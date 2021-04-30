
library(ggplot2)

corrs = read.csv("CORR_Omega_51Emodel.py.txt", header=FALSE)


plot = ggplot(corrs) + geom_histogram(aes(x=V1)) + xlab("Correlation between Dimensions") + theme_bw() + ylab("Posterior Samples") + xlim(-1,1)
ggsave(plot, file="corr_omega.pdf", height=2, width=4)


sink("correlation_omega.txt")
cat("Mean: ", mean(corrs$V1))
cat("\n")
cat("95% CrI ", quantile(corrs$V1, 0.025), " ",  quantile(corrs$V1, 1-0.025))
cat("\n")
cat("Posterior of opposite sign: ", mean(corrs$V1<0))
sink()
