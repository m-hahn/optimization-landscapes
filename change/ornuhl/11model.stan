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
  matrix<lower=0, upper=1>[HiddenN, 2] TraitsHidden;
  vector<lower=-4, upper=4>[2] alpha; // the mean of the process
  vector<lower=0>[2] residual_sigma; // measurement error
  real<lower=0.1, upper=2> sigma_Lambda;
  vector<lower=0, upper=2>[2] sigma_B;
//  cholesky_factor_corr[2] Lrescor_Lambda; // notation follows Blackwell 2003, Bayesian Inference for Markov processes...
  cholesky_factor_corr[2] Lrescor_B;
}
transformed parameters {
}
model {
  // intermediate steps
  matrix[TotalN-1, 2] own;
  matrix[TotalN-1, 2] reference;
  matrix[2, 2] Lrescor_Lambda = [[1, 0], [0, 1]];
  matrix[2, 2] Lambda_chol = sigma_Lambda * Lrescor_Lambda;
  matrix[2, 2] B_chol = diag_pre_multiply(sigma_B, Lrescor_B);
  matrix[2, 2] B = multiply_lower_tri_self_transpose(B_chol);
  matrix[2, 2] Lambda = multiply_lower_tri_self_transpose(Lambda_chol);
  matrix[2, 2] residual_Sigma = diag_pre_multiply(residual_sigma, [[1, 0], [0, 1]]);
  target += student_t_lpdf(sigma_Lambda | 3, 0, 2.5);
  target += student_t_lpdf(sigma_B | 3, 0, 2.5);
  target += student_t_lpdf(residual_sigma | 3, 0, 2.5);
  target += lkj_corr_cholesky_lpdf(Lrescor_B | 1);
//  target += lkj_corr_cholesky_lpdf(Lrescor_Lambda | 1);
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
        target += multi_normal_lpdf(own[n-1] | alpha, Lambda);
     } else {
        matrix[2, 2] exp1 = matrix_exp(-B * ParentDistance[n]);
        matrix[2,2] cov = (Lambda - exp1 * Lambda * exp1');
        if(is_nan(cov[1,2]) || is_nan(cov[2,1])) { // (cov[1,1] < 0) || (cov[2,2] < 0) || (cov[1,1] < cov[1,2]) || (cov[2,2] < cov[1,2]) || 
        print("B", B)
        print("exp1", exp1)
        print("Lambda", Lambda)
        print("Covariance", Lambda - exp1 * Lambda * exp1')
        }
        target += multi_normal_lpdf(own[n-1] | alpha + exp1 * (reference[n-1]' - alpha), Lambda - exp1 * Lambda * exp1' + residual_Sigma);
     }
  }
}

