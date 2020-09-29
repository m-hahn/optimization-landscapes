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
  real stepping;
}
parameters {
  vector<lower=-2, upper=2>[ObservedN] LogitsAll;
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
  for (n in 1:ObservedN) {
        int success = TrialsSuccess[n];
        int total = TrialsTotal[n];
        targetLikelihood += binomial_logit_lpmf(success | total, LogitsAll[n]);
  }
  }
}
model {
  target += stepping * targetLikelihood + targetPrior;
}
generated quantities {
}

