library(tidyr)
library(dplyr)
library(ggrepel)
library(ggplot2)
library(stringr)

u = read.csv("landscapes_2.8_new.R.tsv", sep=" ")

uOldEnglish = data.frame(Language=c("Old_English"), Family=c("Germanic"), OSSameSideSum=c(10), OSSameSideTotal=c(13), OSSameSide=c(0.77), OFartherThanS=c(NA), OSSameSide_Real=c(NA), Congruence_VN=c(0.49))
u = rbind(u, uOldEnglish)

u = u %>% mutate(LogOSSameSide = log(OSSameSide+1e-10))
u = u %>% mutate(LogCongruence_VN = log(Congruence_VN+1e-10))

sink("output/correlation.txt")
print(cor.test(u$Congruence_VN, u$OSSameSide))
sink()


u$Language2 = as.character(u$Language)
for(i in (1:nrow(u))) {
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_2.8", "")
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_", " ")
}


plot = ggplot(u, aes(x=Congruence_VN, y=OSSameSide, color=Family)) + geom_text_repel(aes(label=Language2)) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())
ggsave("figures/fracion-optimized_DLM_2.8_format.pdf", height=7, width=7)


plot = ggplot(u, aes(x=Congruence_All, y=OSSameSide, color=Family)) + geom_text_repel(aes(label=Language2)) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())


families = read.csv("genera_2.8.tsv", sep="\t")

u = merge(u, families, by=c("Language"), all.x=TRUE)
u$Family = u$Family.x

library(brms)

model = brm(OSSameSide ~ Congruence_VN + (1+Congruence_VN|Family) + (1+Congruence_VN|Genus), data=u)

