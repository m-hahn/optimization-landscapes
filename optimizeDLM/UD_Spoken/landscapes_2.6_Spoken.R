library(tidyr)
library(dplyr)

SCR = "~/scr/"
DEPS = paste(SCR,"/deps/", sep="")
#DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_Spoken", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
dataBackup = data
data = data %>% filter(HeadPOS == "VERB", DependentPOS == "NOUN") %>% select(-HeadPOS, -DependentPOS)



#DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl


dataO = data %>% filter(CoarseDependency == "obj")
dataS = data %>% filter(CoarseDependency == "nsubj")

data = merge(dataO, dataS, by=c("Language", "FileName"))

data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))

data = data %>% mutate(Order = ifelse(OSSameSide & OFartherThanS, "VSO", ifelse(OSSameSide, "SOV", "SVO")))



u = data %>% group_by(Language) %>% summarise(OSSameSide = mean(OSSameSide), OFartherThanS = mean(OFartherThanS))
print(u[order(u$OSSameSide),], n=60)

sigmoid = function(x) {
	return(1/(1+exp(-x)))
}




library(lme4)
print(summary(glmer(OSSameSide ~ OSSameSide_Real + (1|Language), family="binomial", data=data)))
print(summary(glmer(OSSameSide ~ log(OSSameSide_Real_Prob+1e-10) + (1|Language), family="binomial", data=data)))
print(cor.test(u$OSSameSide, u$OSSameSide_Real+0.0))
print(u[order(u$OSSameSide),])

data$OSSameSide_Real_Prob_Log = log(data$OSSameSide_Real_Prob)


#########################
#########################
library(brms)
model = brm(OSSameSide ~ OSSameSide_Real_Prob_Log + (1|Language) + (1+OSSameSide_Real_Prob_Log|Family), family="bernoulli", data=data)
capture.output(summary(model), file="output/landscapes_2.6.R_brms.txt")
samp = posterior_samples(model)
capture.output(mean(samp$b_OSSameSide_Real_Prob_Log > 0), file="output/landscapes_2.6.R_brms.txt", append=TRUE)

library(ggplot2)
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)") + theme_bw()
ggsave("figures/fracion-optimized_DLM_2.6.pdf", height=13, width=13)


plot = ggplot(u, aes(x=OSSameSide, y=OFartherThanS, color=Family)) + geom_label(aes(label=Language)) 
ggsave("figures/distance_DLM_2.6.pdf", height=13, width=13)

plot = ggplot(u %>% group_by(Family) %>% summarise(OSSameSide_Real_Prob=mean(OSSameSide_Real_Prob), OSSameSide=mean(OSSameSide)), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Family)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")


plot = ggplot(u %>% filter(Family=="Slavic"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Slavic_2.6.pdf", height=13, width=13)

plot = ggplot(u %>% filter(Family=="Latin_Romance"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Latin_Romance_2.6.pdf", height=13, width=13)


plot = ggplot(u %>% filter(Family=="Germanic"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Germanic_2.6.pdf", height=13, width=13)


plot = ggplot(u %>% filter(Family=="Semitic"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Semitic_2.6.pdf", height=13, width=13)

plot = ggplot(u %>% filter(Family=="Greek"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Greek_2.6.pdf", height=13, width=13)

plot = ggplot(u %>% filter(Family=="Indic"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Indic_2.6.pdf", height=13, width=13)


plot = ggplot(u %>% filter(Family=="Celtic"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_label(aes(label=Language)) + xlab("Fraction of SOV/VSO/OSV... Orders (Real)") + ylab("Fraction of SOV/VSO/OSV... Orders (DLM Optimized)")+ xlim(0,1) + ylim(0,1)
ggsave("figures/fracion-optimized_DLM_Celtic_2.6.pdf", height=13, width=13)






#
#
#
#
#
#
