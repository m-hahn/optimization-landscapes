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
  matrix[ObservedN, ObservedN] CovarianceMatrix;
  int FamiliesNum;
  int FamiliesSize;
  int FamiliesLists[FamiliesNum, FamiliesSize];
}
parameters {
  vector<lower=-2, upper=2>[ObservedN] LogitsAll;
  vector[2] alpha; // the mean of the process
  vector[2] sigma_B;

  real<lower=-1, upper=1> CorrComponentSigma;
//  cholesky_factor_corr[2] Lrescor_Sigma; 

  vector<lower=0>[2] sigma_Sigma;
}
transformed parameters {
  real stepping = 1.0;

  real targetPrior = 0;
  real targetLikelihood = 0;

  // intermediate steps
  matrix[2, 2] Lrescor_B = [[1, 0], [0, 1]];
//
  matrix[2, 2] B_chol = diag_pre_multiply(sigma_B, Lrescor_B);
//  matrix[2, 2] Sigma_chol = diag_pre_multiply(sigma_Sigma, Lrescor_Sigma);
//
  matrix[2, 2] B = multiply_lower_tri_self_transpose(B_chol);
  matrix[2, 2] Sigma = [[sigma_Sigma[1], sqrt(sigma_Sigma[1]*sigma_Sigma[2])*CorrComponentSigma], [sqrt(sigma_Sigma[1]*sigma_Sigma[2])*CorrComponentSigma, sigma_Sigma[2]]];

// Sigma = instantaneous covariance
// B = drift matrix (here assumed to be positive definite & symmetric for simplicity)

  // Now calculate Omega, the stationary covariance
  matrix[3, 3] factor = [[2*B[1,1], 2*B[1,2], 0], [B[2,1], B[1,1]+B[2,2], B[1,2]], [0, 2*B[2,1], 2*B[2,2]]]; // using Risken (6.126)
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




 { //////////////////// likelihood block
  targetPrior += normal_lpdf(alpha | 0, 1);

  targetPrior += normal_lpdf(sigma_B | 0, 1);
  targetPrior += normal_lpdf(sigma_Sigma | 0, 1);
//  targetPrior += lkj_corr_cholesky_lpdf(Lrescor_Sigma | 1);

  for(family in 1:FamiliesNum) {
    int familySizeHere;
    for(language in 1:FamiliesSize) {
       if(FamiliesLists[family, language] == 0) {
          familySizeHere = 1;
          break;
       }
    } // loop over 'language'
    { // block
     vector[2*familySizeHere] own_overall;
     matrix[2*familySizeHere, 2*familySizeHere] fullCovMat;
     vector[2*familySizeHere] fullMeanVector;
   
     for(i in 1:familySizeHere) {
        fullMeanVector[2*(i-1)+1] = alpha[1];
        fullMeanVector[2*(i-1)+2] = alpha[2];
        for(j in 1:i) {
          matrix[2, 2] covarianceHere;
          if(CovarianceMatrix[i,j] > 30) { // essentially no statistical dependency
            covarianceHere = [[0, 0], [0, 0]];
          } else if(i == j) { // here, the distance is zero
            covarianceHere = Omega;
          } else {
            matrix[2,2] exponentiated1 = exp(-CovarianceMatrix[FamiliesLists[family, i],FamiliesLists[family, j]] * B);
            matrix[2,2] exponentiated2 = exp(-CovarianceMatrix[FamiliesLists[family, j],FamiliesLists[family, i]] * B);
            covarianceHere = exponentiated1 * Omega * exponentiated2';
          }
          for(u in 1:2) {
           for(v in 1:2) {
              fullCovMat[2*(i-1)+u, 2*(j-1)+v] = covarianceHere[u,v];
              fullCovMat[2*(j-1)+u, 2*(i-1)+v] = covarianceHere[v,u];
           } // loop over v
          } // loop over u
        } // loop over j
   
        for(j in 1:familySizeHere) {
           own_overall[2*(j-1)+1] = LogitsAll[FamiliesLists[family, j]];
           own_overall[2*(j-1)+2] = TraitObserved[FamiliesLists[family, j]];
        } // loop over j
        targetLikelihood += multi_normal_lpdf(own_overall | rep_vector(0, 2*familySizeHere), fullCovMat);
     } // loop over i
    } // end block
   } // loop over 'family'

   for (n in 1:ObservedN) {
        int success = TrialsSuccess[n];
        int total = TrialsTotal[n];
        targetLikelihood += binomial_logit_lpmf(success | total, LogitsAll[n]);
   } // loop over n
 } // likelihood block
}
model {
  target += stepping * targetLikelihood + targetPrior;
}
generated quantities {
}

