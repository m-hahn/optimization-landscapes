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
  int<lower=1> leaveOut;
}
parameters {
  vector<lower=-1, upper=1>[HiddenN] TraitHidden;
  real<lower=-1, upper=1> traitLoo;
  vector<lower=-2, upper=2>[TotalN] LogitsAll;
  vector<lower=0>[2] sd_1; 

}
transformed parameters {
}
model {


  matrix[2, 2] LSigma = diag_pre_multiply(sd_1, [[1, 0], [0, 1]]);
  matrix[2, 2] Sigma = multiply_lower_tri_self_transpose(LSigma);

  target += student_t_lpdf(sd_1 | 3, 0, 2.5);
//    - 2 * student_t_lccdf(0 | 3, 0, 2.5);
  

  for (n in 2:TotalN) {
     real reference_trait;
     real reference_logit;
     real own_trait;
     real own_logit;
     vector[2] own_overall;
     vector[2] reference_overall;


     if (IsHidden[ParentIndex[n]]) {
         reference_trait = TraitHidden[Total2Hidden[ParentIndex[n]]];
     } else {
         reference_trait = TraitObserved[Total2Observed[ParentIndex[n]]];
     }
     reference_logit = LogitsAll[ParentIndex[n]];
     if (IsHidden[n]) {
        own_trait = TraitHidden[Total2Hidden[n]];
     } else if (n == leaveOut) {
        own_trait = traitLoo;
     } else {
        own_trait = TraitObserved[Total2Observed[n]];
     }
     own_logit = LogitsAll[n];
     own_overall = [own_logit, own_trait]';
     reference_overall = [reference_logit, reference_trait]';
     if(ParentDistance[n] < 0.05) {
       print("Short distance", ParentDistance[n], n);
     }
     target += multi_normal_lpdf(own_overall | reference_overall , ParentDistance[n] * Sigma);
     if(!IsHidden[n] && n != leaveOut) {
        int success = TrialsSuccess[Total2Observed[n]];
        int total = TrialsTotal[Total2Observed[n]];
        target += binomial_logit_lpmf(success | total, own_logit);
     }
  }
}
generated quantities {

     real reference_trait;
     real reference_logit;
     real own_trait;
     real own_logit;
     vector[2] own_overall;
     vector[2] reference_overall;


  matrix[2, 2] Sigma = multiply_lower_tri_self_transpose(diag_pre_multiply(sd_1, [[1, 0], [0, 1]]));
  real likelihoodHere = 0;
  int n = leaveOut;

     if (IsHidden[ParentIndex[n]]) {
         reference_trait = TraitHidden[Total2Hidden[ParentIndex[n]]];
     } else {
         reference_trait = TraitObserved[Total2Observed[ParentIndex[n]]];
     }
     reference_logit = LogitsAll[ParentIndex[n]];
     if (IsHidden[n]) {
        print(TraitObserved[878898]);
        own_trait = TraitHidden[Total2Hidden[n]];
     } else {
        own_trait = TraitObserved[Total2Observed[n]];
     }
     own_logit = LogitsAll[n];
     own_overall = [own_logit, own_trait]';
     // Really should be modified into the following: in the main model, get an estimate of the log-odds but not of the observable coordinate. Then, here, conditional on both the ancestor and the log-odds variable, estimate the observable coordinate.
     reference_overall = [reference_logit, reference_trait]';
     likelihoodHere += multi_normal_lpdf(own_overall | reference_overall , ParentDistance[n] * Sigma);
     if(!IsHidden[n]) {
        int success = TrialsSuccess[Total2Observed[n]];
        int total = TrialsTotal[Total2Observed[n]];
        likelihoodHere += binomial_logit_lpmf(success | total, own_logit);
     } else {
       print(TraitHidden[8778787]);
     }



}

