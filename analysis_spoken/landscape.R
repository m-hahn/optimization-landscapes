library(tidyr)
library(dplyr)

spoken = read.csv("spoken.tsv", sep="\t")

library(ggplot2)

plot = ggplot(spoken, aes(x=OSSameSide_Real_Prob, y=OSSameSide)) +geom_label(aes(label=Language, y=OSSameSide_Other), color="gray", linetype=2) + geom_label(aes(label=Language, y=OSSameSide)) + xlim(0,1) + ylim(0,1) + xlab("Real") + ylab("Predicted")
ggsave(plot, file="spoken.pdf")

summary(lm(OSSameSide_Real_Prob ~ OSSameSide, data=spoken))

library(brms)
model = brm(OSSameSide_Real_Prob ~ OSSameSide, data=spoken)

spoken2 = spoken[spoken$Language != "English",]
model = brm(OSSameSide_Real_Prob ~ OSSameSide, data=spoken2)
spoken2 = spoken[spoken$Language != "Norwegian",]
model = brm(OSSameSide_Real_Prob ~ OSSameSide, data=spoken2)

#summary(brm(OSSameSide_Real_Prob ~ OSSameSide + (1+OSSameSide|Family), data=spoken, iter=20000, prior=prior("normal(0,1)", class="b")))
# doesn't converge
