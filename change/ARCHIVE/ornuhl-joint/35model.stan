functions {
}
data {
  int<lower=1> ObservedN;  // number of observations
  vector<lower=-1, upper=1>[ObservedN] TraitObserved;  // population-level design matrix
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
  matrix[TotalN, TotalN] DistanceMatrixTime;
}
parameters {
  vector<lower=-1, upper=1>[HiddenN] TraitHidden;
  vector<lower=-2, upper=2>[TotalN] LogitsAll;
  vector<lower=-2, upper=2>[2] alpha; // the mean of the process
  vector<lower=0.1, upper=2>[2] sigma_B;

  cholesky_factor_corr[2] Lrescor_Sigma; 


  vector<lower=0.1, upper=2>[2] sigma_Sigma;
  vector<lower=-10, upper=10>[TotalN] mu1;
  vector<lower=-1, upper=1>[TotalN] mu2;

  real<lower=0.000001, upper=100> kernel_mu1_rho_time;
  real<lower=0.000001, upper=100> kernel_mu2_rho_time;


  real<lower=0.000001, upper=1> kernel_mu1_alpha;
  real<lower=0.000001, upper=100> kernel_mu1_rho;
  real<lower=0> kernel_mu1_sigma;
  real<lower=0.000001, upper=1> kernel_mu2_alpha;
  real<lower=0.000001, upper=100> kernel_mu2_rho;
  real<lower=0> kernel_mu2_sigma;
//  matrix[TotalN,2]   alphaByLanguage;
}
transformed parameters {

  // intermediate steps
  matrix[2, 2] Lrescor_B = [[1, 0], [0, 1]];
//



  matrix[2, 2] B_chol = diag_pre_multiply(sigma_B, Lrescor_B);
  matrix[2, 2] Sigma_chol = diag_pre_multiply(sigma_Sigma, Lrescor_Sigma);
//
  matrix[2, 2] B = multiply_lower_tri_self_transpose(B_chol);
  matrix[2, 2] Sigma = multiply_lower_tri_self_transpose(Sigma_chol);

// Sigma = instantaneous covariance
// B = drift matrix (here assumed to be positive definite & symmetric for simplicity)


}
model {
  matrix[TotalN, TotalN] K1;
  matrix[2*TotalN, 2*TotalN] B;


  // Now calculate Omega, the stationary covariance
  matrix[3, 3] factor = [[2*B[1,1], 2*B[1,2], 0], [B[2,1], B[1,1]+B[2,2], B[1,2]], [0, 2*B[2,1], 2*B[2,2]]]; // using Risken (6.126)
  vector[3] instant_cov_components = [Sigma[1,1], Sigma[1,2], Sigma[2,2]]';
  vector[3] Omega_components = factor \ instant_cov_components;
  matrix[2,2] Omega = [[Omega_components[1], Omega_components[2]], [Omega_components[2], Omega_components[3]]];

  matrix[TotalN, TotalN] IdentityMatrix = diag_matrix(rep_vector(1.0, TotalN));


//  print("====")
//  print(B)
//  print(Omega)
//  print(B * Omega + Omega * B')
//  print(Sigma)
//  print(factor[8,2])

        if(Omega[1,1] + Omega[2,2] <= 0 || Omega[1,1] * Omega[2,2] - Omega[1,2] * Omega[2,1] <= 0) {
         print("Omega is NOT POSITIVE DEFINITE!!");
         print(Omega);
         print(Sigma);
         print(B);
        }




  vector[TotalN] zero_mean = rep_vector(0, TotalN);
  K1 = kernel_mu1_alpha * exp(-kernel_mu1_rho * DistanceMatrix - kernel_mu1_rho_time * DistanceMatrixTime) // + kernel_mu1_sigma * IdentityMatrix;

  for(i in 2:TotalN) {
    real opposingDirection = 0;
    for(j in 2:TotalN) { 
      if(i != j) {
         B[i,j] = -K1[i,j];
         opposingDirection += K1[i,j];
      }
    }
    B[i,i] = opposingDirection + kernel_mu1_sigma

  }




                                                                                                       
  for (i in 1:(TotalN - 1)) {                                                                                                                                                                               
    for (j in (i + 1):TotalN) {                                                                                                                                                                             
     if(K1[i,j] > 10) {                                                                                                                                                                                     
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
  target += lkj_corr_cholesky_lpdf(Lrescor_Sigma | 1);


  kernel_mu1_rho_time   ~ normal(0, 1); 

  kernel_mu1_alpha ~ normal(0, 1); 
  kernel_mu1_rho   ~ normal(0, 1);  
  kernel_mu1_sigma ~ normal(0, 1); 

  mu1 ~ multi_normal(zero_mean, K1);

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
     if (ParentIndex[n] == 1) {
        target += multi_normal_lpdf(own_overall | alpha, Omega);
     } else {
        matrix[2, 2] exp1 = matrix_exp(-B * ParentDistance[n]);
        matrix[2,2] covariance_diagnostic = Omega - exp1 * Omega * exp1';
        if(covariance_diagnostic[1,1] + covariance_diagnostic[2,2] <= 0 || covariance_diagnostic[1,1] * covariance_diagnostic[2,2] - covariance_diagnostic[1,2] * covariance_diagnostic[2,1] <= 0) {
         real negDeterminant = -(covariance_diagnostic[1,1] * covariance_diagnostic[2,2] - covariance_diagnostic[1,2] * covariance_diagnostic[2,1]);
         print("NOT POSITIVE DEFINITE")
         print(covariance_diagnostic)
         print(Omega)
         print(exp1)
         print(B)
         print("Neg Determinant", negDeterminant);
         covariance_diagnostic[1,1]  = covariance_diagnostic[1,1] + 0.00001 ;
         covariance_diagnostic[2,2]  = covariance_diagnostic[2,2] + 0.00001 ;

//         if(covariance_diagnostic[1,1] < covariance_diagnostic[2,2]) {
//           covariance_diagnostic[1,1]  = covariance_diagnostic[1,1] + negDeterminant / covariance_diagnostic[2,2] + 0.00001 ;
//         } else {
//           covariance_diagnostic[2,2]  = covariance_diagnostic[2,2] + negDeterminant / covariance_diagnostic[1,1] + 0.00001 ;
//         }
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

