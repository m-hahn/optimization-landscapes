library(tidyr)
library(dplyr)


u = read.table("landscapes_2.6_new.R.tsv")
real = read.table("landscapes_2.6_new_real.R.tsv")
data = read.table("landscapes_2.6_new_data.R.tsv")

genera = read.csv("genera.tsv", sep="\t")
u = merge(u, genera, by=c("Language", "Family"), all.x=TRUE)

library(brms)

data = merge(data, real, by=c("Language"))
data = merge(data, genera, by=c("Language", "Family"))

data$OSSameSide_Real_Prob_Log = log(data$OSSameSide_Real_Prob)


#########################
#########################
library(brms)

v = data %>% group_by(Language, Family, Genus, OSSameSide_Real_Prob) %>% summarise(OSSameSide=mean(OSSameSide, na.rm=TRUE))


library(lme4)
model_lme4 = lmer(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Genus), data=v)


residuals = resid(model_lme4)
v$Resid = residuals


library(stringr)
v$Language2 = str_replace(v$Language, "_2.6", "")
v$Language2 = str_replace(v$Language2, "_", " ")

library(ggplot2)
library(ggrepel)
# Plot the residuals by phylum
genera = c("Afro_Asiatic", "Indo_European", "Niger-Congo", "Sino-Tibetan", "Turkic", "Uralic")
#plot = ggplot(v %>% filter(Genus %in% genera), aes(x=OSSameSide_Real_Prob, y=OSSameSide, group=Language2, color=Family)) + geom_text_repel(aes(label=Language2)) + facet_wrap(~Genus) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + geom_segment(aes(x=c(0), y=c(0.31168), xend=c(1), yend=c(0.31168+0.40962)),color="black") + theme_bw()
plot = ggplot(v %>% filter(Genus %in% genera), aes(x=OSSameSide_Real_Prob, y=OSSameSide, group=Language2)) + geom_point() + facet_wrap(~Genus) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + geom_segment(aes(x=c(0), y=c(0.31168), xend=c(1), yend=c(0.31168+0.40962)),color="black") + theme_bw()
ggsave("figures-scratch/byPhylum.pdf", width=7, height=4)

#plot = ggplot(v %>% filter(Genus %in% genera), aes(x=OSSameSide_Real_Prob, y=OSSameSide, group=Language2, color=Family)) + geom_text_repel(aes(label=Language2)) + facet_wrap(~Genus) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + geom_segment(aes(x=c(0), y=c(0.31168), xend=c(1), yend=c(0.31168+0.40962)),color="black") + theme_bw()
plot = ggplot(v, aes(x=OSSameSide_Real_Prob, y=OSSameSide, group=Language2)) + geom_point() + facet_wrap(~Genus) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + geom_segment(aes(x=c(0), y=c(0.31168), xend=c(1), yend=c(0.31168+0.40962)),color="black") + theme_bw()
ggsave("figures-scratch/byPhylum_all.pdf", width=7, height=4)


w = coef(model_lme4)$Genus
w$Genus = rownames(w)
w = w %>% rename(Slope = OSSameSide_Real_Prob)
v = merge(v, w %>% select(Genus, Slope), by=c("Genus"))
plot = ggplot(v, aes(x=OSSameSide_Real_Prob, y=OSSameSide, group=Language2)) + geom_point() + facet_wrap(~Genus) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + geom_segment(aes(x=c(0), y=c(0.31168), xend=c(1), yend=c(0.31168+Slope)),color="black") + geom_segment(aes(x=c(0), y=c(0.31168), xend=c(1), yend=c(0.31168+0.40962)),color="gray", linetype=2) + theme_bw()
ggsave("figures-scratch/byPhylum_all_slopes.pdf", width=7, height=7)






# Plot by genus
library(ggplot2)
plot = ggplot(v %>% filter(Genus == "Indo_European"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, group=Language, color=Family)) + geom_text_repel(aes(label=Language2)) + theme_bw() + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence")  + theme(legend.position="none")  + theme(panel.grid = element_blank())
ggsave("figures-scratch/within-IE.pdf", width=7, height=7)


plot = ggplot(v %>% filter(Genus %in% genera), aes(x=Resid)) + geom_histogram() + facet_wrap(~Genus)
ggsave("figures-scratch/byPhylum-residuals.pdf", width=20, height=10)

library(ggrepel)
plot = ggplot(v %>% group_by(Genus) %>% summarise(OSSameSide_Real_Prob=mean(OSSameSide_Real_Prob), OSSameSide=mean(OSSameSide)), aes(x=OSSameSide_Real_Prob, y=OSSameSide)) + geom_text_repel(aes(label=Genus)) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence") + theme_bw()
ggsave("figures-scratch/per-phylum-means.pdf", width=5, height=5)

v$OSSameSide_Real_Prob.C = v$OSSameSide_Real_Prob - mean(v$OSSameSide_Real_Prob, na.rm=TRUE)
model = brm(OSSameSide ~ OSSameSide_Real_Prob.C + (1+OSSameSide_Real_Prob.C|Genus), data=v)
#                       Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                  0.48      0.04     0.40     0.56 1.00     2025
#OSSameSide_Real_Prob.C     0.41      0.13     0.16     0.68 1.00     2523

samp = posterior_samples(model)


#hist(samp$b_OSSameSide_Real_Prob + samp[["r_Genus[Niger-Congo,OSSameSide_Real_Prob]"]])

# Posteriors:
genera = c("Afro_Asiatic", "Indo_European", "Niger-Congo", "Sino-Tibetan", "Turkic", "Uralic")
slopes = data.frame(Genus=c(), Coefficient=c())
for(genus in genera) {
	coeffs = samp$b_OSSameSide_Real_Prob.C + samp[[paste("r_Genus[", genus, ",OSSameSide_Real_Prob.C]", sep="")]]
	slopes2 = data.frame(Coefficient=coeffs)
	slopes2$Genus=genus
	slopes=rbind(slopes, slopes2)
}

# Posterior over the slope by language family (excluding those with just one represented member)
library(ggplot2)
plot = ggplot(slopes, aes(x=Coefficient, group=Genus, color=Genus)) + geom_density(aes(y=..scaled..)) + theme_bw() + xlab("Coefficient in Mixed-Effects Regression") + ylab("Posterior Density") + geom_segment(aes(x=c(0), y=c(0), xend=c(0), yend=c(1), group=NULL, color=NULL), color="black", linetype=2)
ggsave("figures-scratch/per-phylum-posteriors.pdf", width=7, height=5)

plot = ggplot(slopes, aes(x=Coefficient, group=Genus, color=Genus)) + geom_density(aes(y=..scaled..)) + theme_bw() + xlab("Coefficient in Mixed-Effects Regression") + ylab("Posterior Density") + geom_segment(aes(x=c(0), y=c(0), xend=c(0), yend=c(1), group=NULL, color=NULL), color="black", linetype=2)
ggsave("figures-scratch/per-phylum-posteriors-short.pdf", width=7, height=3)


