library(MASS)

# Stationary Variance
omega=c(0.37, 0.11, 0.11, 0.23)
dim(omega)=c(2,2)
#B = 
#
#B_Case[1,1]                         1.58    0.07   1.12   0.16   0.58     1.3   2.48    3.84    271   1.02
#B_Case[2,1]                          0.0     nan    0.0    0.0    0.0     0.0    0.0     0.0    nan    nan
#B_Case[1,2]                          0.0     nan    0.0    0.0    0.0     0.0    0.0     0.0    nan    nan
#B_Case[2,2]                         0.24  3.7e-3    0.1   0.09   0.16    0.22   0.29     0.5    772   1.01
#
#
#
#B_NoCase[1,1]                        1.4    0.05   0.96    0.2   0.64    1.11   1.98    3.67    351   1.02
#B_NoCase[2,1]                        0.0     nan    0.0    0.0    0.0     0.0    0.0     0.0    nan    nan
#B_NoCase[1,2]                        0.0     nan    0.0    0.0    0.0     0.0    0.0     0.0    nan    nan
#B_NoCase[2,2]                       0.28  5.3e-3   0.14   0.09   0.19    0.26   0.35    0.62    689   1.01
#

# Stationary Mean
mu = c(0.28, 0.24)
dataCase = mvrnorm(n=2000, mu=mu, Sigma=omega)


omega=c(0.4, 0.11, 0.11, 0.21)
dim(omega)=c(2,2)
mu=c(-0.7, -0.7)
dataNoCase = mvrnorm(n=2000, mu=mu, Sigma=omega)

dataCase = data.frame(x=(dataCase[,2]+1)/2, y=sigmoid(dataCase[,1]))
dataCase$Group = "Case"
dataNoCase = data.frame(x=(dataNoCase[,2]+1)/2, y=sigmoid(dataNoCase[,1]))
dataNoCase$Group = "No Case"

data = rbind(dataCase, dataNoCase)

library(ggplot2)

logit = function(x) { 
   return(log(x/(1-x)))
}

sigmoid = function(x) {
	return(1/(1+exp(-x)))
}

plot = ggplot(data, aes(x=x, y=y, group=Group, color=Group)) + geom_density2d() + xlim(0,1) + ylim(0,1)
plot = plot + theme_bw()
plot = plot + theme(axis.text=element_text(size=7))
plot = plot + xlab("Real Subject-Object Symmetry")
plot = plot + ylab("Optimal Subject-Object-Symmetry")
ggsave(plot, file="stationary_case.pdf", height=4, width=4)


# geom_point(data=data_inf_russian, aes(x=Real, y=Model), color="red") + 
# geom_point(data=data_inf_japanese, aes(x=Real, y=Model), color="red") + 
# geom_point(data=data_inf_english, aes(x=Real, y=Model), color="red") + 
