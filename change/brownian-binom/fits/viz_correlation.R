

corrs = read.csv("CORR_Sigma_33model.py_-50000.txt", header=FALSE)

library(ggplot2)

plot = ggplot(corrs) + geom_histogram(aes(x=V1)) + xlab("Correlation between Dimensions") + theme_bw() + ylab("Posterior Samples") + xlim(-1,1)
ggsave(plot, file="corr_sigma.pdf", height=2, width=4)


