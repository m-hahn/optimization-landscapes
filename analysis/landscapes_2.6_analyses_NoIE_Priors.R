library(tidyr)
library(dplyr)


u = read.table("landscapes_2.6_new.R.tsv")
real = read.table("landscapes_2.6_new_real.R.tsv")
data = read.table("landscapes_2.6_new_data.R.tsv")

genera = read.csv("genera.tsv", sep="\t")
u = merge(u, genera, by=c("Language", "Family"), all.x=TRUE)

library(brms)

data = merge(data, real, by=c("Language"))
data = merge(data, genera, by=c("Language", "Family"))

data$OSSameSide_Real_Prob_Log = log(data$OSSameSide_Real_Prob)


#########################
#########################
library(brms)
library(ggplot2)


v = data %>% group_by(Language, Family, Genus, OSSameSide_Real_Prob) %>% summarise(OSSameSide=mean(OSSameSide, na.rm=TRUE))


v$OSSameSide_Real_Prob.C = v$OSSameSide_Real_Prob - mean(v$OSSameSide_Real_Prob, na.rm=TRUE)

# Different priors
#model = brm(OSSameSide ~ OSSameSide_Real_Prob + (1+OSSameSide_Real_Prob|Genus), data=v)
#> prior_summary(model)
#                    prior     class                 coef  group resp dpar nlpar
#1                                 b                                            
#2                                 b OSSameSide_Real_Prob                       
#3  student_t(3, 0.5, 2.5) Intercept                                            
#4    lkj_corr_cholesky(1)         L                                            
#5                                 L                      Family                
#6                                 L                       Genus                
#7    student_t(3, 0, 2.5)        sd                                            
#8                                sd                      Family                
#9                                sd            Intercept Family                
#10                               sd OSSameSide_Real_Prob Family                
#11                               sd                       Genus                
#12                               sd            Intercept  Genus                
#13                               sd OSSameSide_Real_Prob  Genus                
#14   student_t(3, 0, 2.5)     sigma                                 



visualize = function(model1, prior_name) {
    samples = posterior_samples(model1)
    
    plot = ggplot(samples, aes(x=b_OSSameSide_Real_Prob.C)) + geom_histogram() + theme_bw() + theme(panel.grid = element_blank()) + xlim(-0.3, 1) + geom_segment(aes(x=c(0), y=c(0), xend=c(0), yend=c(1)), linetype=2) + xlab("Slope") + ylab("Posterior Samples")
    ggsave(plot, file=paste("posteriors-across-priors/", prior_name, "-beta.pdf", sep=""), height=2, width=4)
    
    plot = ggplot(samples, aes(x=sd_Genus__OSSameSide_Real_Prob.C)) + geom_histogram() + theme_bw() + theme(panel.grid = element_blank()) + xlim(0.0, 1) + geom_segment(aes(x=c(0), y=c(0), xend=c(0), yend=c(1)), linetype=2) + xlab("Slope Variance across Phyla") + ylab("Posterior Samples")
    ggsave(plot, file=paste("posteriors-across-priors/", prior_name, "-across-phyla-variance.pdf", sep=""), height=2, width=4)
    
    plot = ggplot(samples, aes(x=sigma)) + geom_histogram() + theme_bw() + theme(panel.grid = element_blank()) + xlim(0.0, 0.3) + geom_segment(aes(x=c(0), y=c(0), xend=c(0), yend=c(1)), linetype=2) + xlab("Response Variance") + ylab("Posterior Samples")
    ggsave(plot, file=paste("posteriors-across-priors/", prior_name, "-response-variance.pdf", sep=""), height=2, width=4)
}

#This is the model as we have it
model1 = brm(OSSameSide ~ OSSameSide_Real_Prob.C + (1+OSSameSide_Real_Prob.C|Genus), data=v, prior=c(set_prior("student_t(3, 0, 2.5)", class="sd"), set_prior("student_t(3, 0, 2.5)", class="sigma")))
visualize(model1, "student_3_0_25_uniform")

model1 = brm(OSSameSide ~ OSSameSide_Real_Prob.C + (1+OSSameSide_Real_Prob.C|Genus), data=v, prior=c(set_prior("student_t(3, 0, 2.5)", class="sd"), set_prior("student_t(3, 0, 2.5)", class="sigma"), set_prior("student_t(3, 0, 2.5)", class="b")))
visualize(model1, "student_3_0_25")

model = brm(OSSameSide ~ OSSameSide_Real_Prob.C + (1+OSSameSide_Real_Prob.C|Genus), data=v, prior=c(set_prior("student_t(3, 0, 0.5)", class="sd"), set_prior("student_t(3, 0, 0.5)", class="sigma"), set_prior("student_t(3, 0, 0.5)", class="b")))
visualize(model, "student_3_0_05")
#                     Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                0.30      0.06     0.18     0.43 1.00     1924
#OSSameSide_Real_Prob.C     0.41      0.12     0.18     0.66 1.00     1635

model = brm(OSSameSide ~ OSSameSide_Real_Prob.C + (1+OSSameSide_Real_Prob.C|Genus), data=v, prior=c(set_prior("student_t(3, 0, 10)", class="sd"), set_prior("student_t(3, 0, 10)", class="sigma"), set_prior("student_t(3, 0, 10)", class="b")))
visualize(model, "student_3_0_10")
#                     Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                0.30      0.07     0.17     0.44 1.00     2714
#OSSameSide_Real_Prob.C     0.42      0.13     0.16     0.68 1.00     2307

model = brm(OSSameSide ~ OSSameSide_Real_Prob.C + (1+OSSameSide_Real_Prob.C|Genus), data=v, prior=c(set_prior("student_t(3, 0, 0.1)", class="sd"), set_prior("student_t(3, 0, 0.1)", class="sigma"), set_prior("student_t(3, 0, 0.1)", class="b")))
visualize(model, "student_3_0_01")
#                     Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS
#Intercept                0.30      0.06     0.19     0.42 1.00     3370
#OSSameSide_Real_Prob.C     0.41      0.10     0.20     0.61 1.00     2986


model = brm(OSSameSide ~ OSSameSide_Real_Prob.C + (1+OSSameSide_Real_Prob.C|Genus), data=v, prior=c(set_prior("normal(0,1)", class="sd"), set_prior("normal(0,1)", class="sigma"), set_prior("normal(0,1)", class="b")))
visualize(model, "normal_0_1")






