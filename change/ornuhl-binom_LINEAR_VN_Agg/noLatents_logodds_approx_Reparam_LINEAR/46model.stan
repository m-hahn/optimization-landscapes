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
  matrix[ObservedN, ObservedN] CovarianceMatrix;
  int FamiliesNum;
  int FamiliesSize;
  int FamiliesLists[FamiliesNum, FamiliesSize];
  real stepping;
}
transformed data {
   vector[ObservedN] LogitsAll;
   {
     for(i in 1:ObservedN) {
        real pi = (1.0+TrialsSuccess[i])/(2.0+TrialsTotal[i]);
        LogitsAll[i] = 2*pi-1;
     }
   }
}
parameters {
  vector[2] alpha; // the mean of the process
  real<lower=-1,upper=1> omega_correlation;
  vector<lower=0>[2] sigma_B;
  vector<lower=0>[2] sigma_Omega;
}
transformed parameters {

  real targetPrior = 0;
  real targetLikelihood = 0;

  // intermediate steps
  matrix[2, 2] B = [[sigma_B[1], 0], [0, sigma_B[2]]];

//  matrix[2, 2] Omega_chol = diag_pre_multiply(sigma_Omega, Lrescor_Omega);
  matrix[2, 2] Omega = [[sigma_Omega[1], omega_correlation * sqrt(sigma_Omega[1] * sigma_Omega[2])], [omega_correlation * sqrt(sigma_Omega[1] * sigma_Omega[2]), sigma_Omega[2]]];
//multiply_lower_tri_self_transpose(Omega_chol);

        if(Omega[1,1] + Omega[2,2] <= 0 || Omega[1,1] * Omega[2,2] - Omega[1,2] * Omega[2,1] <= 0) {
         print("Omega is NOT POSITIVE DEFINITE!!");
         print(Omega);
        }




 { //////////////////// likelihood block
  targetPrior += normal_lpdf(alpha | 0, 1);

  targetPrior += normal_lpdf(sigma_B | 0, 1);
  targetPrior += normal_lpdf(sigma_Omega | 0, 1);
  targetPrior += uniform_lpdf(omega_correlation | -1, 1);
//  targetPrior += lkj_corr_cholesky_lpdf(Lrescor_Omega | 1);

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

 } // likelihood block
}
model {
  target += stepping * targetLikelihood + targetPrior;
}
generated quantities {
  matrix[2,2] Sigma = [[0,0],[0,0]];
  {
    real sigma11 = Omega[1,1] * 2 * B[1,1];
    real sigma12 = Omega[1,2] * (B[1,1]+B[2,2]);
    real sigma22 = Omega[2,2] * 2 * B[2,2];
    Sigma[1,1] = sigma11;
    Sigma[1,2] = sigma12;
    Sigma[2,2] = sigma22;
    Sigma[2,1] = sigma12;
  }
}

