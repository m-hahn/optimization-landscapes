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

data = data %>% mutate(Order = ifelse(OSSameSide & OFartherThanS, "VSO", ifelse(OSSameSide, "SOV", "SVO")))

families = read.csv("families.tsv", sep="\t")
data = merge(data, families, by=c("Language"))


u = data %>% group_by(Language, Family) %>% summarise(OSSameSide = mean(OSSameSide), OFartherThanS = mean(OFartherThanS))
print(u[order(u$OSSameSide),], n=60)

sigmoid = function(x) {
	return(1/(1+exp(-x)))
}


real = read.csv("optimizeDLM/countsSubjObjOrder.tsv", sep="\t")

real = real%>% mutate(SameFraction = ((Same+1)/(Mixed+Same+Opposite+1)))
real = real%>% mutate(LogSameFraction = log(SameFraction))



u = merge(u, real, by=c("Language"))



library(brms)
sink("output/landscapes_2.6_Counts.R_avgs.txt")
model = (brm(SameFraction ~ OSSameSide + (1+OSSameSide|Family), data=u))
print(mean(posterior_samples(model)$b_OSSameSide < 0))
print(summary(model))
model = (brm(OSSameSide ~ SameFraction + (1+SameFraction|Family), data=u))
print(mean(posterior_samples(model)$b_SameFraction < 0))
print(summary(model))
u = u %>% mutate(LogOSSameSide = log(OSSameSide+1e-10))
u = u %>% mutate(LogSameFraction = log(SameFraction+1e-10))
print(summary(brm(LogOSSameSide ~ LogSameFraction + (1+LogSameFraction|Family), data=u)))
sink()



#data = merge(data, real, by=c("Language"))

library(lme4)

library(ggplot2)
plot = ggplot(u, aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)") + theme_bw()
ggsave("figures/fracion-optimized_DLM_2.6_Counts.pdf", height=13, width=13)




#summary(glmer(OSSameSide ~ SameLogProb + (1|Language), family="binomial", data=data))
#
#
#
##library(brms)
##summary(brm(OSSameSide ~ SameLogProb + (1|Language) + (1+SameLogProb|Family), family="bernoulli", data=data))
#
#
#library(ggplot2)
#plot = ggplot(u, aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
#ggsave("figures/fracion-optimized_2.6.pdf", height=13, width=13)
#
#
#
#plot = ggplot(u %>% filter(Family=="Slavic"), aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
#ggsave("figures/fracion-optimized_2.6_Slavic.pdf", height=13, width=13)
#
#plot = ggplot(u %>% filter(Family=="Latin_Romance"), aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
#ggsave("figures/fracion-optimized_2.6_Latin_Romance.pdf", height=13, width=13)
#
#
#plot = ggplot(u %>% filter(Family=="Germanic"), aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
#ggsave("figures/fracion-optimized_2.6_Germanic.pdf", height=13, width=13)
#
#
#plot = ggplot(u %>% filter(Family=="Semitic"), aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
#ggsave("figures/fracion-optimized_2.6_Semitic.pdf", height=13, width=13)
#
#
#
#
#
#
#
