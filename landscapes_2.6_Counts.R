library(tidyr)
library(dplyr)

DEPS = "~/CS_SCR/deps/"
#DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
dataBackup = data
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

real = real%>% mutate(SameFraction = ((Same+1)/(Mixed+Same+Opposite+1)))
real = real%>% mutate(SameLogProb = log((Same+1)/(Mixed+Same+Opposite+1)))


u = merge(u, real, by=c("Language"))



cor.test(u$OSSameSide, u$SameLogProb+0.0)
u = u[order(u$OSSameSide),]


data = merge(data, real, by=c("Language"))

library(lme4)

summary(glmer(OSSameSide ~ SameLogProb + (1|Language), family="binomial", data=data))



#library(brms)
#summary(brm(OSSameSide ~ SameLogProb + (1|Language) + (1+SameLogProb|Family), family="bernoulli", data=data))


library(ggplot2)
plot = ggplot(u, aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
ggsave("figures/fracion-optimized_2.6.pdf", height=13, width=13)



plot = ggplot(u %>% filter(Family=="Slavic"), aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
ggsave("figures/fracion-optimized_2.6_Slavic.pdf", height=13, width=13)

plot = ggplot(u %>% filter(Family=="Latin_Romance"), aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
ggsave("figures/fracion-optimized_2.6_Latin_Romance.pdf", height=13, width=13)


plot = ggplot(u %>% filter(Family=="Germanic"), aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
ggsave("figures/fracion-optimized_2.6_Germanic.pdf", height=13, width=13)


plot = ggplot(u %>% filter(Family=="Semitic"), aes(x=SameFraction, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")
ggsave("figures/fracion-optimized_2.6_Semitic.pdf", height=13, width=13)







