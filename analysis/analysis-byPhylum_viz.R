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


library(ggplot2)
# Plot the residuals by phylum
genera = c("Afro_Asiatic", "Indo_European", "Niger-Congo", "Sino-Tibetan", "Turkic", "Uralic")
plot = ggplot(v %>% filter(Genus %in% genera), aes(x=OSSameSide_Real_Prob, y=OSSameSide, group=Language, color=Family)) + geom_text(aes(label=Language)) + facet_wrap(~Genus) + xlab("Attested") + ylab("Optimized")
ggsave("figures-scratch/byPhylum.pdf", width=20, height=10)
plot = ggplot(v %>% filter(Genus %in% genera), aes(x=Resid)) + geom_histogram() + facet_wrap(~Genus)
ggsave("figures-scratch/byPhylum-residuals.pdf", width=20, height=10)

library(ggrepel)
plot = ggplot(v %>% group_by(Genus) %>% summarise(OSSameSide_Real_Prob=mean(OSSameSide_Real_Prob), OSSameSide=mean(OSSameSide)), aes(x=OSSameSide_Real_Prob, y=OSSameSide, color=Genus)) + geom_text_repel(aes(label=Genus)) + xlab("Attested") + ylab("Optimized")
ggsave("figures-scratch/per-phylum-means.pdf", width=20, height=10)


model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Genus), data=v)
samp = posterior_samples(model)


#hist(samp$b_OSSameSide_Real_Prob + samp[["r_Genus[Niger-Congo,OSSameSide_Real_Prob]"]])

# Posteriors:
genera = c("Afro_Asiatic", "Indo_European", "Niger-Congo", "Sino-Tibetan", "Turkic", "Uralic")
slopes = data.frame(Genus=c(), Coefficient=c())
for(genus in genera) {
	coeffs = samp$b_OSSameSide_Real_Prob + samp[[paste("r_Genus[", genus, ",OSSameSide_Real_Prob]", sep="")]]
	slopes2 = data.frame(Coefficient=coeffs)
	slopes2$Genus=genus
	slopes=rbind(slopes, slopes2)
}

# Posterior over the slope by language family (excluding those with just one represented member)
library(ggplot2)
plot = ggplot(slopes, aes(x=Coefficient, group=Genus, color=Genus)) + geom_density()
ggsave("figures-scratch/per-phylum-posteriors.pdf", width=20, height=10)



# Plot by genus
library(ggplot2)
plot = ggplot(v %>% filter(Genus == "Indo_European"), aes(x=OSSameSide_Real_Prob, y=OSSameSide, group=Language, color=Family)) + geom_text(aes(label=Language)) + facet_wrap(~Genus)
ggsave("figures-scratch/within-IE.pdf", width=10, height=10)

