library(tidyr)
library(dplyr)


u = read.table("landscapes_2.6_new.R.tsv")
real = read.table("landscapes_2.6_new_real.R.tsv")
data = read.table("landscapes_2.6_new_data.R.tsv")

genera = read.csv("genera.tsv", sep="\t")
u = merge(u, genera, by=c("Language", "Family"), all.x=TRUE)

library(brms)

data = merge(data, real, by=c("Language"))
data = merge(data, genera, by=c("Language", "Family"))

data$OSSameSide_Real_Prob_Log = log(data$OSSameSide_Real_Prob)


#########################
#########################
library(brms)
model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1|Language) + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), family="bernoulli", data=data)
capture.output(summary(model), file="output/landscapes_2.6.R_brms_genera.txt")
samp = posterior_samples(model)
capture.output(mean(samp$b_OSSameSide_Real_Prob > 0), file="output/landscapes_2.6.R_brms_genera.txt", append=TRUE)

library(brms)
model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1|Language) + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), family="bernoulli", data=data %>% filter(Genus!="Indo_European"))
capture.output(summary(model), file="output/landscapes_2.6.R_brms_genera_NoIE.txt")
samp = posterior_samples(model)
capture.output(mean(samp$b_OSSameSide_Real_Prob > 0), file="output/landscapes_2.6.R_brms_genera_NoIE.txt", append=TRUE)



v = data %>% group_by(Language, Family, Genus, OSSameSide_Real_Prob) %>% summarise(OSSameSide=mean(OSSameSide, na.rm=TRUE))





model_lme4 = lmer(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v)
capture.output(summary(model_lme4), file="output/landscapes_2.6.R_brms_genera_linear_lme4.txt")
library(MuMIn)
capture.output(r.squaredGLMM(model_lme4), file="output/landscapes_2.6.R_brms_genera_linear_lme4.txt", append=TRUE)


residuals = resid(model_lme4)
v$Resid = residuals


library(ggplot2)
# Plot the residuals by genus
plot = ggplot(v, aes(x=OSSameSide_Real_Prob, y=Resid, group=Language, color=Family)) + geom_text(aes(label=Language)) + facet_wrap(~Genus)
plot = ggplot(v, aes(x=Resid)) + geom_histogram() + facet_wrap(~Genus)


model_NoIE = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v %>% filter(Genus!="Indo_European"))
capture.output(summary(model_NoIE), file="output/landscapes_2.6.R_brms_genera_NoIE_linear.txt")
samp = posterior_samples(model_NoIE)
capture.output(mean(samp$b_OSSameSide_Real_Prob > 0), file="output/landscapes_2.6.R_brms_genera_NoIE_linear.txt", append=TRUE)
capture.output(bayes_R2(model_NoIE), file="output/landscapes_2.6.R_brms_genera_NoIE_linear.txt", append=TRUE)




model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v)
capture.output(summary(model), file="output/landscapes_2.6.R_brms_genera_linear.txt")
samp = posterior_samples(model)
capture.output(mean(samp$b_OSSameSide_Real_Prob > 0), file="output/landscapes_2.6.R_brms_genera_linear.txt", append=TRUE)
capture.output(bayes_R2(model), file="output/landscapes_2.6.R_brms_genera_linear.txt", append=TRUE)


#hist(samp$b_OSSameSide_Real_Prob + samp[["r_Genus[Niger-Congo,OSSameSide_Real_Prob]"]])

# Posteriors:
genera = c("Afro_Asiatic", "Indo_European", "Niger-Congo", "Sino-Tibetan", "Turkic", "Uralic")
slopes = data.frame(Genus=c(), Coefficient=c())
for(genus in genera) {
	coeffs = samp$b_OSSameSide_Real_Prob + samp[[paste("r_Genus[", genus, ",OSSameSide_Real_Prob]", sep="")]]
	slopes2 = data.frame(Coefficient=coeffs)
	slopes2$Genus=genus
	slopes=rbind(slopes, slopes2)
}

# Posterior over the slope by language family (excluding those with just one represented member)
library(ggplot2)
plot = ggplot(slopes, aes(x=Coefficient, group=Genus, color=Genus)) + geom_density()



# Plot by genus
library(ggplot2)
plot = ggplot(v, aes(x=OSSameSide_Real_Prob, y=OSSameSide, group=Language, color=Family)) + geom_text(aes(label=Language)) + facet_wrap(~Genus)


# Different priors
model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v)
#> prior_summary(model)
#                    prior     class                 coef  group resp dpar nlpar
#1                                 b                                            
#2                                 b OSSameSide_Real_Prob                       
#3  student_t(3, 0.5, 2.5) Intercept                                            
#4    lkj_corr_cholesky(1)         L                                            
#5                                 L                      Family                
#6                                 L                       Genus                
#7    student_t(3, 0, 2.5)        sd                                            
#8                                sd                      Family                
#9                                sd            Intercept Family                
#10                               sd OSSameSide_Real_Prob Family                
#11                               sd                       Genus                
#12                               sd            Intercept  Genus                
#13                               sd OSSameSide_Real_Prob  Genus                
#14   student_t(3, 0, 2.5)     sigma                                 


#This is the model as we have it
model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v, prior=set_prior("student_t(3, 0, 2.5)", class="sd"))

model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v, prior=set_prior("student_t(3, 0, 0.5)", class="sd"))
#                     Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                0.30      0.06     0.18     0.43 1.00     1924
#OSSameSide_Real_Prob     0.41      0.12     0.18     0.66 1.00     1635

model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v, prior=set_prior("student_t(3, 0, 10)", class="sd"))
#                     Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                0.30      0.07     0.17     0.44 1.00     2714
#OSSameSide_Real_Prob     0.42      0.13     0.16     0.68 1.00     2307

model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v, prior=set_prior("student_t(3, 0, 0.1)", class="sd"))
#                     Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                0.30      0.06     0.19     0.42 1.00     3370
#OSSameSide_Real_Prob     0.41      0.10     0.20     0.61 1.00     2986


model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v, prior=set_prior("normal(0,1)", class="sd"))



model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v, prior=c(set_prior("student_t(3, 0, 0.5)", class="sd"), set_prior("student_t(3, 0, 0.5)", class="sigma")))
#                     Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                0.30      0.06     0.18     0.42 1.00     2927
#OSSameSide_Real_Prob     0.41      0.12     0.18     0.65 1.00     2352


model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v, prior=c(set_prior("student_t(3, 0, 0.1)", class="sd"), set_prior("student_t(3, 0, 0.1)", class="sigma")))
#                     Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                0.30      0.06     0.19     0.41 1.00     3473
#OSSameSide_Real_Prob     0.41      0.10     0.20     0.61 1.00     2806


model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v, prior=c(set_prior("normal(0,1)", class="sd"), set_prior("normal(0,1)", class="sigma")))
#                     Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                0.30      0.06     0.18     0.43 1.00     2604
#OSSameSide_Real_Prob     0.41      0.12     0.17     0.67 1.00     2298


model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v, prior=c(set_prior("normal(0,0.1)", class="sd"), set_prior("normal(0,0.1)", class="sigma")))
#                     Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                0.31      0.06     0.20     0.42 1.00     3445
#OSSameSide_Real_Prob     0.40      0.10     0.19     0.60 1.00     2730

# Extreme case of regularization (not advisable, but just for illustration what happens)!
model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family) + (1+OSSameSide_Real_Prob|Genus), data=v, prior=c(set_prior("normal(0,0.01)", class="sd"), set_prior("normal(0,0.01)", class="sigma")))
#                     Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                0.31      0.03     0.25     0.37 1.00     3240
#OSSameSide_Real_Prob     0.39      0.05     0.29     0.50 1.00     3649





