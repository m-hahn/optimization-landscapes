library(tidyr)
library(dplyr)

perSentence = read.csv("optimizeDLM/perSentence/outputs/collectSentencesProperties.py.tsv", sep="\t")


SCR = "~/CS_SCR/"
DEPS = paste(SCR,"/deps/", sep="")

families = read.csv("families.tsv", sep="\t")
data = families


u = data
#print(u[order(u$OSSameSide),], n=60)

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

isPositive = function(x) {
	return(1*(x>0))
}

real = real %>% mutate(OSSameSide_Real_SemiProb = (sigmoid(DH_Mean_NoPunct.y) * isPositive(DH_Mean_NoPunct.x)) + ((1-sigmoid(DH_Mean_NoPunct.y)) * (1-isPositive(DH_Mean_NoPunct.x))))

real = real %>% mutate(Order_Real = ifelse(OSSameSide_Real & OFartherThanS_Real, "VSO", ifelse(OSSameSide_Real, "SOV", "SVO")))

u = merge(u, real %>% select(Language, OSSameSide_Real, OSSameSide_Real_Prob, OSSameSide_Real_SemiProb), by=c("Language"))



u = merge(u, perSentence, by=c("Language"), all=TRUE)
#summary(lm(OSSameSide ~ isRoot + objects + subjectLength + verbDependents+ verbLength, data=u))
summary(lm(OSSameSide_Real_Prob ~ isRoot + objects + subjectLength + verbDependents+ verbLength, data=u))
summary(lm(OSSameSide_Real_Prob ~ objects, data=u))

library(lme4)
summary(lmer(OSSameSide_Real_Prob ~ objects + (1+objects|Family), data=u))

library(brms)
summary(brm(OSSameSide_Real_Prob ~ objects + (1+objects|Family), data=u, iter=10000))
#          Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
#Intercept     0.52      0.12     0.31     0.78 1.00     1615      771
#objects      -0.15      0.34    -0.89     0.47 1.00     1520      499
summary(brm(objects ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family), data=u, iter=10000))
#                     Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                0.39      0.04     0.32     0.46 1.00    10176
#OSSameSide_Real_Prob    -0.16      0.07    -0.29    -0.02 1.00     9424



#summary(lmer(OSSameSide ~ objects + (1+objects|Family), data=u))

data = merge(data, real, by=c("Language"))
data = merge(data, perSentence, by=c("Language"), all=TRUE)

#summary(glm(OSSameSide ~ isRoot + objects + subjectLength + verbDependents+ verbLength, data=data, family="binomial"))

data$OSSameSide_Real_Prob_Log = log(data$OSSameSide_Real_Prob)

library(ggplot2)
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=isRoot, color=Family)) + geom_label(aes(label=Language)) 
plot = ggplot(u, aes(x=OSSameSide, y=isRoot, color=Family)) + geom_label(aes(label=Language)) 
plot = ggplot(u, aes(x=OSSameSide_Real_SemiProb, y=objects, color=Family)) + geom_label(aes(label=Language)) 
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=objects, color=Family)) + geom_label(aes(label=Language)) 
ggsave("figures/objects-order-pureud.pdf", width=10, height=10)


plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=correlatingDependents, color=Family)) + geom_label(aes(label=Language)) 



plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=verbLength-subjectLength, color=Family)) + geom_label(aes(label=Language)) 
plot = ggplot(u %>% group_by(Family) %>% summarise(isRoot=mean(isRoot), OSSameSide_Real_Prob=mean(OSSameSide_Real_Prob)), aes(x=OSSameSide_Real_Prob, y=isRoot, color=Family)) + geom_label(aes(label=Family))

plot = ggplot(u %>% group_by(Family) %>% summarise(OSSameSide_Real_Prob = mean(OSSameSide_Real_Prob, na.rm=TRUE), objects=mean(objects, na.rm=TRUE)), aes(x=OSSameSide_Real_Prob, y=objects, color=Family)) + geom_label(aes(label=Family)) 
ggsave("figures/objects-order-families-pureud.pdf")


v = u %>% group_by(Family) %>% summarise(OSSameSide_Real_Prob = mean(OSSameSide_Real_Prob), objects=mean(objects), subjectLength=mean(subjectLength))
cor.test(v$OSSameSide_Real_Prob, v$objects)

plot = ggplot(u, aes(x=OSSameSide, y=verbLength, color=Family)) + geom_label(aes(label=Language)) 



plot = ggplot(u, aes(x=OSSameSide, y=objects, color=Family)) + geom_label(aes(label=Language)) 
plot = ggplot(u, aes(x=OSSameSide, y=subjectLength, color=Family)) + geom_label(aes(label=Language)) 

