library(tidyr)
library(dplyr)

perSentence = read.csv("optimizeDLM/perSentence/outputs/collectSentencesProperties_IncludingNonNouns.py.tsv", sep="\t")


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
summary(brm(OSSameSide_Real_Prob ~ isRoot + objects + subjectLength + verbDependents+ verbLength + (1+isRoot + objects + subjectLength + verbDependents+ verbLength|Family), data=u, iter=6000))

summary(lmer(objects ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family), data=u))
u$objects_logOdds = log((u$objects)/(1-u$objects+1e-10))
summary(lmer(objects_logOdds ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family), data=u)) # this essentially corresponds to running a logistic model on the individual clases in the corpus

summary(brm(OSSameSide_Real_Prob ~ objects + (1+objects|Family), data=u, iter=6000))
#Population-Level Effects: 
#          Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
#Intercept     0.52      0.14     0.28     0.80 1.01      765      916
#objects      -0.13      0.36    -0.87     0.50 1.01      802     1425
summary(brm(objects ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family), data=u, iter=6000))
#                     Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                0.43      0.03     0.36     0.50 1.00     4471
#OSSameSide_Real_Prob    -0.15      0.07    -0.29    -0.01 1.00     4527


summary(brm(objects_logOdds ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family), data=u, iter=6000)) # this essentially corresponds to running a logistic model on the individual clases in the corpus



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
ggsave("figures/objects-order-pureud-all.pdf", width=10, height=10)



plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=objects, color=Family)) + geom_label(aes(label=Language)) + facet_wrap(~Family)
ggsave("figures/objects-order-pureud-all-facets.pdf", width=10, height=10)


plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=objects, color=Family)) + geom_label(aes(label=Language)) + facet_wrap(~Family)



plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=correlatingDependents, color=Family)) + geom_label(aes(label=Language)) 



plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=verbLength-subjectLength, color=Family)) + geom_label(aes(label=Language)) 
plot = ggplot(u %>% group_by(Family) %>% summarise(isRoot=mean(isRoot), OSSameSide_Real_Prob=mean(OSSameSide_Real_Prob)), aes(x=OSSameSide_Real_Prob, y=isRoot, color=Family)) + geom_label(aes(label=Family))

plot = ggplot(u %>% group_by(Family) %>% summarise(OSSameSide_Real_Prob = mean(OSSameSide_Real_Prob, na.rm=TRUE), objects=mean(objects, na.rm=TRUE)), aes(x=OSSameSide_Real_Prob, y=objects, color=Family)) + geom_label(aes(label=Family)) 
ggsave("figures/objects-order-families-pureud-all.pdf")


v = u %>% group_by(Family) %>% summarise(OSSameSide_Real_Prob = mean(OSSameSide_Real_Prob), objects=mean(objects))
cor.test(v$OSSameSide_Real_Prob, v$objects)

plot = ggplot(u, aes(x=OSSameSide, y=verbLength, color=Family)) + geom_label(aes(label=Language)) 



plot = ggplot(u, aes(x=OSSameSide, y=objects, color=Family)) + geom_label(aes(label=Language)) 
plot = ggplot(u, aes(x=OSSameSide, y=subjectLength, color=Family)) + geom_label(aes(label=Language)) 



u$Ancient = (u$Language %in% c("Classical_Chinese_2.6", "Latin_2.6", "Sanskrit_2.6", "Old_Church_Slavonic_2.6", "Old_Russian_2.6", "Ancient_Greek_2.6", "ISWOC_Old_English"))
u$Medieval = (u$Language %in% c("Old_French_2.6", "ISWOC_Spanish"))

u$Age = ifelse(u$Ancient, -1, ifelse(u$Medieval, 0, 1))


u = u[order(u$Age),]
u$Language = factor(u$Language, levels=u$Language)

uMandarin = u %>% filter(Language %in% c("Classical_Chinese_2.6", "Chinese_2.6")) %>% mutate(Group="Chinese (Mandarin)") %>% mutate(Time = ifelse(Age == -1, "-400", "+2000"))
u2Mandarin = uMandarin %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, objects, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(objects, OSSameSide_Real_Prob))
uCantonese = u %>% filter(Language %in% c("Classical_Chinese_2.6", "Cantonese_2.6")) %>% mutate(Group="Chinese (Cantonese)") %>% mutate(Time = ifelse(Age == -1, "-400", "+2000"))
u2Cantonese = uCantonese %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, objects, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(objects, OSSameSide_Real_Prob))
uEnglish   = u %>% filter(Language %in% c("ISWOC_Old_English", "English_2.6")) %>% mutate(Group="English") %>% mutate(Time = ifelse(Age == -1, "+900", "+2000"))
u2English = uEnglish %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, objects, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(objects, OSSameSide_Real_Prob))
uFrench   = u %>% filter(Language %in% c("Old_French_2.6", "French_2.6")) %>% mutate(Group="French") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000")))
u2French = uFrench %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, objects, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(objects, OSSameSide_Real_Prob))
uOldFrench   = u %>% filter(Language %in% c("Latin_2.6", "Old_French_2.6")) %>% mutate(Group="French") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000")))
u2OldFrench = uOldFrench %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, objects, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(objects, OSSameSide_Real_Prob))
uSpanish  = u %>% filter(Language %in% c("Latin_2.6", "Spanish_2.6")) %>% mutate(Group="Spanish") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000")))
u2Spanish = uSpanish %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, objects, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(objects, OSSameSide_Real_Prob))
uHindi    = u %>% filter(Language %in% c("Sanskrit_2.6", "Hindi_2.6")) %>% mutate(Group="Hindi/Urdu") %>% mutate(Time = ifelse(Age == -1, "-200", ifelse(Age==0, "+1200", "+2000")))
u2Hindi = uHindi %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, objects, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(objects, OSSameSide_Real_Prob))
uUrdu     = u %>% filter(Language %in% c("Sanskrit_2.6", "Urdu_2.6")) %>% mutate(Group="Hindi/Urdu") %>% mutate(Time = ifelse(Age == -1, "-200", ifelse(Age==0, "+1200", "+2000")))
u2Urdu = uUrdu %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, objects, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(objects, OSSameSide_Real_Prob))
uBulgarian     = u %>% filter(Language %in% c("Old_Church_Slavonic_2.6", "Bulgarian_2.6")) %>% mutate(Group="South Slavic") %>% mutate(Time = ifelse(Age == -1, "+800", ifelse(Age==0, "+1200", "+2000")))
u2Bulgarian = uBulgarian %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, objects, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(objects, OSSameSide_Real_Prob))
uRussian     = u %>% filter(Language %in% c("Old_Russian_2.6", "Russian_2.6")) %>% mutate(Group="East Slavic") %>% mutate(Time = ifelse(Age == -1, "+1200", ifelse(Age==0, "+1200", "+2000")))
u2Russian = uRussian %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, objects, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(objects, OSSameSide_Real_Prob))
uGreek     = u %>% filter(Language %in% c("Ancient_Greek_2.6", "Greek_2.6")) %>% mutate(Group="Greek") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000")))
u2Greek = uGreek %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, objects, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(objects, OSSameSide_Real_Prob))

library(ggplot2)
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=objects)) #+ geom_smooth(method="lm")
plot = plot + geom_point(alpha=0.2) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Objects Fraction") + xlim(0,1) + ylim(0,1)
plot = plot + geom_segment(data=u2Mandarin, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=objects_TRUE, yend=objects_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uMandarin, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Cantonese, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=objects_TRUE, yend=objects_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uCantonese, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2French, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=objects_TRUE, yend=objects_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uFrench, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2OldFrench, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=objects_TRUE, yend=objects_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uOldFrench, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Spanish, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=objects_TRUE, yend=objects_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uSpanish, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Hindi, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=objects_TRUE, yend=objects_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uHindi, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Urdu, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=objects_TRUE, yend=objects_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uUrdu, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Bulgarian, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=objects_TRUE, yend=objects_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uBulgarian, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Russian, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=objects_TRUE, yend=objects_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uRussian, aes(label=Time), color="black")
#plot = plot + geom_segment(data=u2English, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=objects_TRUE, yend=objects_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uEnglish, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Greek, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=objects_TRUE, yend=objects_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uGreek, aes(label=Time), color="black")
plot = plot + facet_wrap(~Group)
ggsave("figures/objects-order-historical-pureud-all.pdf")





