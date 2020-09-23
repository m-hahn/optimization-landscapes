library(MASS)
sigma=c(0.45, 0.15, 0.15, 0.09)
dim(sigma)=c(2,2)
data = mvrnorm(n=1000, mu=c(0,0), Sigma=sigma)

library(ggplot2)
plot = ggplot(data.frame(Real = data[,2]+0.43, Model = 1/(1+exp(-data[,1]+0.01))), aes(x=Real, y=Model)) + geom_density2d() + xlim(0,1) + ylim(0,1)



