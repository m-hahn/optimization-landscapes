library(tidyr)
library(dplyr)


u = read.csv("../landscapes_2.6_new.R.tsv", sep=" ")


u = merge(u, read.csv("../WALS/languages-wals-mapping.csv", sep="\t"), by=c("Language"), all.x=TRUE)

wals = read.csv("../../81A.tab", sep="\t") %>% rename(iso_code=wals.code)
#Matthew S. Dryer. 2013. Order of Subject, Object and Verb.
#In: Dryer, Matthew S. & Haspelmath, Martin (eds.)
#The World Atlas of Language Structures Online.
#Leipzig: Max Planck Institute for Evolutionary Anthropology.
#(Available online at http://wals.info/chapter/81, Accessed on 2020-09-12.)

u = merge(u, wals, by=c("iso_code"), all.x=TRUE)

library(stringr)
u$Language2 = as.character(u$Language)
for(i in (1:nrow(u))) {
        u$Language2[[i]] = str_replace(u$Language2[[i]], "_2.6", "")
        u$Language2[[i]] = str_replace(u$Language2[[i]], "_", " ")
}



library(ggrepel)
library(ggplot2)
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=description)) + geom_text_repel(aes(label=Language2)) + xlab("Attested Subject-Object Symmetry") + ylab("Optimized Subject-Object Symmetry") + theme_bw() + theme(axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())
ggsave(plot, file="figures/by_categorical_order.pdf")

v = u %>% filter(description == "SVO")
sink("output/corr_SVO.txt")
print(cor.test(v$OSSameSide_Real_Prob, v$OSSameSide))
sink()

v = u %>% filter(description == "SOV")
sink("output/corr_SOV.txt")
print(cor.test(v$OSSameSide_Real_Prob, v$OSSameSide))
sink()

#summary(glmer(SOV_VSO ~ OSSameSide + (1|Family), family="binomial", data=u %>% filter(SameSideWALS != 0)))


#
#u$SOV_VSO = (u$description == "SOV" | u$description == "VSO")
#u$free = u$description == "No dominant order"
#u$SVO = u$description == "SVO"
#
#u$SameSideWALS = ifelse(u$SOV_VSO, 1, ifelse(u$SVO, -1, 0))
#
#
#u %>% group_by(description) %>% summarise(OSSameSide=mean(OSSameSide))
