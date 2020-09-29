library(MASS)

# Instantaneous Fluctuations
sigma=c(1.48, 0.99, 0.99, 0.86)
dim(sigma)=c(2,2)

# Stationary Variance
omega=c(1.00, 0.63, 0.63, 0.52)
dim(omega)=c(2,2)

# Drift vector
drift = c(0.82, 0, 0, 0.89)
dim(drift)=c(2,2)


data = mvrnorm(n=1000, mu=c(0,0), Sigma=omega)


library(ggplot2)
plot = ggplot(data.frame(Real = data[,2], Model = 1/(1+exp(-data[,1]))), aes(x=Real, y=Model)) + geom_density2d() + xlim(0,1) + ylim(0,1)


                                                                                                        
#"20" "English_2.6" "Germanic" 4 15 0.266666666666667 0.866666666666667 FALSE 0.0816786854392221                                                                                     
#"55" "Russian_2.6" "Slavic" 7 15 0.466666666666667 0.8 FALSE 0.355193867478513                 
# "36" "Japanese_2.6" "Japanese" 15 16 0.9375 0.4375 TRUE 0.999464341990614            
logit = function(x) { 
   return(log(x/(1-x)))
}

english = c(logit(4/15), 2*0.0817-1)
russian = c(logit(7/15), 2*0.36-1)
arabic = c(logit(6/15), 2*0.65-1)
japanese = c(logit(15/16), 2*0.99-1)

library(expm)                                                             
#        target += multi_normal_lpdf(own_overall | target_mean_here + exp1 * (reference_overall - target_mean_here), covariance_diagnostic);     
englishMean = 0 + expm(-0.01 * drift) %*% (english-0)
russianMean = 0 + expm(-0.01 * drift) %*% (russian-0)
japaneseMean = 0 + expm(-0.01 * drift) %*% (japanese-0)
arabicMean = 0 + expm(-0.01 * drift) %*% (arabic-0)
change_variance = omega - expm(-0.01 * drift) %*% omega %*% t(expm(-0.01 * drift))


sigmoid = function(x) {
	return(1/(1+exp(-x)))
}

infinitesimal_english = mvrnorm(n=100, mu=englishMean, Sigma=change_variance)
infinitesimal_japanese = mvrnorm(n=100, mu=japaneseMean, Sigma=change_variance)
infinitesimal_russian = mvrnorm(n=100, mu=russianMean, Sigma=change_variance)
infinitesimal_arabic = mvrnorm(n=100, mu=arabicMean, Sigma=change_variance)


data_inf_english = data.frame(Real = (infinitesimal_english[,2]+1)/2, Model = sigmoid(infinitesimal_english[,1]))
data_inf_japanese = data.frame(Real = (infinitesimal_japanese[,2]+1)/2, Model = sigmoid(infinitesimal_japanese[,1]))
data_inf_russian = data.frame(Real = (infinitesimal_russian[,2]+1)/2, Model = sigmoid(infinitesimal_russian[,1]))
data_inf_arabic = data.frame(Real = (infinitesimal_arabic[,2]+1)/2, Model = sigmoid(infinitesimal_arabic[,1]))

plot = ggplot(data.frame(Real = (data[,2]+1)/2, Model = sigmoid(data[,1])), aes(x=Real, y=Model)) + geom_density2d() + xlim(0,1) + ylim(0,1)
plot = plot + geom_density2d(data=data_inf_english, color="red")
#plot = plot + geom_point(data=data.frame(Real = c((english[2]+1)/2), Model = sigmoid(c(english[1]))), aes(x=Real, y=Model), color="black")
plot = plot + geom_density2d(data=data_inf_japanese, color="red")
#plot = plot + geom_point(data=data.frame(Real = c((japanese[2]+1)/2), Model = sigmoid(c(japanese[1]))), aes(x=Real, y=Model), color="black")
plot = plot + geom_density2d(data=data_inf_arabic, color="red")
plot = plot + geom_density2d(data=data_inf_russian, color="red")
data_langs = data.frame(Real = (c(arabic[2], russian[2],english[2], japanese[2])+1)/2, Model = sigmoid(c(arabic[1], russian[1], english[1], japanese[1])), Name = c("Arabic", "Russian", "English", "Japanese"))
plot = plot + geom_point(data=data_langs, aes(x=Real, y=Model), color="black") + geom_text(data=data_langs, aes(x=Real, y=Model, label=Name), nudge_y=-0.08)
plot = plot + xlab("Real Subject-Object Symmetry")
plot = plot + ylab("Optimal Subject-Object-Symmetry")
ggsave(plot, file="stationary.pdf")


# geom_point(data=data_inf_russian, aes(x=Real, y=Model), color="red") + 
# geom_point(data=data_inf_japanese, aes(x=Real, y=Model), color="red") + 
# geom_point(data=data_inf_english, aes(x=Real, y=Model), color="red") + 
