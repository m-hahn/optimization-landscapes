functions {
}
data {
  int<lower=1> ObservedN;  // number of observations
  matrix[ObservedN, 2] TraitsObserved;  // population-level design matrix
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
  real<lower=0> sigma1; 
  real<lower=0> sigma2; 
  matrix<lower=0, upper=1>[HiddenN, 2] TraitsHidden;
  real<lower=-5, upper=5> logkappa1;
  real<lower=-5, upper=5> logkappa2;
  real<lower=-5, upper=5> alpha1;
  real<lower=-5, upper=5> alpha2;
}
transformed parameters {
   real kappa1 = exp(logkappa1);
   real kappa2 = exp(logkappa2);
}
model {
  matrix[TotalN-1, 2] own;
  matrix[TotalN-1, 2] reference;
  target += student_t_lpdf(sigma1 | 3, 0, 2.5);
  target += student_t_lpdf(sigma2 | 3, 0, 2.5);
  for (n in 2:TotalN) {
     if (IsHidden[ParentIndex[n]]) {
         reference[n-1] = TraitsHidden[Total2Hidden[ParentIndex[n]]];
     } else {
         reference[n-1] = TraitsObserved[Total2Observed[ParentIndex[n]]];
     }
     if (IsHidden[n]) {
        own[n-1] = TraitsHidden[Total2Hidden[n]];
     } else {
        own[n-1] = TraitsObserved[Total2Observed[n]];
     }
     if (ParentIndex[n] == 1) {
        target += normal_lpdf(own[n-1][1] | alpha1, 0.5 * sigma1 / kappa1);
        target += normal_lpdf(own[n-1][2] | alpha2, 0.5 * sigma2 / kappa2);
     } else {
        target += normal_lpdf(own[n-1][1] | reference[n-1][1] * exp(-kappa1*ParentDistance[n]) + alpha1 * (1-exp(-kappa1*ParentDistance[n]) ), 0.5 * sigma1 * (1-exp(-2*kappa1*ParentDistance[n])) / kappa1);
        target += normal_lpdf(own[n-1][2] | reference[n-1][2] * exp(-kappa2*ParentDistance[n]) + alpha2 * (1-exp(-kappa2*ParentDistance[n]) ), 0.5 * sigma2 * (1-exp(-2*kappa2*ParentDistance[n])) / kappa2);
     }
  }
}

