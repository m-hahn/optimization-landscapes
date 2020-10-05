

corrs = read.csv("ornuhl-binom/fits/CORR_Sigma_42model.py.txt", header=FALSE)

library(ggplot2)

plot = ggplot(corrs) + geom_histogram(aes(x=V1)) + xlab("Correlation between Dimensions") + theme_bw() + ylab("Posterior Samples") + xlim(-1,1)
ggsave(plot, file="figures/corr_ornuhl-binom_42.pdf", height=2, width=4)


