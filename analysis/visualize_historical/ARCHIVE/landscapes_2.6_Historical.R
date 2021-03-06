library(tidyr)
library(dplyr)

SCR = "~/CS_SCR/"
DEPS = paste(SCR,"/deps/", sep="")
#DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
dataBackup = data
data = data %>% filter(HeadPOS == "VERB", DependentPOS == "NOUN") %>% select(-HeadPOS, -DependentPOS)


# OldEnglish: OSSameSide 0.769, OSSameSide_Real_Prob 0.49

#DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl
#(base) mhahn@sc:~/scr/CODE/optimization-landscapes/optimizeDLM/OldEnglish$ ls output/
#ISWOC_Old_English_inferWeights_PerText.py_model_9104261.tsv


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

real = real %>% mutate(Order_Real = ifelse(OSSameSide_Real & OFartherThanS_Real, "VSO", ifelse(OSSameSide_Real, "SOV", "SVO")))

u = merge(u, real %>% select(Language, OSSameSide_Real, OSSameSide_Real_Prob), by=c("Language"))



data = merge(data, real, by=c("Language"))

data$OSSameSide_Real_Prob_Log = log(data$OSSameSide_Real_Prob)


#########################
#########################

u = rbind(u, data.frame(Language=c("ISWOC_Old_English"), Family=c("Germanic"), OSSameSide = c(0.769), OSSameSide_Real = c(TRUE), OSSameSide_Real_Prob = c(0.49)))
# OldEnglish: OSSameSide 0.769, OSSameSide_Real_Prob 0.49



u$Ancient = (u$Language %in% c("Classical_Chinese_2.6", "Latin_2.6", "Sanskrit_2.6", "Old_Church_Slavonic_2.6", "Old_Russian_2.6", "Ancient_Greek_2.6", "ISWOC_Old_English"))
u$Medieval = (u$Language %in% c("Old_French_2.6", "ISWOC_Spanish"))

u$Age = ifelse(u$Ancient, -1, ifelse(u$Medieval, 0, 1))


u = u[order(u$Age),]
u$Language = factor(u$Language, levels=u$Language)

uMandarin = u %>% filter(Language %in% c("Classical_Chinese_2.6", "Chinese_2.6")) %>% mutate(Group="Chinese (Mandarin)")
u2Mandarin = uMandarin %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uCantonese = u %>% filter(Language %in% c("Classical_Chinese_2.6", "Cantonese_2.6")) %>% mutate(Group="Chinese (Cantonese)")
u2Cantonese = uCantonese %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uEnglish   = u %>% filter(Language %in% c("ISWOC_Old_English", "English_2.6")) %>% mutate(Group="English")
u2English = uEnglish %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uFrench   = u %>% filter(Language %in% c("Old_French_2.6", "French_2.6")) %>% mutate(Group="French")
u2French = uFrench %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uOldFrench   = u %>% filter(Language %in% c("Latin_2.6", "Old_French_2.6")) %>% mutate(Group="French")
u2OldFrench = uOldFrench %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uSpanish  = u %>% filter(Language %in% c("Latin_2.6", "Spanish_2.6")) %>% mutate(Group="Spanish")
u2Spanish = uSpanish %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uHindi    = u %>% filter(Language %in% c("Sanskrit_2.6", "Hindi_2.6")) %>% mutate(Group="Hindi/Urdu")
u2Hindi = uHindi %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uUrdu     = u %>% filter(Language %in% c("Sanskrit_2.6", "Urdu_2.6")) %>% mutate(Group="Hindi/Urdu")
u2Urdu = uUrdu %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uBulgarian     = u %>% filter(Language %in% c("Old_Church_Slavonic_2.6", "Bulgarian_2.6")) %>% mutate(Group="South Slavic")
u2Bulgarian = uBulgarian %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uRussian     = u %>% filter(Language %in% c("Old_Russian_2.6", "Russian_2.6")) %>% mutate(Group="East Slavic")
u2Russian = uRussian %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uGreek     = u %>% filter(Language %in% c("Ancient_Greek_2.6", "Greek_2.6")) %>% mutate(Group="Greek")
u2Greek = uGreek %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))

library(ggrepel)

library(ggplot2)
#  %>% filter(Language %in% c("Chinese_2.6", "Cantonese_2.6", "Classical_Chinese_2.6", "French_2.6", "Old_French_2.6", "Russian_2.6", "Old_Russian_2.6", "Latin_2.6", "Greek_2.6", "Ancient_Greek_2.6", "Sanskrit_2.6", "Urdu_2.6", "Hindi_2.6", "Spanish_2.6", "Italian_2.6"))
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=OSSameSide)) #+ geom_smooth(method="lm")
plot = plot + geom_point(alpha=0.2) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)") + xlim(0,1) + ylim(0,1)
plot = plot + geom_segment(data=u2Mandarin, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_text(data=uMandarin, aes(label=Language), color="black")
plot = plot + geom_segment(data=u2Cantonese, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_text(data=uCantonese, aes(label=Language), color="black")
plot = plot + geom_segment(data=u2French, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_text(data=uFrench, aes(label=Language), color="black")
plot = plot + geom_segment(data=u2OldFrench, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_text(data=uOldFrench, aes(label=Language), color="black")
plot = plot + geom_segment(data=u2Spanish, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_text(data=uSpanish, aes(label=Language), color="black")
plot = plot + geom_segment(data=u2Hindi, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_text(data=uHindi, aes(label=Language), color="black")
plot = plot + geom_segment(data=u2Urdu, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_text(data=uUrdu, aes(label=Language), color="black")
plot = plot + geom_segment(data=u2Bulgarian, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_text(data=uBulgarian, aes(label=Language), color="black")
plot = plot + geom_segment(data=u2Russian, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_text(data=uRussian, aes(label=Language), color="black")
plot = plot + geom_segment(data=u2English, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_text(data=uEnglish, aes(label=Language), color="black")
plot = plot + geom_segment(data=u2Greek, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_text(data=uGreek, aes(label=Language), color="black")
#ggsave("figures/fracion-optimized_DLM_2.6.pdf", height=13, width=13)
plot = plot + facet_wrap(~Group)
ggsave("figures/historical_2.6.pdf", width=10, height=10)


