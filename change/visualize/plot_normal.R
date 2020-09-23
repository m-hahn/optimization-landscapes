library(MASS)
mvrnorm(n=10, mu=c(0,0), Sigma=c(0.36, 0.1, 0.1, 0.07))
sigma=c(0.36, 0.1, 0.1, 0.07)
dim(sigma)=c(2,2)
sigma
mvrnorm(n=10, mu=c(0,0), Sigma=csigma)
mvrnorm(n=10, mu=c(0,0), Sigma=sigma)
mvrnorm(n=100, mu=c(0,0), Sigma=sigma)
data = mvrnorm(n=100, mu=c(0,0), Sigma=sigma)
plot(data[,1], data[,2])
plot(data[,2], data[,1])
data = mvrnorm(n=1000, mu=c(0,0), Sigma=sigma)
plot(data[,2], data[,1])
plot(data[,2]+0.45, 1/(1+exp(-data[,1]+0.12)))


library(ggplot2)
plot = ggplot(data.frame(Real = data[,2]+0.45, Model = 1/(1+exp(-data[,1]+0.12))), aes(x=Real, y=Model)) + geom_density2d() + xlim(0,1) + ylim(0,1)



mu = c(0.12, 0.45)

B = c(1, 0.3, 0.3, 1)
dim(B) = c(2,2)

Lambda = c(1, 0.3, 0.3, 1)
dim(Lambda) = c(2,2)

variance = B %*% Lambda + Lambda %*% t(B)


start1 = c(0.25, 0.25)
start2 = c(0.5, 0.85)

infinitesimal1 = mvrnorm(n=100, mu=start1+0.01*(B %*% (start1-mu)), Sigma=(0.01^2)*variance)
infinitesimal2 = mvrnorm(n=100, mu=start2+0.01*(B %*% (start2-mu)), Sigma=(0.01^2)*variance)


sigmoid = function(x) {
	return(1/(1+exp(-x)))
}

plot = ggplot(data.frame(Real = data[,2]+0.45, Model = 1/(1+exp(-data[,1]+0.12))), aes(x=Real, y=Model)) + geom_density2d() + xlim(0,1) + ylim(0,1)
plot = plot + geom_point(data=data.frame(Real = infinitesimal1[,2], Model = 1/(1+exp(-infinitesimal1[,1]))), aes(x=Real, y=Model), color="red")
#plot = plot + geom_point(data=data.frame(Real = infinitesimal2[,2], Model = 1/(1+exp(-infinitesimal2[,1]))), aes(x=Real, y=Model), color="red")
plot = plot + geom_point(data=data.frame(Real = c(start1[1]), Model = sigmoid(c(start1[2]))), aes(x=Real, y=Model), color="black")
#plot = plot + geom_point(data=data.frame(Real = c(start2[1]), Model = sigmoid(c(start2[2]))), aes(x=Real, y=Model), color="black")
ggsave(plot, file="stationary.pdf")



