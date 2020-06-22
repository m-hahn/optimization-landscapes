library(tidyr)
library(dplyr)

DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
data = data %>% filter(HeadPOS == "VERB", DependentPOS == "NOUN") %>% select(-HeadPOS, -DependentPOS)



#DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl


dataO = data %>% filter(CoarseDependency == "obj")
dataS = data %>% filter(CoarseDependency == "nsubj")

data = merge(dataO, dataS, by=c("Language_", "FileName"))

data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))

data = data %>% mutate(Order = ifelse(OSSameSide & OFartherThanS, "VSO", ifelse(OSSameSide, "SOV", "SVO")))

u = data %>% group_by(Language_) %>% summarise(OSSameSide = mean(OSSameSide))
print(u[order(u$OSSameSide),], n=60)

sigmoid = function(x) {
	return(1/(1+exp(-x)))
}

real = read.csv("../grammar-optim/grammars/manual_output_funchead_ground_coarse_final/auto-summary-lstm.tsv", sep="\t")
realO = real %>% filter(Dependency == "obj")
realS = real %>% filter(Dependency == "nsubj")

real = merge(realO, realS, by=c("Language", "FileName", "ModelName"))

real = real %>% mutate(OFartherThanS_Real = (Distance_Mean_NoPunct.x > Distance_Mean_NoPunct.y))
real = real %>% mutate(OSSameSide_Real = (sign(DH_Mean_NoPunct.x) == sign(DH_Mean_NoPunct.y)))
real = real %>% mutate(OSSameSide_Real_Prob = (sigmoid(DH_Mean_NoPunct.x) * sigmoid(DH_Mean_NoPunct.y)) + ((1-sigmoid(DH_Mean_NoPunct.x)) * (1-sigmoid(DH_Mean_NoPunct.y))))

real = real %>% mutate(Order_Real = ifelse(OSSameSide_Real & OFartherThanS_Real, "VSO", ifelse(OSSameSide_Real, "SOV", "SVO")))

u = merge(u %>% mutate(Language = Language_), real %>% select(Language, OSSameSide_Real, OSSameSide_Real_Prob), by=c("Language"))

cor.test(u$OSSameSide, u$OSSameSide_Real+0.0)
u[order(u$OSSameSide),]


data = merge(data %>% mutate(Language=Language_), real, by=c("Language"))

summary(glmer(OSSameSide ~ OSSameSide_Real + (1|Language), family="binomial", data=data))
summary(glmer(OSSameSide ~ log(OSSameSide_Real_Prob+1e-10) + (1|Language), family="binomial", data=data))





