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
  int<lower=0, upper=1> HasCase[TotalN];
}
parameters {
  vector<lower=-1, upper=1>[HiddenN] TraitHidden;
  vector<lower=-2, upper=2>[TotalN] LogitsAll;
  vector<lower=-2, upper=2>[2] alphaCase; // the mean of the process
  vector<lower=-2, upper=2>[2] alphaNoCase; // the mean of the process
  vector<lower=0.1, upper=2>[2] sigma_B;

  cholesky_factor_corr[2] Lrescor_Sigma; 


  vector<lower=0.1, upper=2>[2] sigma_Sigma;
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

  // Now calculate Omega, the stationary covariance
  matrix[3, 3] factor = [[2*B[1,1], B[1,2], 0], [B[2,1], B[1,1]+B[2,2], B[1,2]], [0, B[2,1], 2*B[2,2]]]; // using Risken (6.126)
  vector[3] instant_cov_components = [Sigma[1,1], Sigma[1,2], Sigma[2,2]]';
  vector[3] Omega_components = factor \ instant_cov_components;
  matrix[2,2] Omega = [[Omega_components[1], Omega_components[2]], [Omega_components[2], Omega_components[3]]];
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



}
model {
  target += student_t_lpdf(sigma_B | 3, 0, 2.5);
  target += student_t_lpdf(sigma_Sigma | 3, 0, 2.5);
  target += normal_lpdf(alphaNoCase | 0, 1);
  target += normal_lpdf(alphaCase | 0, 1);
  target += lkj_corr_cholesky_lpdf(Lrescor_Sigma | 1);
  for (n in 2:TotalN) {
     real reference_trait;
     real reference_logit;
     real own_trait;
     real own_logit;
     vector[2] own_overall;
     vector[2] reference_overall;
     vector[2] alphaHere;

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
     if(HasCase[n]) {
         alphaHere = alphaCase;
     } else {
         alphaHere = alphaNoCase;
     }
     if (ParentIndex[n] == 1) {
        target += multi_normal_lpdf(own_overall | alphaHere, Omega);
     } else {
        matrix[2, 2] exp1 = matrix_exp(-B * ParentDistance[n]);
        target += multi_normal_lpdf(own_overall | alphaHere + exp1 * (reference_overall - alphaHere), Omega - exp1 * Omega * exp1');
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

