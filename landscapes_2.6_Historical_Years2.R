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
u = rbind(u, data.frame(Language=c("Archaic_Greek"), Family=c("Germanic"), OSSameSide = c(0.8), OSSameSide_Real = c(TRUE), OSSameSide_Real_Prob = c(0.56)))
u = rbind(u, data.frame(Language=c("Classical_Greek"), Family=c("Germanic"), OSSameSide = c(0.53), OSSameSide_Real = c(TRUE), OSSameSide_Real_Prob = c(0.52)))
u = rbind(u, data.frame(Language=c("Koine_Greek"), Family=c("Germanic"), OSSameSide = c(0.67), OSSameSide_Real = c(TRUE), OSSameSide_Real_Prob = c(0.47)))
# OldEnglish: OSSameSide 0.769, OSSameSide_Real_Prob 0.49



u$Ancient = (u$Language %in% c("Classical_Chinese_2.6", "Latin_2.6", "Sanskrit_2.6", "Old_Church_Slavonic_2.6", "Old_Russian_2.6", "Ancient_Greek_2.6", "ISWOC_Old_English"))
u$Medieval = (u$Language %in% c("Old_French_2.6", "ISWOC_Spanish"))

u$Age = ifelse(u$Ancient, -1, ifelse(u$Medieval, 0, 1))


u = u[order(u$Age),]
u$Language = factor(u$Language, levels=u$Language)

uMandarin = u %>% filter(Language %in% c("Classical_Chinese_2.6", "Chinese_2.6")) %>% mutate(Group="Chinese (Mandarin)") %>% mutate(Time = ifelse(Age == -1, "-400", "+2000"))
u2Mandarin = uMandarin %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uCantonese = u %>% filter(Language %in% c("Classical_Chinese_2.6", "Cantonese_2.6")) %>% mutate(Group="Chinese (Cantonese)") %>% mutate(Time = ifelse(Age == -1, "-400", "+2000"))
u2Cantonese = uCantonese %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uEnglish   = u %>% filter(Language %in% c("ISWOC_Old_English", "English_2.6")) %>% mutate(Group="English") %>% mutate(Time = ifelse(Age == -1, "+900", "+2000"))
u2English = uEnglish %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uFrench   = u %>% filter(Language %in% c("Old_French_2.6", "French_2.6")) %>% mutate(Group="French") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000")))
u2French = uFrench %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uOldFrench   = u %>% filter(Language %in% c("Latin_2.6", "Old_French_2.6")) %>% mutate(Group="French") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000")))
u2OldFrench = uOldFrench %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uSpanish  = u %>% filter(Language %in% c("Latin_2.6", "Spanish_2.6")) %>% mutate(Group="Spanish") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000")))
u2Spanish = uSpanish %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uHindi    = u %>% filter(Language %in% c("Sanskrit_2.6", "Hindi_2.6")) %>% mutate(Group="Hindi/Urdu") %>% mutate(Time = ifelse(Age == -1, "-200", ifelse(Age==0, "+1200", "+2000")))
u2Hindi = uHindi %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uUrdu     = u %>% filter(Language %in% c("Sanskrit_2.6", "Urdu_2.6")) %>% mutate(Group="Hindi/Urdu") %>% mutate(Time = ifelse(Age == -1, "-200", ifelse(Age==0, "+1200", "+2000")))
u2Urdu = uUrdu %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uBulgarian     = u %>% filter(Language %in% c("Old_Church_Slavonic_2.6", "Bulgarian_2.6")) %>% mutate(Group="South Slavic") %>% mutate(Time = ifelse(Age == -1, "+800", ifelse(Age==0, "+1200", "+2000")))
u2Bulgarian = uBulgarian %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))
uRussian     = u %>% filter(Language %in% c("Old_Russian_2.6", "Russian_2.6")) %>% mutate(Group="East Slavic") %>% mutate(Time = ifelse(Age == -1, "+1200", ifelse(Age==0, "+1200", "+2000")))
u2Russian = uRussian %>% mutate(Earlier = (Age == min(Age))) %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))

uGreek1     = u %>% filter(Language %in% c("Archaic_Greek", "Classical_Greek")) %>% mutate(Group="Greek") %>% mutate(Time = ifelse(Language == "Archaic_Greek", "-700", "-400")) %>% mutate(Earlier=ifelse(Language == "Archaic_Greek", TRUE, FALSE))
u2Greek1 = uGreek1 %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))

uGreek2     = u %>% filter(Language %in% c("Classical_Greek", "Koine_Greek")) %>% mutate(Group="Greek") %>% mutate(Time = ifelse(Language == "Classical_Greek", "-400", "+0")) %>% mutate(Earlier=ifelse(Language == "Classical_Greek", TRUE, FALSE))
u2Greek2 = uGreek2 %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))


uGreek3     = u %>% filter(Language %in% c("Koine_Greek", "Greek_2.6")) %>% mutate(Group="Greek") %>% mutate(Time = ifelse(Language == "Koine_Greek", "+0", "+2000")) %>% mutate(Earlier=ifelse(Language == "Koine_Greek", TRUE, FALSE))
u2Greek3 = uGreek3 %>% select(Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob))


library(ggrepel)

library(ggplot2)
#  %>% filter(Language %in% c("Chinese_2.6", "Cantonese_2.6", "Classical_Chinese_2.6", "French_2.6", "Old_French_2.6", "Russian_2.6", "Old_Russian_2.6", "Latin_2.6", "Greek_2.6", "Ancient_Greek_2.6", "Sanskrit_2.6", "Urdu_2.6", "Hindi_2.6", "Spanish_2.6", "Italian_2.6"))
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=OSSameSide)) #+ geom_smooth(method="lm")
plot = plot + geom_point(alpha=0.2) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)") + xlim(0,1) + ylim(0,1)
plot = plot + geom_segment(data=u2Mandarin, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uMandarin, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Cantonese, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uCantonese, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2French, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uFrench, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2OldFrench, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uOldFrench, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Spanish, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uSpanish, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Hindi, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uHindi, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Urdu, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uUrdu, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Bulgarian, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uBulgarian, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Russian, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uRussian, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2English, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uEnglish, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Greek1, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uGreek1, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Greek2, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uGreek2, aes(label=Time), color="black")
plot = plot + geom_segment(data=u2Greek3, aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=uGreek3, aes(label=Time), color="black")
#ggsave("figures/fracion-optimized_DLM_2.6.pdf", height=13, width=13)
plot = plot + facet_wrap(~Group)
#ggsave("figures/historical_2.6_times.pdf", width=10, height=10)


