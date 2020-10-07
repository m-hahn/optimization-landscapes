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
  real stepping;
}
parameters {
  vector<lower=-1, upper=1>[HiddenN] TraitHidden;
  vector<lower=-2, upper=2>[TotalN] LogitsAll;
  vector<lower=0>[2] sd_1; 
  cholesky_factor_corr[2] Lrescor; 

}
transformed parameters {
  real targetPrior = 0;
  real targetLikelihood = 0;
  matrix[2, 2] LSigma = diag_pre_multiply(sd_1, Lrescor);
  matrix[2, 2] Sigma = multiply_lower_tri_self_transpose(LSigma);
  { ////////////////////
  targetPrior += student_t_lpdf(sd_1 | 3, 0, 2.5) + log(2.0);
  targetPrior += lkj_corr_cholesky_lpdf(Lrescor | 1);
  targetPrior += normal_lpdf(TraitHidden[1] | 0, 1);
  targetPrior += normal_lpdf(LogitsAll[1] | 0, 1);
 
  for (n in 2:TotalN) {
     real reference_trait;
     real reference_logit;
     real own_trait;
     real own_logit;
     vector[2] own_overall;
     vector[2] reference_overall;
     real likelihoodForPoint;

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
     if(ParentDistance[n] < 0.05) {
       print("Short distance", ParentDistance[n], n);
     }
     likelihoodForPoint = multi_normal_lpdf(own_overall | reference_overall , ParentDistance[n] * Sigma);
     if(IsHidden[n]) {
       targetPrior += likelihoodForPoint;
     } else {
       targetLikelihood += likelihoodForPoint;
     }
     if(!IsHidden[n]) {
        int success = TrialsSuccess[Total2Observed[n]];
        int total = TrialsTotal[Total2Observed[n]];
        targetLikelihood += binomial_logit_lpmf(success | total, own_logit);
     }
  }
  }
}
model {
  target += stepping * targetLikelihood + targetPrior;
}
generated quantities {
}
