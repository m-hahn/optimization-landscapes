library(tidyr)
library(dplyr)
data = read.csv("outputs/VSOrderWhenNoObject.py.tsv", sep="\t")
language = "French_2.6"
sink("results_analyze_VSOrderWhenNoObject.R.tex")
for(language in data$Language) {
   u = data %>% filter(Language==language)
   model = summary(glm(SV ~ Object, weights=Frequency, data=data.frame(SV = c(TRUE, TRUE, FALSE, FALSE), Object = c(FALSE, TRUE, FALSE, TRUE), Frequency = as.numeric(u[2:5])), family="binomial"))
   cat(language, " & ", sum(u[2:3])/sum(u[2:4]), " & ", model$coefficients[2,1], " & ", model$coefficients[2,4], "\\\\ \n")
}
sink()
