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
model = brm(OSSameSide ~ OSSameSide_Real_Prob_Log + (1|Language) + (1+OSSameSide_Real_Prob_Log|Family) + (1+OSSameSide_Real_Prob_Log|Genus), family="bernoulli", data=data)
capture.output(summary(model), file="output/landscapes_2.6.R_brms_genera.txt")
samp = posterior_samples(model)
capture.output(mean(samp$b_OSSameSide_Real_Prob_Log > 0), file="output/landscapes_2.6.R_brms_genera.txt", append=TRUE)

library(brms)
model = brm(OSSameSide ~ OSSameSide_Real_Prob_Log + (1|Language) + (1+OSSameSide_Real_Prob_Log|Family) + (1+OSSameSide_Real_Prob_Log|Genus), family="bernoulli", data=data %>% filter(Genus!="Indo_European"))
capture.output(summary(model), file="output/landscapes_2.6.R_brms_genera_NoIE.txt")
samp = posterior_samples(model)
capture.output(mean(samp$b_OSSameSide_Real_Prob_Log > 0), file="output/landscapes_2.6.R_brms_genera_NoIE.txt", append=TRUE)


