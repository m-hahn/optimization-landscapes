library(tidyr)
library(dplyr)

embedding = read.csv("../../collectPerVerbProperties/outputs/embedding5.py.tsv", sep="\t")

families = read.csv("../families.tsv", sep="\t")
data = families


u = data
#print(u[order(u$OSSameSide),], n=60)

sigmoid = function(x) {
	return(1/(1+exp(-x)))
}

real = read.csv("../mle-fine_selected_auto-summary-lstm_2.6.tsv", sep="\t")
realO = real %>% filter(Dependency == "obj")
realS = real %>% filter(Dependency == "nsubj")

real = merge(realO, realS, by=c("Language", "FileName", "ModelName"))

real = real %>% mutate(OFartherThanS_Real = (Distance_Mean_NoPunct.x > Distance_Mean_NoPunct.y))
real = real %>% mutate(OSSameSide_Real = (sign(DH_Mean_NoPunct.x) == sign(DH_Mean_NoPunct.y)))
real = real %>% mutate(OSSameSide_Real_Prob = (sigmoid(DH_Mean_NoPunct.x) * sigmoid(DH_Mean_NoPunct.y)) + ((1-sigmoid(DH_Mean_NoPunct.x)) * (1-sigmoid(DH_Mean_NoPunct.y))))

isPositive = function(x) {
	return(1*(x>0))
}

real = real %>% mutate(OSSameSide_Real_SemiProb = (sigmoid(DH_Mean_NoPunct.y) * isPositive(DH_Mean_NoPunct.x)) + ((1-sigmoid(DH_Mean_NoPunct.y)) * (1-isPositive(DH_Mean_NoPunct.x))))

real = real %>% mutate(Order_Real = ifelse(OSSameSide_Real & OFartherThanS_Real, "VSO", ifelse(OSSameSide_Real, "SOV", "SVO")))

u = merge(u, real %>% select(Language, OSSameSide_Real, OSSameSide_Real_Prob, OSSameSide_Real_SemiProb), by=c("Language"))



u = merge(u, embedding, by=c("Language"), all=TRUE)

u$Coexpression = (u$Yes/(u$Yes+u$No))


embedding = read.csv("../../collectPerVerbProperties/outputs/embedding.py.tsv", sep="\t") %>% mutate(Embedded = Yes/(Yes+No))

u = merge(u, embedding, by=c("Language"), all=TRUE)


library(lme4)


print(summary(lmer(OSSameSide_Real_Prob ~ Coexpression + Embedded + (1|Family), data=u)))


print(summary(lmer(Coexpression ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family), data=u)))
library(brms)
model = ((brm(Coexpression ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Family), data=u)))

samples = posterior_samples(model)

sink("embedding_results.txt")
print(cor.test(u$Coexpression, u$OSSameSide_Real_Prob))
cat("\n")
cat("Beta ", mean(samples$b_OSSameSide_Real_Prob), "\n")
cat("SD ",sd(samples$b_OSSameSide_Real_Prob), "\n")
cat("95% CrI [",quantile(samples$b_OSSameSide_Real_Prob, 0.025), " ", quantile(samples$b_OSSameSide_Real_Prob, 1-0.025), "]\n")
cat("P(beta) > 0 ", mean(samples$b_OSSameSide_Real_Prob > 0), "\n")
sink()




library(ggplot2)

library(stringr)
u$Language2 = as.character(u$Language)
for(i in (1:nrow(u))) {
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_2.6", "")
	u$Language2[[i]] = str_replace(u$Language2[[i]], "_", " ")
}


library(ggrepel)
library(ggplot2)
plot = ggplot(u, aes(x=OSSameSide_Real_Prob, y=Coexpression, color=Family)) + geom_text_repel(aes(label=Language2)) + xlab("Attested Subject-Object Symmetry") + ylab("Coexpressed Subjects and Objects") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())
ggsave("../figures/objects-order-pureud-byVerb_FORMAT.pdf", width=7, height=7)


write.csv(u, file="landscapes_2.6_Properties_IncludingNonNouns_All_VIZ.R.csv")


v = read.csv("../landscapes_2.6_new.R.tsv", sep=" ")


v = merge(u, v, by=c("Language", "Family"))


plot = ggplot(v, aes(x=OSSameSide, y=Coexpression, color=Family)) + geom_text_repel(aes(label=Language2)) + xlab("Optimized Subject-Object Symmetry") + ylab("Coexpressed Subjects and Objects") + theme_bw() + theme(legend.position="none", axis.text=element_text(size=14), axis.title=element_text(size=16)) + theme(panel.grid = element_blank())
ggsave("../figures/objects-order-pureud-byVerb_optimized_FORMAT.pdf", width=7, height=7)


model = ((brm(Coexpression ~ OSSameSide + (1+OSSameSide|Family), data=v)))


samples = posterior_samples(model)

sink("embedding_optim_results.txt")
print(cor.test(v$Coexpression, v$OSSameSide))
cat("\n")
cat("Beta ", mean(samples$b_OSSameSide), "\n")
cat("SD ",sd(samples$b_OSSameSide), "\n")
cat("95% CrI [",quantile(samples$b_OSSameSide, 0.025), " ", quantile(samples$b_OSSameSide, 1-0.025), "]\n")
cat("P(beta) > 0 ", mean(samples$b_OSSameSide > 0), "\n")
sink()




