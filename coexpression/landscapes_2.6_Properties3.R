library(tidyr)
library(dplyr)

perSentence = read.csv("optimizeDLM/perSentence/outputs/pronominalSubjects.py.tsv", sep="\t")


SCR = "~/CS_SCR/"
DEPS = paste(SCR,"/deps/", sep="")

families = read.csv("families.tsv", sep="\t")
data = families


u = data
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

isPositive = function(x) {
	return(1*(x>0))
}

real = real %>% mutate(OSSameSide_Real_SemiProb = (sigmoid(DH_Mean_NoPunct.y) * isPositive(DH_Mean_NoPunct.x)) + ((1-sigmoid(DH_Mean_NoPunct.y)) * (1-isPositive(DH_Mean_NoPunct.x))))

real = real %>% mutate(Order_Real = ifelse(OSSameSide_Real & OFartherThanS_Real, "VSO", ifelse(OSSameSide_Real, "SOV", "SVO")))

u = merge(u, real %>% select(Language, OSSameSide_Real, OSSameSide_Real_Prob, OSSameSide_Real_SemiProb), by=c("Language"))



u = merge(u, perSentence, by=c("Language"), all=TRUE)
library(lme4)
library(ggplot2)

summary(lmer(OSSameSide_Real_Prob ~ objec_ratio + (1+objec_ratio|Family), data=u))
summary(lmer(OSSameSide_Real_Prob ~ subject_ratio + (1+subject_ratio|Family), data=u))

plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=subject_ratio, color=Family)) + geom_label(aes(label=Language)) 




v = u %>% group_by(Family) %>% summarise(OSSameSide_Real_Prob = mean(OSSameSide_Real_Prob, na.rm=TRUE), SO=mean(SO, na.rm=TRUE), SON=mean(SON, na.rm=TRUE))
plot = ggplot(v, aes(x=OSSameSide_Real_Prob, y=SO, color=Family)) + geom_label(aes(label=Family)) 
cor.test(v$OSSameSide_Real_Prob, v$SO)

