library(ggplot2)


corrs = read.csv("ornuhl-binom/fits/CORR_Sigma_Case_45model.py.txt", header=FALSE)
plot = ggplot(corrs) + geom_histogram(aes(x=V1)) + xlab("Correlation between Dimensions") + theme_bw() + ylab("Posterior Samples") + xlim(-1, 1)
ggsave(plot, file="figures/corr_ornuhl-binom_45_Case.pdf", height=2, width=4)

corrs = read.csv("ornuhl-binom/fits/CORR_Sigma_NoCase_45model.py.txt", header=FALSE)
plot = ggplot(corrs) + geom_histogram(aes(x=V1)) + xlab("Correlation between Dimensions") + theme_bw() + ylab("Posterior Samples") + xlim(-1, 1)
ggsave(plot, file="figures/corr_ornuhl-binom_45_NoCase.pdf", height=2, width=4)


