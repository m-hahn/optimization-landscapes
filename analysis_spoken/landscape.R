library(tidyr)
library(dplyr)

spoken = read.csv("spoken.tsv", sep="\t")

library(ggplot2)

plot = ggplot(spoken, aes(x=OSSameSide_Real_Prob, y=OSSameSide)) +geom_label(aes(label=Language, y=OSSameSide_Other), color="gray", linetype=2) + geom_label(aes(label=Language, y=OSSameSide)) + xlim(0,1) + ylim(0,1) + xlab("Real") + ylab("Predicted")
ggsave(plot, file="spoken.pdf")


