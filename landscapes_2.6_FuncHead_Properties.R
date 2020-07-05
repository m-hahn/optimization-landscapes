library(tidyr)
library(dplyr)

perSentence = read.csv("optimizeDLM/perSentence/outputs/collectSentencesProperties_FuncHead.py.tsv", sep="\t")


SCR = "~/CS_SCR/"
DEPS = paste(SCR,"/deps/", sep="")
#DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_funchead", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
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


u = data %>% group_by(Language, Family) %>% summarise(OSSameSide = mean(OSSameSide))
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
summary(lm(OSSameSide ~ isRoot + objects + subjectLength + verbDependents+ verbLength, data=u))
summary(lm(OSSameSide_Real_Prob ~ isRoot + objects + subjectLength + verbDependents+ verbLength, data=u))
summary(lm(OSSameSide_Real_Prob ~ objects, data=u))

library(lme4)
summary(lmer(OSSameSide_Real_Prob ~ objects + (1+objects|Family), data=u))
summary(lmer(OSSameSide ~ objects + (1+objects|Family), data=u))

data = merge(data, real, by=c("Language"))
data = merge(data, perSentence, by=c("Language"), all=TRUE)

summary(glm(OSSameSide ~ isRoot + objects + subjectLength + verbDependents+ verbLength, data=data, family="binomial"))

data$OSSameSide_Real_Prob_Log = log(data$OSSameSide_Real_Prob)

library(ggplot2)
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=isRoot, color=Family)) + geom_label(aes(label=Language)) 
plot = ggplot(u, aes(x=OSSameSide, y=isRoot, color=Family)) + geom_label(aes(label=Language)) 
plot = ggplot(u, aes(x=OSSameSide_Real_SemiProb, y=objects, color=Family)) + geom_label(aes(label=Language)) 
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=objects, color=Family)) + geom_label(aes(label=Language)) 
ggsave("figures/objects-order.pdf", width=10, height=10)

plot = ggplot(u %>% group_by(Family) %>% summarise(OSSameSide_Real_Prob = mean(OSSameSide_Real_Prob), objects=mean(objects)), aes(x=OSSameSide_Real_Prob, y=objects, color=Family)) + geom_label(aes(label=Family)) 
ggsave("figures/objects-order-families.pdf")


plot = ggplot(u, aes(x=OSSameSide, y=objects, color=Family)) + geom_label(aes(label=Language)) 
plot = ggplot(u, aes(x=OSSameSide, y=subjectLength, color=Family)) + geom_label(aes(label=Language)) 

