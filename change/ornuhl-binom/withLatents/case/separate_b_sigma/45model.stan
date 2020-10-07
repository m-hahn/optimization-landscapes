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
  vector<lower=0.1, upper=2>[2] sigma_B_Case;
  vector<lower=0.1, upper=2>[2] sigma_B_NoCase;

  cholesky_factor_corr[2] Lrescor_Sigma_Case; 
  vector<lower=0.1, upper=2>[2] sigma_Sigma_Case;
  cholesky_factor_corr[2] Lrescor_Sigma_NoCase; 
  vector<lower=0.1, upper=2>[2] sigma_Sigma_NoCase;
}
transformed parameters {
  // intermediate steps
  matrix[2, 2] Lrescor_B = [[1, 0], [0, 1]];
//
  matrix[2, 2] B_Case_chol = diag_pre_multiply(sigma_B_Case, Lrescor_B);
  matrix[2, 2] B_NoCase_chol = diag_pre_multiply(sigma_B_NoCase, Lrescor_B);
  matrix[2, 2] Sigma_Case_chol = diag_pre_multiply(sigma_Sigma_Case, Lrescor_Sigma_Case);
  matrix[2, 2] Sigma_NoCase_chol = diag_pre_multiply(sigma_Sigma_NoCase, Lrescor_Sigma_NoCase);
//
  matrix[2, 2] B_Case = multiply_lower_tri_self_transpose(B_Case_chol);
  matrix[2, 2] B_NoCase = multiply_lower_tri_self_transpose(B_NoCase_chol);
  matrix[2, 2] Sigma_Case = multiply_lower_tri_self_transpose(Sigma_Case_chol);
  matrix[2, 2] Sigma_NoCase = multiply_lower_tri_self_transpose(Sigma_NoCase_chol);

// Sigma = instantaneous covariance
// B = drift matrix (here assumed to be positive definite & symmetric for simplicity)

  // Now calculate Omega, the stationary covariance
  matrix[3, 3] factor_Case = [[2*B_Case[1,1], 2*B_Case[1,2], 0], [B_Case[2,1], B_Case[1,1]+B_Case[2,2], B_Case[1,2]], [0, 2*B_Case[2,1], 2*B_Case[2,2]]]; // using Risken (6.126)
  vector[3] instant_cov_components_Case = [Sigma_Case[1,1], Sigma_Case[1,2], Sigma_Case[2,2]]';
  vector[3] Omega_Case_components = factor_Case \ instant_cov_components_Case;
  matrix[2,2] Omega_Case = [[Omega_Case_components[1], Omega_Case_components[2]], [Omega_Case_components[2], Omega_Case_components[3]]];



  matrix[3, 3] factor_NoCase = [[2*B_NoCase[1,1], 2*B_NoCase[1,2], 0], [B_NoCase[2,1], B_NoCase[1,1]+B_NoCase[2,2], B_NoCase[1,2]], [0, 2*B_NoCase[2,1], 2*B_NoCase[2,2]]]; // using Risken (6.126)
  vector[3] instant_cov_components_NoCase = [Sigma_NoCase[1,1], Sigma_NoCase[1,2], Sigma_NoCase[2,2]]';
  vector[3] Omega_NoCase_components = factor_NoCase \ instant_cov_components_NoCase;
  matrix[2,2] Omega_NoCase = [[Omega_NoCase_components[1], Omega_NoCase_components[2]], [Omega_NoCase_components[2], Omega_NoCase_components[3]]];

//  print("====")
//  print(B)
//  print(Omega)
//  print(B * Omega + Omega * B')
//  print(Sigma)
//  print(factor[8,2])

//        if(Omega[1,1] + Omega[2,2] <= 0 || Omega[1,1] * Omega[2,2] - Omega[1,2] * Omega[2,1] <= 0) {
//         print("Omega is NOT POSITIVE DEFINITE!!");
//         print(Omega);
//         print(Sigma);
//         print(B);
//        }



}
model {
  target += student_t_lpdf(sigma_B_Case | 3, 0, 2.5);
  target += student_t_lpdf(sigma_B_NoCase | 3, 0, 2.5);
  target += student_t_lpdf(sigma_Sigma_Case | 3, 0, 2.5);
  target += student_t_lpdf(sigma_Sigma_Case | 3, 0, 2.5);
  target += normal_lpdf(alphaNoCase | 0, 1);
  target += normal_lpdf(alphaCase | 0, 1);
  target += lkj_corr_cholesky_lpdf(Lrescor_Sigma_Case | 1);
  target += lkj_corr_cholesky_lpdf(Lrescor_Sigma_NoCase | 1);
  for (n in 2:TotalN) {
     real reference_trait;
     real reference_logit;
     real own_trait;
     real own_logit;
     vector[2] own_overall;
     vector[2] reference_overall;
     vector[2] alphaHere;
     matrix[2,2] OmegaHere;
     matrix[2,2] BHere;
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
         OmegaHere = Omega_Case;
         BHere = B_Case;
     } else {
         alphaHere = alphaNoCase;
         OmegaHere = Omega_NoCase;
         BHere = B_NoCase;
     }
     if (ParentIndex[n] == 1) {
        target += multi_normal_lpdf(own_overall | alphaHere, OmegaHere);
     } else {
        matrix[2, 2] exp1 = matrix_exp(-BHere * ParentDistance[n]);
        target += multi_normal_lpdf(own_overall | alphaHere + exp1 * (reference_overall - alphaHere), OmegaHere - exp1 * OmegaHere * exp1');
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

