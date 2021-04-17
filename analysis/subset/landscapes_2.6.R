library(tidyr)
library(dplyr)


optimized = read.csv("../../optimizeDLM/subset/auto-summary-lstm_2.6.tsv", sep="\t")
real = read.csv("../../fitGrammars/subset/auto-summary-lstm_2.6.tsv", sep="\t")


dataO = optimized %>% filter(CoarseDependency == "obj")
dataS = optimized %>% filter(CoarseDependency == "nsubj")

data = merge(dataO, dataS, by=c("LanguageBare", "Language", "FileName"))

data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))

data = data %>% mutate(Order = ifelse(OSSameSide & OFartherThanS, "VSO", ifelse(OSSameSide, "SOV", "SVO")))


u = data %>% group_by(LanguageBare, Language) %>% summarise(OSSameSideSum=sum(OSSameSide), OSSameSideTotal=NROW(OSSameSide), OSSameSide = mean(OSSameSide), OFartherThanS = mean(OFartherThanS))
print(u[order(u$OSSameSide),], n=60)

sigmoid = function(x) {
	return(1/(1+exp(-x)))
}

realO = real %>% filter(Dependency == "obj")
realS = real %>% filter(Dependency == "nsubj")

real = merge(realO, realS, by=c("Language", "FileName", "ModelName"))

real = real %>% mutate(OFartherThanS_Real = (Distance_Mean_NoPunct.x > Distance_Mean_NoPunct.y))
real = real %>% mutate(OSSameSide_Real = (sign(DH_Mean_NoPunct.x) == sign(DH_Mean_NoPunct.y)))
real = real %>% mutate(OSSameSide_Real_Prob = (sigmoid(DH_Mean_NoPunct.x) * sigmoid(DH_Mean_NoPunct.y)) + ((1-sigmoid(DH_Mean_NoPunct.x)) * (1-sigmoid(DH_Mean_NoPunct.y))))

real = real %>% mutate(Order_Real = ifelse(OSSameSide_Real & OFartherThanS_Real, "VSO", ifelse(OSSameSide_Real, "SOV", "SVO")))

real2 = data.frame(LanguageBare=c("English_2.6", "Japanese_2.6"), OSSameSide_Real_Prob = c(0.1, 0.99))


sizes = strsplit(as.character(u$Language), "-")
size = c()
for(i in (1:nrow(u))) {
	size = c(sizes[[i]][2], size)
}
u$size = as.numeric(size)


u = u %>% select(OSSameSide, LanguageBare, Language, size)

u = merge(u, real %>% select(Language, OSSameSide_Real_Prob), by=c("Language"), all=TRUE)


u = rbind(as.data.frame(u), data.frame(LanguageBare = c("English_2.6", "Japanese_2.6"), Language = c("English_2.6-31811", "Japanese_2.6-67002"), size=c(31811, 67002), OSSameSide=c(0.3, 0.95), OSSameSide_Real_Prob=c(0.1, 0.99)))


#u = merge(u, real2 %>% select(LanguageBare, OSSameSide_Real_Prob), by=c("LanguageBare"), all=TRUE)

library(ggplot2)
library(ggrepel)



plot = ggplot(u %>% filter(LanguageBare %in% c("English_2.6", "Japanese_2.6")), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=LanguageBare)) + geom_point(show.legend=FALSE) + geom_text_repel(aes(label=size), show.legend=FALSE) + xlim(0, NA) + ylim(0, NA) + theme_bw()
ggsave("figures/by-corpus-size.pdf", width=4, height=4)


