library(tidyr)
library(dplyr)

SCR = "~/CS_SCR/"
DEPS = paste(SCR,"/deps/", sep="")
#DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm_surp_weighted/manual_output_funchead_fine_depl_surp_weighted/", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
dataBackup = data
data = data %>% filter(HeadPOS == "VERB", DependentPOS == "NOUN") %>% select(-HeadPOS, -DependentPOS)



#DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl


dataO = data %>% filter(CoarseDependency == "obj")
dataS = data %>% filter(CoarseDependency == "nsubj")

data = merge(dataO, dataS, by=c("Language", "FileName"))

data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))

data = data %>% mutate(Order = ifelse(OSSameSide & OFartherThanS, "VSO", ifelse(OSSameSide, "SOV", "SVO")))

families = read.csv("families.tsv", sep="\t")
data = merge(data, families, by=c("Language"))


u = data %>% group_by(Language, Family) %>% summarise(OSSameSide = mean(OSSameSide), OFartherThanS = mean(OFartherThanS))
print(u[order(u$OSSameSide),], n=60)

sigmoid = function(x) {
	return(1/(1+exp(-x)))
}

real = read.csv(paste(SCR,"/deps/LANDSCAPE/mle-fine_selected/auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
realO = real %>% filter(Dependency == "obj")
realS = real %>% filter(Dependency == "nsubj")

real = merge(realO, realS, by=c("Language", "FileName", "ModelName"))

real = real %>% mutate(OFartherThanS_Real = (Distance_Mean_NoPunct.x > Distance_Mean_NoPunct.y))
real = real %>% mutate(OSSameSide_Real = (sign(DH_Mean_NoPunct.x) == sign(DH_Mean_NoPunct.y)))
real = real %>% mutate(OSSameSide_Real_Prob = (sigmoid(DH_Mean_NoPunct.x) * sigmoid(DH_Mean_NoPunct.y)) + ((1-sigmoid(DH_Mean_NoPunct.x)) * (1-sigmoid(DH_Mean_NoPunct.y))))

real = real %>% mutate(Order_Real = ifelse(OSSameSide_Real & OFartherThanS_Real, "VSO", ifelse(OSSameSide_Real, "SOV", "SVO")))

u = merge(u, real %>% select(Language, OSSameSide_Real, OSSameSide_Real_Prob), by=c("Language"))

u = u %>% mutate(LogOSSameSide = log(OSSameSide+1e-10))
u = u %>% mutate(LogOSSameSide_Real_Prob = log(OSSameSide_Real_Prob+1e-10))


library(brms)
sink("output/landscapes_2.6_I1.R_avgs.txt")
model = (brm(OSSameSide_Real_Prob ~ OSSameSide + (1+OSSameSide|Family), data=u))
print(mean(posterior_samples(model)$b_OSSameSide < 0))
print(summary(model))
model = (brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family), data=u))
print(mean(posterior_samples(model)$b_OSSameSide_Real_Prob < 0))
print(summary(model))
print(summary(brm(LogOSSameSide ~ LogOSSameSide_Real_Prob + (1+LogOSSameSide_Real_Prob|Family), data=u)))
sink()


data = merge(data, real, by=c("Language"))

library(lme4)
sink("output/landscapes_2.6_I1.R.txt")
print(summary(glmer(OSSameSide ~ OSSameSide_Real + (1|Language), family="binomial", data=data)))
print(summary(glmer(OSSameSide ~ log(OSSameSide_Real_Prob+1e-10) + (1|Language), family="binomial", data=data)))
print(cor.test(u$OSSameSide, u$OSSameSide_Real+0.0))
print(u[order(u$OSSameSide),])
sink()

data$OSSameSide_Real_Prob_Log = log(data$OSSameSide_Real_Prob)


#########################
#########################
library(brms)
model = brm(OSSameSide ~ OSSameSide_Real_Prob_Log + (1|Language) + (1+OSSameSide_Real_Prob_Log|Family), family="bernoulli", data=data)
capture.output(summary(model), file="output/landscapes_2.6_I1.R_brms.txt")
samp = posterior_samples(model)
capture.output(mean(samp$b_OSSameSide_Real_Prob_Log > 0), file="output/landscapes_2.6.R_brms.txt", append=TRUE)

library(ggplot2)
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)") + theme_bw()
ggsave("figures/fracion-optimized_DLM_2.6_I1.pdf", height=13, width=13)


