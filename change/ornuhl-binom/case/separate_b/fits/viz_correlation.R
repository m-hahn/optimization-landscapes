

corrs = read.csv("CORR_Sigma_44model.py.txt", header=FALSE)

library(ggplot2)

plot = ggplot(corrs) + geom_histogram(aes(x=V1)) + xlab("Correlation between Dimensions") + theme_bw() + ylab("Posterior Samples") + xlim(-1,1)
ggsave(plot, file="corr_sigma.pdf", height=2, width=4)



sink("correlation_sigma.txt")
cat("Mean: ", mean(corrs$V1))
cat("\n")
cat("95% CrI ", quantile(corrs$V1, 0.025), " ",  quantile(corrs$V1, 1-0.025))
cat("\n")
cat("Posterior of opposite sign: ", mean(corrs$V1<0))
sink()



sigmoid = function(x) {
        return(1/(1+exp(-x)))
}
stationary = read.csv("stationary_fit_44model.py.txt", sep=" ")

library(MASS)

# Stationary Variance
data = data.frame(Group=c(), X=c(), Y=c())

for(i in 1:2) {
   omega=c(stationary$Cov11[[i]], stationary$Cov12[[i]], stationary$Cov12[[i]], stationary$Cov22[[i]])
   dim(omega)=c(2,2)
   
   # Stationary Mean
   mu = c(stationary$Mean1[[i]], stationary$Mean2[[i]])
   dataCase = mvrnorm(n=2000, mu=mu, Sigma=omega)
   dataGroup = data.frame(X=dataCase[,1], Y=dataCase[,2])
   dataGroup$Group=stationary$Group[[i]]
   data = rbind(data, dataGroup)
}

data$Y = (data$Y+1)/2
data$X = sigmoid(data$X)

library(ggplot2)

logit = function(x) {
   return(log(x/(1-x)))
}

library(tidyr)
library(dplyr)
plot = ggplot(data, aes(x=Y, y=X, group=Group, color=Group)) + geom_density2d() + xlim(0,1) + ylim(0,1)
plot = plot + theme_bw()
plot = plot + theme(axis.text=element_text(size=7))
plot = plot + xlab("Real Subject-Object Position Congruence")
plot = plot + ylab("Optimal Subject-Object-Position Congruence")
ggsave(plot, file="stationary_case.pdf", height=4, width=4)


