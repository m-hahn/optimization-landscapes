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
}
transformed data {
   vector[ObservedN] LogitsAll;
   {
     for(i in 1:ObservedN) {
        real pi = (1.0+TrialsSuccess[i])/(2.0+TrialsTotal[i]);
        LogitsAll[i] = log(pi/(1-pi));
        print(LogitsAll[i]);
        print(i);
     }
   }
}
parameters {
  vector[2] alpha; // the mean of the process

  cholesky_factor_corr[2] Lrescor_Omega; 
  vector<lower=0>[2] sigma_Omega;
}
transformed parameters {
  real stepping = 1.0;

  real targetPrior = 0;
  real targetLikelihood = 0;

  // intermediate steps

  matrix[2, 2] Omega_chol = diag_pre_multiply(sigma_Omega, Lrescor_Omega);
  matrix[2, 2] Omega = multiply_lower_tri_self_transpose(Omega_chol);


        if(Omega[1,1] + Omega[2,2] <= 0 || Omega[1,1] * Omega[2,2] - Omega[1,2] * Omega[2,1] <= 0) {
         print("Omega is NOT POSITIVE DEFINITE!!");
         print(Omega);
        }




 { //////////////////// likelihood block
  targetPrior += normal_lpdf(alpha | 0, 1);

  targetPrior += normal_lpdf(sigma_Omega | 0, 1);
  targetPrior += lkj_corr_cholesky_lpdf(Lrescor_Omega | 1);

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
          if(i!=j) { // essentially no statistical dependency
            covarianceHere = [[0, 0], [0, 0]];
          } else if(i == j) { // here, the distance is zero
            covarianceHere = Omega;
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
}

