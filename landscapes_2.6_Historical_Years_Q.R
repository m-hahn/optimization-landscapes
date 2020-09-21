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


us = data.frame()

us = rbind(us, u %>% filter(Language %in% c("Classical_Chinese_2.6", "Chinese_2.6")) %>% mutate(Trajectory="Mandarin", Group="Chinese") %>% mutate(Time = ifelse(Age == -1, "-400", "+2000")))
us = rbind(us, u %>% filter(Language %in% c("Classical_Chinese_2.6", "Cantonese_2.6")) %>% mutate(Trajectory="Cantonese", Group="Chinese") %>% mutate(Time = ifelse(Age == -1, "-400", "+2000")))
us = rbind(us, u %>% filter(Language %in% c("ISWOC_Old_English", "English_2.6")) %>% mutate(Trajectory="English", Group="English") %>% mutate(Time = ifelse(Age == -1, "+900", "+2000")))
us = rbind(us, u %>% filter(Language %in% c("Old_French_2.6", "French_2.6")) %>% mutate(Trajectory="Old_French", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Latin_2.6", "Old_French_2.6")) %>% mutate(Trajectory="French", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Latin_2.6", "Spanish_2.6")) %>% mutate(Trajectory="Spanish", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Latin_2.6", "Italian_2.6")) %>% mutate(Trajectory="Italian", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Latin_2.6", "Catalan_2.6")) %>% mutate(Trajectory="Catalan", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Latin_2.6", "Romanian_2.6")) %>% mutate(Trajectory="Romanian", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Latin_2.6", "Portuguese_2.6")) %>% mutate(Trajectory="Portuguese", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Sanskrit_2.6", "Hindi_2.6")) %>% mutate(Trajectory="Hindi", Group="Hindi/Urdu") %>% mutate(Time = ifelse(Age == -1, "-200", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Sanskrit_2.6", "Urdu_2.6")) %>% mutate(Trajectory="Urdu", Group="Hindi/Urdu") %>% mutate(Time = ifelse(Age == -1, "-200", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Old_Church_Slavonic_2.6", "Bulgarian_2.6")) %>% mutate(Trajectory="Bulgarian", Group="South Slavic") %>% mutate(Time = ifelse(Age == -1, "+800", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Old_Russian_2.6", "Russian_2.6")) %>% mutate(Trajectory="Russian", Group="East Slavic") %>% mutate(Time = ifelse(Age == -1, "+1200", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Old_Russian_2.6", "Ukrainian_2.6")) %>% mutate(Trajectory="Ukrainian", Group="East Slavic") %>% mutate(Time = ifelse(Age == -1, "+1200", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Ancient_Greek_2.6", "Greek_2.6")) %>% mutate(Trajectory="Greek", Group="Greek") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))


trajectories = unique(us$Trajectory)

getU2 = function(v) {
	return(v %>% mutate(Earlier = (Age == min(Age))) %>% select(Trajectory, Group, Earlier, OSSameSide, OSSameSide_Real_Prob) %>% pivot_wider(names_from=Earlier, values_from=c(OSSameSide, OSSameSide_Real_Prob)));
}


baselines = data.frame()

getBaselines = function(v, baselines) {
   u3 = rbind(v) %>% rename(OSSameSide_FALSE_=OSSameSide_TRUE, OSSameSide_TRUE_=OSSameSide_FALSE) %>% rename(OSSameSide_FALSE=OSSameSide_FALSE_, OSSameSide_TRUE=OSSameSide_TRUE_) %>% mutate(Baseline=3) # 3: exchange usage Old<->New
   u4 = rbind(v) %>% rename(OSSameSide_Real_Prob_FALSE_=OSSameSide_Real_Prob_TRUE, OSSameSide_Real_Prob_TRUE_=OSSameSide_Real_Prob_FALSE) %>% rename(OSSameSide_Real_Prob_FALSE=OSSameSide_Real_Prob_FALSE_, OSSameSide_Real_Prob_TRUE=OSSameSide_Real_Prob_TRUE_) %>% mutate(Baseline=4) # exchange ordering Old<->New
   u5 = rbind(v) %>% mutate(OSSameSide_Real_Prob_FALSE=OSSameSide_Real_Prob_TRUE) %>% mutate(Baseline=5) # Only change usage, not ordering
   u6 = rbind(v) %>% mutate(OSSameSide_FALSE=OSSameSide_TRUE) %>% mutate(Baseline=6) # Only change ordering, not usage
   baselines = rbind(baselines, v %>% mutate(Baseline=2))
   baselines = rbind(baselines, u3)
   baselines = rbind(baselines, u4)
   baselines = rbind(baselines, u5)
   baselines = rbind(baselines, u6)
   return(baselines)
}
u2s = data.frame()


for(language in trajectories) {
   baselines = getBaselines(getU2(us[us$Trajectory == language,]), baselines)
   u2s = rbind(u2s, getU2(us[us$Trajectory == language,]))
}


baselines = baselines %>% mutate(Dev_FALSE=abs(OSSameSide_FALSE-OSSameSide_Real_Prob_FALSE), Dev_TRUE=abs(OSSameSide_TRUE-OSSameSide_Real_Prob_TRUE))


baselines = merge(baselines, baselines %>% filter(Baseline==2) %>% select(Dev_FALSE, Dev_TRUE, Trajectory), by=c("Trajectory"))

library(lme4)
summary(lmer(Dev_FALSE.x - Dev_FALSE.y ~ 1 + (1|Group), data=baselines %>% filter(Baseline==3))) #
summary(lmer(Dev_FALSE.x - Dev_FALSE.y ~ 1 + (1|Group), data=baselines %>% filter(Baseline==4))) 
summary(lmer(Dev_FALSE.x - Dev_FALSE.y ~ 1 + (1|Group), data=baselines %>% filter(Baseline==5))) 
summary(lmer(Dev_FALSE.x - Dev_FALSE.y ~ 1 + (1|Group), data=baselines %>% filter(Baseline==6))) #

summary(lmer(Dev_TRUE.x - Dev_TRUE.y ~ 1 + (1|Group), data=baselines %>% filter(Baseline==3)))
summary(lmer(Dev_TRUE.x - Dev_TRUE.y ~ 1 + (1|Group), data=baselines %>% filter(Baseline==4))) #
#summary(lmer(Dev_TRUE.x - Dev_TRUE.y ~ 1 + (1|Group), data=baselines %>% filter(Baseline==5)))
#summary(lmer(Dev_TRUE.x - Dev_TRUE.y ~ 1 + (1|Group), data=baselines %>% filter(Baseline==6)))

summary(lmer(Dev_FALSE.x - Dev_FALSE.y + Dev_TRUE.x - Dev_TRUE.y ~ 1 + (1|Group), data=baselines %>% filter(Baseline==3)))
summary(lmer(Dev_FALSE.x - Dev_FALSE.y + Dev_TRUE.x - Dev_TRUE.y ~ 1 + (1|Group), data=baselines %>% filter(Baseline==4)))
summary(lmer(Dev_FALSE.x - Dev_FALSE.y + Dev_TRUE.x - Dev_TRUE.y ~ 1 + (1|Group), data=baselines %>% filter(Baseline==5)))
summary(lmer(Dev_FALSE.x - Dev_FALSE.y + Dev_TRUE.x - Dev_TRUE.y ~ 1 + (1|Group), data=baselines %>% filter(Baseline==6)))





summary(lm(Dev_FALSE.x - Dev_FALSE.y ~ 1, data=baselines %>% filter(Baseline==3)))
summary(lm(Dev_FALSE.x - Dev_FALSE.y ~ 1, data=baselines %>% filter(Baseline==4)))
summary(lm(Dev_FALSE.x - Dev_FALSE.y ~ 1, data=baselines %>% filter(Baseline==5)))
summary(lm(Dev_FALSE.x - Dev_FALSE.y ~ 1, data=baselines %>% filter(Baseline==6)))




library(ggrepel)

library(ggplot2)
#  %>% filter(Language %in% c("Chinese_2.6", "Cantonese_2.6", "Classical_Chinese_2.6", "French_2.6", "Old_French_2.6", "Russian_2.6", "Old_Russian_2.6", "Latin_2.6", "Greek_2.6", "Ancient_Greek_2.6", "Sanskrit_2.6", "Urdu_2.6", "Hindi_2.6", "Spanish_2.6", "Italian_2.6"))
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=OSSameSide)) #+ geom_smooth(method="lm")
plot = plot + geom_segment(data=data.frame(x=c(0,1), y=c(0,1)), aes(x=0, xend=1, y=0, yend=1))
plot = plot + geom_point(alpha=0.2) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)") + xlim(0,1) + ylim(0,1)
for(group in unique(us$Group)) { 
   plot = plot + geom_segment(data= u2s %>% filter(Group == group), aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=us %>% filter(Group == group), aes(label=Time), color="black")
}
plot = plot + facet_wrap(~Group)




