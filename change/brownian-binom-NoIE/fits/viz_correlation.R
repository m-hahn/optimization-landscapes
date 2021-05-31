

corrs = read.csv("CORR_Sigma_33model.py_-20000.txt", header=FALSE)
print(mean(corrs$V1))
print(mean(corrs$V1 <= 0))
corrs = read.csv("CORR_Sigma_33model.py_-50000.txt", header=FALSE)
print(mean(corrs$V1))
print(mean(corrs$V1 <= 0))
corrs = read.csv("CORR_Sigma_33model.py_-100000.txt", header=FALSE)
print(mean(corrs$V1))
print(mean(corrs$V1 <= 0))


library(ggplot2)

plot = ggplot(corrs) + geom_histogram(aes(x=V1)) + xlab("Correlation between Dimensions") + theme_bw() + ylab("Posterior Samples") + xlim(-1,1)
ggsave(plot, file="corr_sigma.pdf", height=2, width=4)


