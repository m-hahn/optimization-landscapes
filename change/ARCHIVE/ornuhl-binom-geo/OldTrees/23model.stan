functions {
}
data {
  int<lower=1> ObservedN;  // number of observations
  vector<lower=0, upper=1>[ObservedN] TraitObserved;  // population-level design matrix
  int<lower=0> TrialsSuccess[ObservedN];
  int<lower=0> TrialsTotal[ObservedN];
  int<lower=1> HiddenN;
  int<lower=1> TotalN;
  int IsHidden[TotalN];
  int ParentIndex[TotalN];
  int Total2Observed[TotalN];
  int Total2Hidden[TotalN];
  vector<lower=0>[TotalN] ParentDistance;
  int prior_only;  // should the likelihood be ignored?
  int Components;
  matrix[TotalN, TotalN] DistanceMatrix;
}
parameters {
  vector<lower=0, upper=1>[HiddenN] TraitHidden;
  vector<lower=-2, upper=2>[TotalN] LogitsAll;
  vector<lower=-2, upper=2>[2] alpha; // the mean of the process
  vector<lower=0.1, upper=2>[2] sigma_B;
  vector<lower=0.1, upper=2>[2] sigma_Sigma;
  real<lower=-0.9, upper=0.9> corr_B;
  real<lower=-0.9, upper=0.9> corr_Sigma;
  vector[TotalN] mu1;
  vector[TotalN] mu2;
  real<lower=0.000001, upper=1> kernel_mu1_alpha;
  real<lower=0.000001, upper=100> kernel_mu1_rho;
  real<lower=0> kernel_mu1_sigma;
  real<lower=0.000001, upper=1> kernel_mu2_alpha;
  real<lower=0.000001, upper=100> kernel_mu2_rho;
  real<lower=0> kernel_mu2_sigma;
//  matrix[TotalN,2]   alphaByLanguage;
}
transformed parameters {

  matrix[TotalN, TotalN] K1;
  matrix[TotalN, TotalN] K2;


  // intermediate steps
  matrix[2, 2] Lrescor_B = [[1, 0], [corr_B, 1]];
  matrix[2, 2] Lrescor_Sigma = [[1, 0], [corr_Sigma, 1]];
//
  matrix[2, 2] B_chol = diag_pre_multiply(sigma_B, Lrescor_B);
  matrix[2, 2] Sigma_chol = diag_pre_multiply(sigma_Sigma, Lrescor_Sigma);
//
  matrix[2, 2] B = multiply_lower_tri_self_transpose(B_chol);
  matrix[2, 2] Sigma = multiply_lower_tri_self_transpose(Sigma_chol);

// Sigma = instantaneous covariance
// B = drift matrix (here assumed to be positive definite & symmetric for simplicity)

  // Now calculate Omega, the stationary covariance
  matrix[3, 3] factor = [[2*B[1,1], B[1,2], 0], [B[2,1], B[1,1]+B[2,2], B[1,2]], [0, B[2,1], 2*B[2,2]]]; // using Risken (6.126)
  vector[3] instant_cov_components = [Sigma[1,1], Sigma[1,2], Sigma[2,2]]';
  vector[3] Omega_components = factor \ instant_cov_components;
  matrix[2,2] Omega = [[Omega_components[1], Omega_components[2]], [Omega_components[2], Omega_components[3]]];


  matrix[TotalN, TotalN] IdentityMatrix = diag_matrix(rep_vector(1.0, TotalN));


  vector[TotalN] zero_mean = rep_vector(0, TotalN);
  K1 = kernel_mu1_alpha * exp(-kernel_mu1_rho * (DistanceMatrix)) + kernel_mu1_sigma * IdentityMatrix;
  K2 = kernel_mu2_alpha * exp(-kernel_mu2_rho * (DistanceMatrix)) + kernel_mu2_sigma * IdentityMatrix;
//  print("====")
//  print(B)
//  print(Omega)
//  print(B * Omega + Omega * B')
//  print(Sigma)
//  print(factor[8,2])
}
model {

                                                                                                       
  for (i in 1:(TotalN - 1)) {                                                                                                                                                                               
    for (j in (i + 1):TotalN) {                                                                                                                                                                             
     if(K1[i,j] > 50) {                                                                                                                                                                                     
       print(i, " ", j," ",  K1[i, j]," ",  kernel_mu1_alpha, " ", kernel_mu1_rho, " ", DistanceMatrix[i,j]);                                                                                                                        
     }                                                                                                                                                                                                      
    }                                                                                                                                                                                                       
  }                                                                                                  

   if(K1[4, 47] != K1[4, 47]) {
      print("===");
      print(K1[4,47]);
      print(kernel_mu1_alpha);
      print(kernel_mu1_rho);
       print(DistanceMatrix[4,47]);
     print(kernel_mu1_sigma);
     print(IdentityMatrix[4,47]);
   }
//  print(K1[4, 47])  ;

  target += student_t_lpdf(sigma_B | 3, 0, 2.5);
  target += student_t_lpdf(sigma_Sigma | 3, 0, 2.5);
  target += normal_lpdf(alpha[1] | 0, 1);

  kernel_mu1_alpha ~ normal(0, 1); 
  kernel_mu1_rho   ~ normal(0, 1);  
  kernel_mu1_sigma ~ normal(0, 1); 
  kernel_mu2_alpha ~ normal(0, 1);  
  kernel_mu2_rho   ~ normal(0, 1); 
  kernel_mu2_sigma ~ normal(0, 1);  

  mu1 ~ multi_normal(zero_mean, K1);
  mu2 ~ multi_normal(zero_mean, K2);

  for (n in 2:TotalN) {
     real reference_trait;
     real reference_logit;
     real own_trait;
     real own_logit;
     vector[2] own_overall;
     vector[2] reference_overall;
     vector[2] target_mean_here;
     if (IsHidden[ParentIndex[n]]) {
         reference_trait = TraitHidden[Total2Hidden[ParentIndex[n]]];
     } else {
         reference_trait = TraitObserved[Total2Observed[ParentIndex[n]]];
     }
     reference_logit = LogitsAll[ParentIndex[n]];
     if (IsHidden[n]) {
        own_trait = TraitHidden[Total2Hidden[n]];
     } else {
        own_trait = TraitObserved[Total2Observed[n]];
     }
     own_logit = LogitsAll[n];
     own_overall = [own_logit, own_trait]';
     reference_overall = [reference_logit, reference_trait]';
     target_mean_here = alpha + [mu1[n], mu2[n]]';
     if (ParentIndex[n] == 1) {
        target += multi_normal_lpdf(own_overall | alpha, Omega);
     } else {
        matrix[2, 2] exp1 = matrix_exp(-B * ParentDistance[n]);
        matrix[2,2] covariance_diagnostic = Omega - exp1 * Omega * exp1';
        if(covariance_diagnostic[1,1] + covariance_diagnostic[2,2] <= 0 || covariance_diagnostic[1,1] * covariance_diagnostic[2,2] - covariance_diagnostic[1,2] * covariance_diagnostic[2,1] <= 0) {
         print("NOT POSITIVE DEFINITE")
         print(covariance_diagnostic)
         print(Omega)
         print(exp1)
         print(B)
        }
        target += multi_normal_lpdf(own_overall | alpha + exp1 * (reference_overall - alpha), covariance_diagnostic);
     }
     if(!IsHidden[n]) {
        int success = TrialsSuccess[Total2Observed[n]];
        int total = TrialsTotal[Total2Observed[n]];
        target += binomial_logit_lpmf(success | total, own_logit);
     }
  }
}
generated quantities {
}

