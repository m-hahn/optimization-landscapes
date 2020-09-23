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
  real<lower=0, upper=0.9> corr_Lambda;

  matrix[2, 2] B;
}
transformed parameters {
  matrix[2, 2] Lambda = [[1, corr_Lambda], [corr_Lambda, 1]];

  cov_matrix[2] Sigma = B * Lambda + Lambda * B';

  real<lower=0.00001> constraint1;
  real<lower=0.00001> constraint2;

  // Routh-Hurwitz criterion
  constraint1 = B[1, 1] + B[2, 2];
  constraint2 = B[1, 1] * B[2, 2] - B[1, 2] * B[2, 1];




}
model {
  // intermediate steps
  to_vector(B) ~ normal(0, 10);
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

