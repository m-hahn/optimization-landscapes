library(tidyr)
library(dplyr)

SCR = "~/CS_SCR/"
DEPS = paste(SCR,"/deps/", sep="")
#DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
dataBackup = data
data = data %>% filter(HeadPOS == "VERB", DependentPOS == "NOUN") %>% select(-HeadPOS, -DependentPOS)



#DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl


dataO = data %>% filter(CoarseDependency == "obj")
dataS = data %>% filter(CoarseDependency == "nsubj")

data = merge(dataO, dataS, by=c("Language", "FileName"))

data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))
data = data %>% mutate(OSSameSide_Prob = (sigmoid(DH_Weight.x) * sigmoid(DH_Weight.y)) + ((1-sigmoid(DH_Weight.x)) * (1-sigmoid(DH_Weight.y))))

data = data %>% mutate(Order = ifelse(OSSameSide & OFartherThanS, "VSO", ifelse(OSSameSide, "SOV", "SVO")))

families = read.csv("families.tsv", sep="\t")
data = merge(data, families, by=c("Language"))


u = data %>% group_by(Language, Family) %>% summarise(OSSameSide = mean(OSSameSide), OSSameSide_Prob = mean(OSSameSide_Prob), OFartherThanS = mean(OFartherThanS))
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



data = merge(data, real, by=c("Language"))

library(lme4)
sink("output/landscapes_2.6_Cont.R.txt")
print(summary(lmer(OSSameSide_Prob ~ OSSameSide_Real_Prob + (1|Language) + (1+OSSameSide_Real_Prob |Family), data=data)))
print(summary(lmer(OSSameSide_Real_Prob ~ OSSameSide + (1+OSSameSide|Family), data=u)))
print(cor.test(u$OSSameSide_Prob, u$OSSameSide_Real_Prob+0.0))
print(u[order(u$OSSameSide),])
sink()

data$OSSameSide_Real_Prob_Log = log(data$OSSameSide_Real_Prob)


#########################
#########################
library(brms)
model = brm(OSSameSide_Prob ~ OSSameSide_Real_Prob + (1|Language) + (1+OSSameSide_Real_Prob|Family), data=data)
model = brm(OSSameSide_Real_Prob ~ OSSameSide + (1+OSSameSide|Family), data=u)
capture.output(summary(model), file="output/landscapes_2.6_Cont.R_brms.txt")
samp = posterior_samples(model)
capture.output(mean(samp$b_OSSameSide > 0), file="output/landscapes_2.6_Cont.R_brms.txt", append=TRUE)

library(ggplot2)
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=OSSameSide_Prob, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)") + theme_bw()
ggsave("figures/fracion-optimized_DLM_2.6_Cont.pdf", height=13, width=13)


plot = ggplot(u, aes(x=OSSameSide, y=OFartherThanS, color=Family)) + geom_label(aes(label=Language)) 
ggsave("figures/distance_DLM_2.6.pdf", height=13, width=13)

plot = ggplot(u %>% group_by(Family) %>% summarise(OSSameSide_Real_Prob=mean(OSSameSide_Real_Prob), OSSameSide=mean(OSSameSide)), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Family)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")


plot = ggplot(u %>% filter(Family=="Slavic"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Slavic_2.6.pdf", height=13, width=13)

plot = ggplot(u %>% filter(Family=="Latin_Romance"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Latin_Romance_2.6.pdf", height=13, width=13)


plot = ggplot(u %>% filter(Family=="Germanic"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Germanic_2.6.pdf", height=13, width=13)


plot = ggplot(u %>% filter(Family=="Semitic"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Semitic_2.6.pdf", height=13, width=13)

plot = ggplot(u %>% filter(Family=="Greek"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Greek_2.6.pdf", height=13, width=13)

plot = ggplot(u %>% filter(Family=="Indic"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Indic_2.6.pdf", height=13, width=13)


plot = ggplot(u %>% filter(Family=="Celtic"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Celtic_2.6.pdf", height=13, width=13)






#
#
#
#
#
#
