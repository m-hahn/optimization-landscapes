library(tidyr)
library(dplyr)

spoken = read.csv("spoken.tsv", sep="\t")

library(ggplot2)

library(ggrepel)
spoken2 = rbind(spoken %>% select(Language, OSSameSide_Real_Prob, OSSameSide) %>% mutate(Group="Spoken"), spoken %>% select(Language, OSSameSide_Real_Prob, OSSameSide_Other) %>% rename(OSSameSide=OSSameSide_Other) %>% mutate(Group="Written") %>% filter(Language != "Naija"))
plot = ggplot(spoken2, aes(x=OSSameSide_Real_Prob, y=OSSameSide)) +geom_text_repel(aes(label=Language, y=OSSameSide, color=Group), size=6) + xlim(0,1) + ylim(0,1) + xlab("Attested Subject-Object Position Congruence") + ylab("Optimized Subject-Object Position Congruence")+ theme_bw() + theme(legend.position="bottom", axis.text=element_text(size=12), axis.title=element_text(size=15)) + theme(panel.grid = element_blank())
ggsave(plot, file="spoken.pdf", width=7, height=7)

sink("spoken_results.txt")
cat("SPOKEN ONLY:\n")
print(cor.test(spoken$OSSameSide, spoken$OSSameSide_Real_Prob))
cat("\nCORPORA FROM MAIN EXPERIMENT\n")
print(cor.test(spoken$OSSameSide_Other, spoken$OSSameSide_Real_Prob))
sink()

#
#summary(lm(OSSameSide ~ OSSameSide_Real_Prob, data=spoken))
#
#summary(lm(OSSameSide_Real_Prob ~ OSSameSide, data=spoken))
#
#library(brms)
#model = brm(OSSameSide_Real_Prob ~ OSSameSide, data=spoken)
#
#spoken2 = spoken[spoken$Language != "English",]
#model = brm(OSSameSide_Real_Prob ~ OSSameSide, data=spoken2)
#spoken2 = spoken[spoken$Language != "Norwegian",]
#model = brm(OSSameSide_Real_Prob ~ OSSameSide, data=spoken2)
#
##summary(brm(OSSameSide_Real_Prob ~ OSSameSide + (1+OSSameSide|Family), data=spoken, iter=20000, prior=prior("normal(0,1)", class="b")))
## doesn't converge
