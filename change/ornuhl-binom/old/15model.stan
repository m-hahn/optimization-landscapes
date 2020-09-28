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
}
parameters {
  vector<lower=0, upper=1>[HiddenN] TraitHidden;
  vector<lower=-2, upper=2>[TotalN] LogitsAll;
  vector<lower=-2, upper=2>[2] alpha; // the mean of the process
  vector<lower=0, upper=2>[2] sigma_Lambda;
  vector<lower=0.05, upper=2>[2] sigma_B;
  real<lower=0, upper=1> corr_Lambda;
  real<lower=0, upper=0.95> corr_B;
}
transformed parameters {
}
model {
  // intermediate steps
  matrix[2, 2] Lrescor_Lambda = [[1, 0], [corr_Lambda, 1]];
  matrix[2, 2] Lrescor_B = [[1, 0], [corr_B, 1]];
//
  matrix[2, 2] Lambda_chol = diag_pre_multiply(sigma_Lambda, Lrescor_Lambda);
  matrix[2, 2] B_chol = diag_pre_multiply(sigma_B, Lrescor_B);
//
  matrix[2, 2] Lambda = multiply_lower_tri_self_transpose(Lambda_chol);
  matrix[2, 2] B = multiply_lower_tri_self_transpose(B_chol);
//
  target += student_t_lpdf(sigma_Lambda | 3, 0, 2.5);
  target += student_t_lpdf(sigma_B | 3, 0, 2.5);
  target += normal_lpdf(alpha[1] | 0, 1);
  for (n in 2:TotalN) {
     real reference_trait;
     real reference_logit;
     real own_trait;
     real own_logit;
     vector[2] own_overall;
     vector[2] reference_overall;

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
        target += multi_normal_lpdf(own_overall | alpha, Lambda);
     } else {
        matrix[2, 2] exp1 = matrix_exp(-B * ParentDistance[n]);
        target += multi_normal_lpdf(own_overall | alpha + exp1 * (reference_overall - alpha), Lambda - exp1 * Lambda * exp1');
     }
     if(!IsHidden[n]) {
        int success = TrialsSuccess[Total2Observed[n]];
        int total = TrialsTotal[Total2Observed[n]];
        target += binomial_logit_lpmf(success | total, own_logit);
     }
  }
}

