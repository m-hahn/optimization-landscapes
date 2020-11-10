library(tidyr)
library(dplyr)

SCR = "~/scr/"
#SCR = "~/CS_SCR/"
DEPS = paste(SCR,"/deps/", sep="")
#DEPS = "/u/scr/mhahn/deps/"
data = read.csv("dlm-auto-summary-lstm_2.6.tsv", sep="\t")
dataBackup = data
data = data %>% filter(HeadPOS == "VERB", DependentPOS == "NOUN") %>% select(-HeadPOS, -DependentPOS)



#DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl


dataO = data %>% filter(CoarseDependency == "obj")
dataS = data %>% filter(CoarseDependency == "nsubj")

data = merge(dataO, dataS, by=c("Language", "FileName"))

data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))

data = data %>% mutate(Order = ifelse(OSSameSide & OFartherThanS, "VSO", ifelse(OSSameSide, "SOV", "SVO")))

u = data %>% group_by(Language) %>% summarise(OSSameSideSum=sum(OSSameSide), OSSameSideTotal=NROW(OSSameSide), OSSameSide = mean(OSSameSide), OFartherThanS = mean(OFartherThanS))
u = u %>% mutate(Group = ifelse(grepl("0", Language, "1"), 0, 1))

u$Language2 = as.character(u$Language)
for(i in (1:nrow(u))) {
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_2.6", "")
	u$Language2[[i]] = str_replace(u$Language2[[i]], "1", " ")
	u$Language2[[i]] = str_replace(u$Language2[[i]], "0", " ")
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_", " ")
}

print(u[order(u$OSSameSide),], n=60)

sigmoid = function(x) {
	return(1/(1+exp(-x)))
}

real = read.csv("real-auto-summary-lstm_2.6.tsv", sep="\t")
realO = real %>% filter(Dependency == "obj")
realS = real %>% filter(Dependency == "nsubj")

real = merge(realO, realS, by=c("Language", "FileName", "ModelName"))

real = real %>% mutate(OFartherThanS_Real = (Distance_Mean_NoPunct.x > Distance_Mean_NoPunct.y))
real = real %>% mutate(OSSameSide_Real = (sign(DH_Mean_NoPunct.x) == sign(DH_Mean_NoPunct.y)))
real = real %>% mutate(OSSameSide_Real_Prob = (sigmoid(DH_Mean_NoPunct.x) * sigmoid(DH_Mean_NoPunct.y)) + ((1-sigmoid(DH_Mean_NoPunct.x)) * (1-sigmoid(DH_Mean_NoPunct.y))))

real = real %>% mutate(Order_Real = ifelse(OSSameSide_Real & OFartherThanS_Real, "VSO", ifelse(OSSameSide_Real, "SOV", "SVO")))
real = real %>% mutate(Group = ifelse(grepl("0", Language, "1"), 1, 0))

real$Language2 = as.character(u$Language)
for(i in (1:nrow(real))) {
	real$Language2[[i]] = str_replace(real$Language2[[i]], "_2.6", "")
	real$Language2[[i]] = str_replace(real$Language2[[i]], "1", " ")
	real$Language2[[i]] = str_replace(real$Language2[[i]], "0", " ")
	real$Language2[[i]] = str_replace(real$Language2[[i]], "_", " ")
}

u = merge(u, real %>% select(Language2, Group, OSSameSide_Real, OSSameSide_Real_Prob), by=c("Language2", "Group"))

u = u%>% mutate(Language=NULL, OSSameSideSum=NULL, OSSameSideTotal=NULL, OFartherThanS=NULL, OSSameSide_Real=NULL)


u = rbind(u, data.frame(Language2=c("Japanese", "English"), Group=c("Same", "Same"), OSSameSide=c(0.938, 0.27), OSSameSide_Real_Prob=c(0.999, 0.08)))


library(stringr)


library(ggplot2)
library(ggrepel)
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Group)) + geom_text_repel(aes(label=Language2)) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + theme_bw() + theme(axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank()) + xlim(0,1) + ylim(0,1)
ggsave("plane-disjoint.pdf", height=5, width=5)

