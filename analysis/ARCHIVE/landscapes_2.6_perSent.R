library(tidyr)
library(dplyr)


perSent = read.csv("optimizeDLM/perSentence/Best_ByGroup/results/Simple4.txt", sep="\t")
perSent = perSent %>% group_by(Language) %>% summarise(MaxSame =max(Fraction), MinSame=min(Fraction))


SCR = "~/CS_SCR/"
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

real = merge(real, perSent, by=c("Language"))

cor.test(real$OSSameSide_Real_Prob, real$MaxSame+real$MinSame)

families = read.csv("families.tsv", sep="\t")
real = merge(real, families, by=c("Language"))

library(ggplot2)
plot = ggplot(real, aes(x=OSSameSide_Real_Prob, y=(MaxSame+MinSame)/2, color=Family)) + geom_label(aes(label=Language))

real = real %>% mutate(SameAvg = (MaxSame+MinSame)/2)
library(lme4)
summary(lmer(OSSameSide_Real_Prob ~ SameAvg + (1+SameAvg|Family), data=real))

