library(tidyr)
library(dplyr)
library(ggrepel)
library(ggplot2)
library(stringr)

u = read.csv("../landscapes_2.6_new.R.tsv", sep=" ") %>% select(Language, Family, OSSameSide, OSSameSide_Real, OSSameSide_Real_Prob)

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


us = data.frame()

us = rbind(us, u %>% filter(Language %in% c("Classical_Chinese_2.6", "Chinese_2.6")) %>% mutate(Trajectory="Mandarin", Group="Chinese") %>% mutate(Time = ifelse(Age == -1, "-400", "+2000")))
us = rbind(us, u %>% filter(Language %in% c("Classical_Chinese_2.6", "Cantonese_2.6")) %>% mutate(Trajectory="Cantonese", Group="Chinese") %>% mutate(Time = ifelse(Age == -1, "-400", "+2000")))
us = rbind(us, u %>% filter(Language %in% c("ISWOC_Old_English", "English_2.6")) %>% mutate(Trajectory="English", Group="English") %>% mutate(Time = ifelse(Age == -1, "+900", "+2000")))
us = rbind(us, u %>% filter(Language %in% c("Old_French_2.6", "French_2.6")) %>% mutate(Trajectory="Old_French", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Latin_2.6", "Old_French_2.6")) %>% mutate(Trajectory="French", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Latin_2.6", "Spanish_2.6")) %>% mutate(Trajectory="Spanish", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Latin_2.6", "Italian_2.6")) %>% mutate(Trajectory="Italian", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Latin_2.6", "Galician_2.6")) %>% mutate(Trajectory="Galician", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Latin_2.6", "Catalan_2.6")) %>% mutate(Trajectory="Catalan", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Latin_2.6", "Romanian_2.6")) %>% mutate(Trajectory="Romanian", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Latin_2.6", "Portuguese_2.6")) %>% mutate(Trajectory="Portuguese", Group="Romance") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Sanskrit_2.6", "Hindi_2.6")) %>% mutate(Trajectory="Hindi", Group="Indo-Aryan") %>% mutate(Time = ifelse(Age == -1, "-900", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Sanskrit_2.6", "Urdu_2.6")) %>% mutate(Trajectory="Urdu", Group="Indo-Aryan") %>% mutate(Time = ifelse(Age == -1, "-900", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Old_Church_Slavonic_2.6", "Bulgarian_2.6")) %>% mutate(Trajectory="Bulgarian", Group="Eastern South Slavic") %>% mutate(Time = ifelse(Age == -1, "+800", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Old_Russian_2.6", "Russian_2.6")) %>% mutate(Trajectory="Russian", Group="East Slavic") %>% mutate(Time = ifelse(Age == -1, "+1200", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Old_Russian_2.6", "Belarusian_2.6")) %>% mutate(Trajectory="Belarusian", Group="East Slavic") %>% mutate(Time = ifelse(Age == -1, "+1200", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Old_Russian_2.6", "Ukrainian_2.6")) %>% mutate(Trajectory="Ukrainian", Group="East Slavic") %>% mutate(Time = ifelse(Age == -1, "+1200", ifelse(Age==0, "+1200", "+2000"))))
#us = rbind(us, u %>% filter(Language %in% c("Ancient_Greek_2.6", "Greek_2.6")) %>% mutate(Trajectory="Greek", Group="Greek") %>% mutate(Time = ifelse(Age == -1, "+0", ifelse(Age==0, "+1200", "+2000"))))
us = rbind(us, u %>% filter(Language %in% c("Archaic_Greek", "Classical_Greek")) %>% mutate(Trajectory="Classical_Greek", Group="Greek") %>% mutate(Time = ifelse(Language == "Archaic_Greek", "-700", "-400")) %>% mutate(Age = as.numeric(as.character(Time))))
us = rbind(us, u %>% filter(Language %in% c("Classical_Greek", "Koine_Greek")) %>% mutate(Trajectory="Koine_Greek", Group="Greek") %>% mutate(Time = ifelse(Language == "Classical_Greek", "-400", "+0")) %>% mutate(Age = as.numeric(as.character(Time))))
us = rbind(us, u %>% filter(Language %in% c("Koine_Greek", "Greek_2.6")) %>% mutate(Trajectory="Modern_Greek", Group="Greek") %>% mutate(Time = ifelse(Language == "Koine_Greek", "+0", "+2000")) %>% mutate(Age = as.numeric(as.character(Time))))





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

library(brms)
#imake_stancode(Dev_FALSE.x - Dev_FALSE.y ~ Dev_TRUE.x + (1+Dev_TRUE.x|Group), data=baselines %>% filter(Baseline==3))



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


library(MASS)

# Instantaneous Fluctuations
sigma=c(1.48, 0.99, 0.99, 0.86)
dim(sigma)=c(2,2)

# Stationary Variance
omega=c(1.00, 0.63, 0.63, 0.52)
dim(omega)=c(2,2)

# Drift vector
drift = c(0.82, 0, 0, 0.89)
dim(drift)=c(2,2)


stationary_sample = mvrnorm(n=1000, mu=c(0,0), Sigma=omega)

sigmoid = function(x) {
	return(1/(1+exp(-x)))
}



library(ggrepel)

library(ggplot2)
#  %>% filter(Language %in% c("Chinese_2.6", "Cantonese_2.6", "Classical_Chinese_2.6", "French_2.6", "Old_French_2.6", "Russian_2.6", "Old_Russian_2.6", "Latin_2.6", "Greek_2.6", "Ancient_Greek_2.6", "Sanskrit_2.6", "Urdu_2.6", "Hindi_2.6", "Spanish_2.6", "Italian_2.6"))
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=OSSameSide)) #+ geom_smooth(method="lm")
plot = plot + geom_density2d(data=data.frame(Real = (stationary_sample[,2]+1)/2, Model = sigmoid(stationary_sample[,1])), aes(x=Real, y=Model), alpha=0.5)
plot = plot + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + xlim(-0.1,1.0) + ylim(0.0,1.0)
for(group in unique(us$Group)) { 
   plot = plot + geom_segment(data= u2s %>% filter(Group == group), aes(x=OSSameSide_Real_Prob_TRUE, xend=OSSameSide_Real_Prob_FALSE, y=OSSameSide_TRUE, yend=OSSameSide_FALSE), arrow=arrow(), size=1, color="blue") + geom_label(data=us %>% filter(Group == group), aes(label=Time), color="black", size=3)
}
plot = plot + facet_wrap(~Group, nrow=2)
plot = plot + theme_bw()
plot = plot + theme(panel.grid = element_blank())
plot = plot + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16), strip.text.x = element_text(size = 10))
ggsave("../figures/historical_2.6_times_stationary_layout.pdf", width=10, height=5)


cor.test(u2s$OSSameSide_FALSE-u2s$OSSameSide_TRUE, u2s$OSSameSide_Real_Prob_FALSE-u2s$OSSameSide_Real_Prob_TRUE)

#write.table(us, file="historical/us.tsv", sep="\t")




