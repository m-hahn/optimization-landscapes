functions {
}
data {
  int<lower=1> ObservedN;  // number of observations
  vector<lower=-1, upper=1>[ObservedN] TraitObserved;  // population-level design matrix
  vector<lower=0>[ObservedN] TrialsSuccess;
  vector<lower=0>[ObservedN] TrialsTotal;
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
transformed data {
   vector[ObservedN] LogitsObserved;
   {
     for(i in 1:ObservedN) {
        real pi = (TrialsSuccess[i])/(TrialsTotal[i]);
        LogitsObserved[i] = pi*2-1;
     }
   }
}
parameters {
  vector<lower=-1, upper=1>[HiddenN] TraitHidden;
  vector<lower=-1, upper=1>[HiddenN] LogitsHidden;
  vector<lower=-2, upper=2>[2] alpha; // the mean of the process
  vector<lower=0.1, upper=2>[2] sigma_B;

  cholesky_factor_corr[2] Lrescor_Sigma; 


  vector<lower=0.1, upper=2>[2] sigma_Sigma;
  vector<lower=-10, upper=10>[TotalN] mu1;
  vector<lower=-1, upper=1>[TotalN] mu2;

  real<lower=0.000001, upper=1> kernel_mu1_rho_time;
  real<lower=0.000001, upper=1> kernel_mu2_rho_time;


  real<lower=0.000001, upper=1> kernel_mu1_alpha;
  real<lower=0.000001, upper=1> kernel_mu1_rho;
  real<lower=0> kernel_mu1_sigma;
  real<lower=0.000001, upper=1> kernel_mu2_alpha;
  real<lower=0.000001, upper=1> kernel_mu2_rho;
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

  matrix[(2*ObservedN)*((2*ObservedN)-1)/2] multWithStat;
  vector[2*ObservedN] sigmaAsVector;
  matrix[2*ObservedN, 2*ObservedN] BTotal;
  vector[TotalN] zero_mean = rep_vector(0, TotalN);


  matrix[3, 3] factor = [[2*B[1,1], 2*B[1,2], 0], [B[2,1], B[1,1]+B[2,2], B[1,2]], [0, 2*B[2,1], 2*B[2,2]]]; // using Risken (6.126)
  vector[3] instant_cov_components = [Sigma[1,1], Sigma[1,2], Sigma[2,2]]';
  vector[3] Omega_components = factor \ instant_cov_components;
  matrix[2,2] Omega = [[Omega_components[1], Omega_components[2]], [Omega_components[2], Omega_components[3]]];

  matrix[ObservedN, ObservedN] IdentityMatrix = diag_matrix(rep_vector(1.0, ObservedN));



  for(i in 1:ObservedN) {
     for(j in 1:i-1) {
       real transfer1 = kernel_mu1_alpha * exp(-kernel_mu1_rho * DistanceMatrix[i,j]);
       real transfer2 = kernel_mu2_alpha * exp(-kernel_mu2_rho * DistanceMatrix[i,j]);
       BTotal[2*(i-1)+2, 2*(j-1)+2] = -transfer2;
       BTotal[2*(i-1)+1, 2*(j-1)+1] = -transfer1;
       BTotal[2*(j-1)+2, 2*(i-1)+2] = -transfer2;
       BTotal[2*(j-1)+1, 2*(i-1)+1] = -transfer1;
//      print(i, j, DistanceMatrix[i,j]);
//      print(transfer1)
//      print(transfer2)
     }
  }
  for(i in 1:ObservedN) {
     real transfer1 = 0;
     real transfer2 = 0;
     for(j in 1:ObservedN) {
        BTotal[2*(i-1)+1, 2*(j-1)+2] = 0;
        BTotal[2*(i-1)+2, 2*(j-1)+1] = 0;

        if(i != j) {
          transfer1 += BTotal[2*(i-1)+1,2*(j-1)+1];
          transfer2 += BTotal[2*(i-1)+2,2*(j-1)+2];
        }
     }
     BTotal[2*(i-1)+1,2*(i-1)+1] = B[1,1]-transfer1;
     BTotal[2*(i-1)+2,2*(i-1)+2] = B[2,2]-transfer2;
  }


  // Now calculate Omega, the stationary covariance

  for(i in 1:(2*ObservedN)) {
     for(j in 1:i) {
       firstIndex = (i-1)*(2*ObservedN) + j;
       for(i2 in 1:(2*ObservedN)) {
         for(j2 in 1:i) {
            secondIndex = (i2-1)*(2*ObservedN) + j2;
            
            multWithStat[firstIndex, secondIndex] = 0;
            if(j == j2) {
                 multWithStat[firstIndex, secondIndex] += BTotal[i2,j];
            }
            if(i == i2) {
                multWithStat[firstIndex, secondIndex] += BTotal[j2,j];
            }
         }
      }
     }
  }
  for(i in 1:ObservedN) {
    for(j in 1:i) {
      sigmaAsVector[(i-1)*(2*ObservedN) + 2*(i-1) + 1] = 

    }
  }

}
model {

  target += student_t_lpdf(sigma_B | 3, 0, 2.5);
  target += student_t_lpdf(sigma_Sigma | 3, 0, 2.5);
  target += normal_lpdf(alpha[1] | 0, 1);
  target += lkj_corr_cholesky_lpdf(Lrescor_Sigma | 1);


  kernel_mu1_rho_time   ~ normal(0, 1); 
  kernel_mu2_rho_time   ~ normal(0, 1); 

  kernel_mu1_alpha ~ normal(0, 1); 
  kernel_mu1_rho   ~ normal(0, 1);  
  kernel_mu1_sigma ~ normal(0, 1); 
  kernel_mu2_alpha ~ normal(0, 1);  
  kernel_mu2_rho   ~ normal(0, 1); 
  kernel_mu2_sigma ~ normal(0, 1);  

//  mu1 ~ multi_normal(zero_mean, K1);
//  mu2 ~ multi_normal(zero_mean, K2);

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
         reference_logit = LogitsHidden[Total2Hidden[ParentIndex[n]]];
     } else {
         reference_trait = TraitObserved[Total2Observed[ParentIndex[n]]];
         reference_logit = LogitsObserved[Total2Observed[ParentIndex[n]]];
     }
     if (IsHidden[n]) {
        own_trait = TraitHidden[Total2Hidden[n]];
        own_logit = LogitsHidden[Total2Hidden[n]];
     } else {
        own_trait = TraitObserved[Total2Observed[n]];
        own_logit = LogitsObserved[Total2Observed[n]];
     }
     own_overall = [own_logit, own_trait]';
     reference_overall = [reference_logit, reference_trait]';
     target_mean_here = alpha + [mu1[n], mu2[n]]';
     if (ParentIndex[n] == 1) {
        target += multi_normal_lpdf(own_overall | target_mean_here, Omega);
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
        target += multi_normal_lpdf(own_overall | target_mean_here + exp1 * (reference_overall - target_mean_here), covariance_diagnostic);
     }
  }
}
generated quantities {
}

