library(tidyr)
library(dplyr)

perSentence = read.csv("optimizeDLM/perSentence/outputs/collectSentencesProperties_ByVerb.py.tsv", sep="\t")


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




data = merge(data, real, by=c("Language"))
data = merge(data, perSentence, by=c("Language"), all=TRUE)


data$OSSameSide_Real_Prob_Log = log(data$OSSameSide_Real_Prob)

library(ggplot2)

library(stringr)
u$Language2 = as.character(u$Language)
for(i in (1:nrow(u))) {
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_2.6", "")
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_", " ")
}


library(ggrepel)
library(ggplot2)
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=objects, color=Family)) + geom_text_repel(aes(label=Language2)) + xlab("Real Subject-Object Symmetry") + ylab("Coexpressed Subjects and Objects") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())
ggsave("figures/objects-order-pureud-byVerb_FORMAT.pdf", width=7, height=7)




