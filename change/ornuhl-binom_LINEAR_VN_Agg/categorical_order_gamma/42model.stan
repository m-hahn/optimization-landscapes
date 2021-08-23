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
  int NumberOfCategories;
  int<lower=0, upper=NumberOfCategories> OrderCategory[TotalN];
}
transformed data {
   vector<lower=-1, upper=1>[ObservedN] LogitsObserved;
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
  matrix<lower=-2, upper=2>[NumberOfCategories, 2] alpha; // the mean of the process
  matrix<lower=0.1, upper=2>[NumberOfCategories, 2] sigma_B;

  cholesky_factor_corr[2] Lrescor_Sigma; 


  vector<lower=0.1, upper=2>[2] sigma_Sigma;
}
transformed parameters {
  // intermediate steps
  matrix[2, 2] Lrescor_B = [[1, 0], [0, 1]];
//
 matrix[2, 2] Sigma_chol = diag_pre_multiply(sigma_Sigma, Lrescor_Sigma);
 matrix[2, 2] Sigma = multiply_lower_tri_self_transpose(Sigma_chol);

 matrix[2,2] B[NumberOfCategories];
 matrix[2,2] Omega[NumberOfCategories];
  for(i in 1:NumberOfCategories) {
     matrix[2, 2] B_chol = diag_pre_multiply(sigma_B[i], Lrescor_B);
   //
     matrix[2, 2] B_ = multiply_lower_tri_self_transpose(B_chol);
   
   // Sigma = instantaneous covariance
   // B = drift matrix (here assumed to be positive definite & symmetric for simplicity)
   
     // Now calculate Omega, the stationary covariance
     matrix[3, 3] factor = [[2*B_[1,1], B_[1,2], 0], [B_[2,1], B_[1,1]+B_[2,2], B_[1,2]], [0, B_[2,1], 2*B_[2,2]]]; // using Risken (6.126)
     vector[3] instant_cov_components = [Sigma[1,1], Sigma[1,2], Sigma[2,2]]';
     vector[3] Omega_components = factor \ instant_cov_components;
     matrix[2,2] Omega_ = [[Omega_components[1], Omega_components[2]], [Omega_components[2], Omega_components[3]]];
  
           if(Omega_[1,1] + Omega_[2,2] <= 0 || Omega_[1,1] * Omega_[2,2] - Omega_[1,2] * Omega_[2,1] <= 0) {
            print("Omega_ is NOT POSITIVE DEFINITE!!");
            print(Omega_);
            print(Sigma);
            print(B_);
           }
   for(j in 1:2){
     for(k in 1:2){
       B[i,j,k] = B_[j,k];
       Omega[i,j,k] = Omega_[j,k];
     }
   }
}


}
model {
  for(i in 1:NumberOfCategories) {
     target += student_t_lpdf(sigma_B[i] | 3, 0, 2.5);
  }
  target += student_t_lpdf(sigma_Sigma | 3, 0, 2.5);
  for(i in 1:NumberOfCategories) {
     target += normal_lpdf(alpha[i] | 0, 1);
  }
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
     alphaHere = alpha[OrderCategory[n]]';
     if (ParentIndex[n] == 1) {
        target += multi_normal_lpdf(own_overall | alphaHere, Omega[OrderCategory[n]]);
     } else {
        matrix[2, 2] exp1 = matrix_exp(-B[OrderCategory[n]] * ParentDistance[n]);
        target += multi_normal_lpdf(own_overall | alphaHere + exp1 * (reference_overall - alphaHere), Omega[OrderCategory[n]] - exp1 * Omega[OrderCategory[n]] * exp1');
     }
  }
}
generated quantities {
}

