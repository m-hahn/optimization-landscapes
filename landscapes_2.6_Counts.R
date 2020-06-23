library(tidyr)
library(dplyr)

DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
data = data %>% filter(HeadPOS == "VERB", DependentPOS == "NOUN") %>% select(-HeadPOS, -DependentPOS)



#DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl


dataO = data %>% filter(CoarseDependency == "obj")
dataS = data %>% filter(CoarseDependency == "nsubj")

data = merge(dataO, dataS, by=c("Language", "FileName"))



families = read.csv("families.tsv", sep="\t")
data=merge(data, families, by=c("Language"))



data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))

data = data %>% mutate(Order = ifelse(OSSameSide & OFartherThanS, "VSO", ifelse(OSSameSide, "SOV", "SVO")))

u = data %>% group_by(Family, Language) %>% summarise(OSSameSide = mean(OSSameSide))
print(u[order(u$OSSameSide),], n=60)

sigmoid = function(x) {
	return(1/(1+exp(-x)))
}


real = read.csv("optimizeDLM/countsSubjObjOrder.tsv", sep="\t")

real = real%>% mutate(SameLogProb = log((Same+1)/(Mixed+Same+Opposite+1)))


u = merge(u, real, by=c("Language"))



cor.test(u$OSSameSide, u$SameLogProb+0.0)
u = u[order(u$OSSameSide),]


data = merge(data, real, by=c("Language"))

library(lme4)

summary(glmer(OSSameSide ~ SameLogProb + (1|Language), family="binomial", data=data))



#library(brms)
#summary(brm(OSSameSide ~ SameLogProb + (1|Language) + (1+SameLogProb|Family), family="bernoulli", data=data))







