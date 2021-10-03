library(tidyr)
library(dplyr)
library(ggrepel)
library(ggplot2)
library(stringr)


#optim = read.csv("~/memsurp-optim/code/optimizeAUC/output/NP_and_basic_28.tsv", sep="\t") %>% group_by(language, basic) %>% summarise(Count=NROW(np)) %>% pivot_wider(names_from=basic, values_from=Count) %>% rename(Language=language)
optim = read.csv("~/memsurp-optim/code/optimizeAUC/output/NP_and_basic.tsv", sep="\t")  %>% rename(Language=language) %>% group_by() %>% mutate(Language=str_replace(Language, "2.7", "2.8")) %>% mutate(Language=str_replace(Language, "2.6", "2.8")) %>% mutate(Language=str_replace(Language, "-GSD", "")) %>% group_by(Language, basic) %>% summarise(Count=NROW(np)) %>% pivot_wider(names_from=basic, values_from=Count) 
optim[is.na(optim$SVO),]$SVO=0
optim[is.na(optim$OSV),]$OSV=0
optim[is.na(optim$SOV),]$SOV=0



u = read.csv("landscapes_noPOS_2.8_new.R.tsv", sep=" ")

u = merge(u, optim, by=c("Language"))

u$AUCOptimizedCongruence = 1-u$SVO/(u$SVO+u$OSV+u$SOV)
#> cor.test(u$Congruence_All, u$AUCOptimizedCongruence)



uOldEnglish = data.frame(Language=c("Old_English"), Family=c("Germanic"), OSSameSideSum=c(10), OSSameSideTotal=c(13), OSSameSide=c(0.77), OFartherThanS=c(NA), OSSameSide_Real=c(NA), Congruence_VN=c(0.49))
u = rbind(u, uOldEnglish)

u = u %>% mutate(LogOSSameSide = log(OSSameSide+1e-10))
u = u %>% mutate(LogCongruence_VN = log(Congruence_VN+1e-10))

sink("output/correlation.txt")
print(cor.test(u$Congruence_All, u$AUCOptimizedCongruence))
print(cor.test(u$Congruence_All, u$OSSameSide))
print(cor.test(u$Congruence_All, u$AUCOptimizedCongruence+u$OSSameSide))
sink()


u$Language2 = as.character(u$Language)
for(i in (1:nrow(u))) {
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_2.8", "")
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_", " ")
}


plot = ggplot(u, aes(x=Congruence_All, y=OSSameSide, color=Family)) + geom_text_repel(aes(label=Language2)) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())
ggsave("figures/coadaptation-noPOS-dlm.pdf", height=7, width=7)
plot = ggplot(u, aes(x=Congruence_All, y=AUCOptimizedCongruence, color=Family)) + geom_text_repel(aes(label=Language2)) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())
ggsave("figures/coadaptation-noPOS-surprisal.pdf", height=7, width=7)
plot = ggplot(u, aes(x=Congruence_All, y=(AUCOptimizedCongruence+OSSameSide)/2, color=Family)) + geom_text_repel(aes(label=Language2)) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())
ggsave("figures/coadaptation-noPOS-joint.pdf", height=7, width=7)


families = read.csv("genera_2.8.tsv", sep="\t")

u = merge(u, families, by=c("Language"), all.x=TRUE)
u$Family = u$Family.x

library(brms)

u$Together = u$AUCOptimizedCongruence + u$OSSameSide

model = brm( Congruence_All~ Together + (1+Together|Family) + (1+Together|Genus), data=u)
samples = posterior_samples(model)
mean(samples$b_Together<0)
#[1] 0.00425


model = brm( Congruence_All~ AUCOptimizedCongruence + (1+AUCOptimizedCongruence|Family) + (1+AUCOptimizedCongruence|Genus), data=u)
samples = posterior_samples(model)
mean(samples$b_AUCOptimizedCongruence<0)
# 0.0435

model = brm( Congruence_All~ OSSameSide + (1+OSSameSide|Family) + (1+OSSameSide|Genus), data=u)
samples = posterior_samples(model)
mean(samples$b_OSSameSide<0)
# 0.01975



model = brm( Congruence_All~ AUCOptimizedCongruence + OSSameSide + (1+AUCOptimizedCongruence+OSSameSide|Family) + (1+AUCOptimizedCongruence+OSSameSide|Genus), data=u)


model = brm(OSSameSide ~ Congruence_All + (1+Congruence_All|Family) + (1+Congruence_All|Genus), data=u)


write.table(u, file="landscapes_NoPOS_2.8_VIZ_AUC.R.tsv")
