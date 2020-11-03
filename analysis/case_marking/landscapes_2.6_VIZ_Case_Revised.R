library(tidyr)
library(dplyr)


u = read.csv("../landscapes_2.6_new.R.tsv", sep=" ")


u = merge(u, read.csv("case_marking_revised.tsv", sep=","), by=c("Language"), all=TRUE)



library(stringr)
u$Language2 = as.character(u$Language)
for(i in (1:nrow(u))) {
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_2.6", "")
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_", " ")
}


library(ggrepel)
library(ggplot2)
#ggsave("figures/fracion-optimized_DLM_2.6_format.pdf", height=7, width=7)

u = u %>% mutate(Group = ifelse(value, "Case", "NoCase"))

plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Group)) + geom_text_repel(aes(label=Language2)) + xlab("Real Subject-Object Symmetry") + ylab("Optimal Subject-Object Symmetry") + theme_bw() + theme(axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())
ggsave(plot, file="../figures/by_patient_marking.pdf", width=6, height=6)

v = u %>% filter(Group)
cor.test(v$OSSameSide_Real_Prob, v$OSSameSide)
plot = ggplot(v, aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Group)) + geom_text_repel(aes(label=Language2)) + xlab("Real Subject-Object Symmetry") + ylab("Optimal Subject-Object Symmetry") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())
v = u %>% filter(!Group)
cor.test(v$OSSameSide_Real_Prob, v$OSSameSide)
plot = ggplot(v, aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Group)) + geom_text_repel(aes(label=Language2)) + xlab("Real Subject-Object Symmetry") + ylab("Optimal Subject-Object Symmetry") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())





