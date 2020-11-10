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
  real stepping;
}
transformed data {
   vector[ObservedN] LogitsAll;
   {
     for(i in 1:ObservedN) {
        LogitsAll[i] = ((TrialsSuccess[i])/(TrialsTotal[i])) * 2 -1;
     }
   }
}
parameters {
  vector<lower=0>[2] sd_1; 

}
transformed parameters {

  matrix[2, 2] Sigma ;
  real targetPrior = 0;
  real targetLikelihood = 0;

  
  { ////////////////////
  vector[2*ObservedN] own_overall;
  matrix[2*ObservedN, 2*ObservedN] fullCovMat;

  matrix[2, 2] LSigma = diag_pre_multiply(sd_1, [[1, 0], [0, 1]]);
  Sigma = multiply_lower_tri_self_transpose(LSigma);

  for(i in 1:ObservedN) {
     for(j in 1:ObservedN) {
       for(u in 1:2) {
        for(v in 1:2) {
           fullCovMat[2*(i-1)+u, 2*(j-1)+v] = CovarianceMatrix[i,j] * Sigma[u,v];
        }
       }
     }
  }

  targetPrior += student_t_lpdf(sd_1 | 3, 0, 2.5);
  
  for(i in 1:ObservedN) {
     own_overall[2*(i-1)+1] = LogitsAll[i];
     own_overall[2*(i-1)+2] = TraitObserved[i];
  }
  targetLikelihood += multi_normal_lpdf(own_overall | rep_vector(0, 2*ObservedN), fullCovMat);

  }
}
model {
  target += stepping * targetLikelihood + targetPrior;
}
generated quantities {
}

