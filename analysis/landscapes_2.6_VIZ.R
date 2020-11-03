library(tidyr)
library(dplyr)
library(ggrepel)
library(ggplot2)
library(stringr)

u = read.csv("landscapes_2.6_new.R.tsv", sep=" ")


uOldEnglish = data.frame(Language=c("Old_English"), Family=c("Germanic"), OSSameSideSum=c(10), OSSameSideTotal=c(13), OSSameSide=c(0.77), OFartherThanS=c(NA), OSSameSide_Real=c(NA), OSSameSide_Real_Prob=c(0.49))
u = rbind(u, uOldEnglish)

u = u %>% mutate(LogOSSameSide = log(OSSameSide+1e-10))
u = u %>% mutate(LogOSSameSide_Real_Prob = log(OSSameSide_Real_Prob+1e-10))

sink("output/correlation.txt")
print(cor.test(u$OSSameSide_Real_Prob, u$OSSameSide))
sink()


u$Language2 = as.character(u$Language)
for(i in (1:nrow(u))) {
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_2.6", "")
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_", " ")
}


plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Family)) + geom_text_repel(aes(label=Language2)) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())
ggsave("figures/fracion-optimized_DLM_2.6_format.pdf", height=7, width=7)

