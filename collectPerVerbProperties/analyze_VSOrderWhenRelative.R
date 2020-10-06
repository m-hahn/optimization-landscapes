library(tidyr)
library(dplyr)
data = read.csv("outputs/VSOrderWhenRelative.py.tsv", sep="\t")
language = "French_2.6"
sink("results_analyze_VSOrderWhenRelative.R.tex")
for(language in data$Language) {
   u = data %>% filter(Language==language)
   v = data.frame(SV = c(TRUE, TRUE, FALSE, FALSE), Relative = c("Relative", "Root"), Frequency = as.numeric(u[2:5]))
   model = summary(glm(SV ~ Relative, weights=Frequency, data=v, family="binomial"))
   if(nrow(model$coefficients)>1) {
      cat(language, " & ", sum(u[2:3])/sum(u[2:5]), " & ", model$coefficients[2,1], " & ", model$coefficients[2,4], "\\\\ \n")
   }
}
sink()
