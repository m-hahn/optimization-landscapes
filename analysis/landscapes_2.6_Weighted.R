library(tidyr)
library(dplyr)

SCR = "~/CS_SCR/"
DEPS = paste(SCR,"/deps/", sep="")
#DEPS = "/u/scr/mhahn/deps/"

data = read.csv("optimizeAUC/output_Weighted.tsv", sep="\t")

families = read.csv("families.tsv", sep="\t")
data = merge(data, families, by=c("Language"), all.y=TRUE)


data[is.na(data$SOV),]

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

u = merge(data, real %>% select(Language, OSSameSide_Real, OSSameSide_Real_Prob, Order_Real), by=c("Language"))

cor.test(u$SOV+u$VSO, u$OSSameSide_Real_Prob)

cor.test(u$VSO, 1.0*(u$Order_Real=="VSO"))
cor.test(u$SVO, 1.0*(u$Order_Real=="SVO"))
cor.test(u$SOV, 1.0*(u$Order_Real=="SOV"))

library(lme4)
u$RealSVO = (u$Order_Real == "SVO")
u$RealVSO = (u$Order_Real == "VSO")
u$RealSOV = (u$Order_Real == "SOV")
summary(glmer(RealSOV ~ SOV + (1+SOV|Family), family="binomial", data=u))
summary(glmer(RealSVO ~ SVO + (1+SVO|Family), family="binomial", data=u))
summary(glmer(RealVSO ~ VSO + (1+VSO|Family), family="binomial", data=u))

u$SameSide = u$SOV+u$VSO
summary(lmer(OSSameSide_Real_Prob ~ SameSide + (1+SameSide|Family), data=u))

v = u[u$Order_Real %in% c("VSO", "SOV"),]
v$VSO = v$VSO/(v$VSO+v$SOV)
v %>% group_by(Order_Real) %>% summarise(VSO=mean(VSO, na.rm=TRUE))
v$Order_Real = as.factor(v$Order_Real)
summary(glmer(Order_Real ~ VSO + (1|Family), data=v, family="binomial"))



library(ggplot2)
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=SameSide, color=Order_Real, group=Order_Real)) + geom_label(aes(label=Language))


#> mean(u[u$Order_Real == "SVO",]$SVO)
#[1] 0.4268027
#> mean(u[u$Order_Real == "VSO",]$VSO)
#[1] 0.7460317
#> mean(u[u$Order_Real == "SOV",]$SOV)
#[1] 0.4590136

