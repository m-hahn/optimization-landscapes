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
  int NumberOfCategories;
  int<lower=0, upper=NumberOfCategories> OrderCategory[TotalN];
}
parameters {
  vector<lower=-1, upper=1>[HiddenN] TraitHidden;
  vector<lower=-2, upper=2>[TotalN] LogitsAll;
  matrix<lower=-2, upper=2>[NumberOfCategories, 2] alpha; // the mean of the process
  matrix<lower=0.1, upper=2>[NumberOfCategories, 2] sigma_Omega;


  real<lower=-1, upper=1> correlation_sigma;
  vector<lower=0.1, upper=2>[2] sigma_Sigma;
}
transformed parameters {
 matrix[2,2] B[NumberOfCategories];
 matrix[2,2] Omega[NumberOfCategories];
  for(i in 1:NumberOfCategories) {
     real omegaCorrelation;
     B[i][1,1] = sigma_Sigma[1] / sigma_Omega[i, 1];
     B[i][2,2] = sigma_Sigma[2] / sigma_Omega[i, 2];
     B[i][1,2] = 0;
     B[i][2,1] = 0;
     Omega[i][1,1] = sigma_Omega[i, 1];
     Omega[i][2,2] = sigma_Omega[i, 2];
     omegaCorrelation = correlation_sigma * sqrt(sigma_Sigma[1] * sigma_Sigma[2]) / (B[i][1,1] + B[i][2,2]);
     Omega[i][1,2] = omegaCorrelation;
     Omega[i][2,1] = omegaCorrelation;
   }
}


model {
  for(i in 1:NumberOfCategories) {
     target += student_t_lpdf(sigma_Omega[i] | 3, 0, 2.5);
  }
  target += student_t_lpdf(sigma_Sigma | 3, 0, 2.5);
  for(i in 1:NumberOfCategories) {
     target += normal_lpdf(alpha[i] | 0, 1);
  }
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
     alphaHere = alpha[OrderCategory[n]]';
     if (ParentIndex[n] == 1) {
        target += multi_normal_lpdf(own_overall | alphaHere, Omega[OrderCategory[n]]);
     } else {
        matrix[2, 2] exp1 = matrix_exp(-B[OrderCategory[n]] * ParentDistance[n]);
        target += multi_normal_lpdf(own_overall | alphaHere + exp1 * (reference_overall - alphaHere), Omega[OrderCategory[n]] - exp1 * Omega[OrderCategory[n]] * exp1');
     }
     if(!IsHidden[n]) {
        int success = TrialsSuccess[Total2Observed[n]];
        int total = TrialsTotal[Total2Observed[n]];
        target += binomial_logit_lpmf(success | total, own_logit);
     }
  }
}
generated quantities {
  matrix[2,2] Sigma = [[sigma_Sigma[1], correlation_sigma * sqrt(sigma_Sigma[1] * sigma_Sigma[2])], [ correlation_sigma * sqrt(sigma_Sigma[1] * sigma_Sigma[2]), sigma_Sigma[2]]];
}

