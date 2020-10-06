library(tidyr)
library(dplyr)


u = read.table("landscapes_2.6_new.R.tsv")
real = read.table("landscapes_2.6_new_real.R.tsv")
data = read.table("landscapes_2.6_new_data.R.tsv")

library(brms)
sink("output/landscapes_2.6.R_avgs.txt")
model = (brm(OSSameSide_Real_Prob ~ OSSameSide + (1+OSSameSide|Family), data=u))
print(mean(posterior_samples(model)$b_OSSameSide < 0))
print(summary(model))
model = (brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family), data=u))
print(mean(posterior_samples(model)$b_OSSameSide_Real_Prob < 0))
print(summary(model))
u = u %>% mutate(LogOSSameSide = log(OSSameSide+1e-10))
u = u %>% mutate(LogOSSameSide_Real_Prob = log(OSSameSide_Real_Prob+1e-10))
print(summary(brm(LogOSSameSide ~ LogOSSameSide_Real_Prob + (1+LogOSSameSide_Real_Prob|Family), data=u)))
sink()


data = merge(data, real, by=c("Language"))

library(lme4)
sink("output/landscapes_2.6.R.txt")
print(summary(glmer(OSSameSide ~ OSSameSide_Real + (1|Language), family="binomial", data=data)))
print(summary(glmer(OSSameSide ~ log(OSSameSide_Real_Prob+1e-10) + (1|Language), family="binomial", data=data)))
print(summary(glmer(OSSameSide ~ OSSameSide_Real_Prob + (1|Language) + (1+OSSameSide_Real_Prob|Family), family="binomial", data=data)))
print(cor.test(u$OSSameSide, u$OSSameSide_Real+0.0))
print(u[order(u$OSSameSide),])
sink()

data$OSSameSide_Real_Prob_Log = log(data$OSSameSide_Real_Prob)


#########################
#########################
library(brms)
model = brm(OSSameSide ~ OSSameSide_Real_Prob_Log + (1|Language) + (1+OSSameSide_Real_Prob_Log|Family), family="bernoulli", data=data)
capture.output(summary(model), file="output/landscapes_2.6.R_brms.txt")
samp = posterior_samples(model)
capture.output(mean(samp$b_OSSameSide_Real_Prob_Log > 0), file="output/landscapes_2.6.R_brms.txt", append=TRUE)


