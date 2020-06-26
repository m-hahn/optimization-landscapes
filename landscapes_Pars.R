library(tidyr)
library(dplyr)

data = read.csv("../grammar-optim/grammars/manual_output_funchead_two_coarse_parser_best_balanced/auto-summary-lstm.tsv", sep="\t")



dataO = data %>% filter(CoarseDependency == "obj")
dataS = data %>% filter(CoarseDependency == "nsubj")

data = merge(dataO, dataS, by=c("Language", "FileName"))

data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))

data = data %>% mutate(Order = ifelse(OSSameSide & OFartherThanS, "VSO", ifelse(OSSameSide, "SOV", "SVO")))

u = data %>% group_by(Language) %>% summarise(OSSameSide = mean(OSSameSide))
print(u[order(u$OSSameSide),], n=60)

sigmoid = function(x) {
	return(1/(1+exp(-x)))
}

real = read.csv("../grammar-optim/grammars/manual_output_funchead_ground_coarse_final/auto-summary-lstm.tsv", sep="\t")
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
sink("output/landscapes_Pars.R.txt")
cor.test(u$OSSameSide, u$OSSameSide_Real_Prob+0.0)
cor.test(u$OSSameSide, u$OSSameSide_Real+0.0)
u[order(u$OSSameSide),]


summary(glmer(OSSameSide ~ OSSameSide_Real_Prob + (1|Language), family="binomial", data=data))
sink()




#library(brms)
#summary(brm(OSSameSide ~ SameLogProb + (1|Language) + (1+SameLogProb|Family), family="bernoulli", data=data))


library(ggplot2)
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=OSSameSide)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
ggsave("figures/fracion-optimized_Pars.pdf", height=13, width=13)
#
#
#
#plot = ggplot(u %>% filter(Family=="Slavic"), aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
#ggsave("figures/fracion-optimized_Pars_Slavic.pdf", height=13, width=13)
#
#plot = ggplot(u %>% filter(Family=="Latin_Romance"), aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
#ggsave("figures/fracion-optimized_Pars_Latin_Romance.pdf", height=13, width=13)
#
#
#plot = ggplot(u %>% filter(Family=="Germanic"), aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
#ggsave("figures/fracion-optimized_Pars_Germanic.pdf", height=13, width=13)
#
#
#plot = ggplot(u %>% filter(Family=="Semitic"), aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
#ggsave("figures/fracion-optimized_Pars_Semitic.pdf", height=13, width=13)
#
#
#
#
#
#
#
#
