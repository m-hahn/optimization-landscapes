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
  vector<lower=0>[2] sd_1; 
  cholesky_factor_corr[2] Lrescor; 
  matrix<lower=0, upper=1>[HiddenN, 2] TraitsHidden;
}
model {
  matrix[TotalN-1, 2] own;
  matrix[TotalN-1, 2] reference;
  matrix[2, 2] LSigma = diag_pre_multiply(sd_1, Lrescor);
  target += student_t_lpdf(sd_1 | 3, 0, 2.5)
    - 2 * student_t_lccdf(0 | 3, 0, 2.5);
  target += lkj_corr_cholesky_lpdf(Lrescor | 1);
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
     target += multi_normal_cholesky_lpdf(own[n-1] | reference[n-1], sqrt(ParentDistance[n]) * LSigma);
  }
}
generated quantities {
  // residual correlations
  corr_matrix[Components] Rescor = multiply_lower_tri_self_transpose(Lrescor);
}

