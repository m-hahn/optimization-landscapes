library(tidyr)
library(dplyr)


u = read.csv("../landscapes_2.6_new.R.tsv", sep=" ")

u = u %>% mutate(LogOSSameSide = log(OSSameSide+1e-10))
u = u %>% mutate(LogOSSameSide_Real_Prob = log(OSSameSide_Real_Prob+1e-10))

data = merge(data, real, by=c("Language"))


data$OSSameSide_Real_Prob_Log = log(data$OSSameSide_Real_Prob)

library(stringr)
u$Language2 = as.character(u$Language)
for(i in (1:nrow(u))) {
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_2.6", "")
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_", " ")
}


library(ggrepel)
library(ggplot2)
#ggsave("figures/fracion-optimized_DLM_2.6_format.pdf", height=7, width=7)


u = merge(u, read.csv("pro_drop.tsv", sep=","), by=c("Language"), all=TRUE)

#write.table(u %>% filter(is.na(value)) %>% select(Language, value), file="pro_drop_others.tsv", sep="\t")


plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=value)) + geom_text_repel(aes(label=Language2)) + xlab("Real Subject-Object Symmetry") + ylab("Optimal Subject-Object Symmetry") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())
ggsave(plot, file="figures/by_prodrop_marking.pdf")

v = u %>% filter(value)
cor.test(v$OSSameSide_Real_Prob, v$OSSameSide)
plot = ggplot(v, aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=value)) + geom_text_repel(aes(label=Language2)) + xlab("Real Subject-Object Symmetry") + ylab("Optimal Subject-Object Symmetry") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())
v = u %>% filter(!value)
cor.test(v$OSSameSide_Real_Prob, v$OSSameSide)
plot = ggplot(v, aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=value)) + geom_text_repel(aes(label=Language2)) + xlab("Real Subject-Object Symmetry") + ylab("Optimal Subject-Object Symmetry") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())





