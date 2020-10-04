library(tidyr)
library(dplyr)
data = read.csv("outputs/VSOrderWhenEmbedded.py.tsv", sep="\t")
language = "French_2.6"
sink("results_analyze_VSOrderWhenEmbedded.R.tex")
for(language in data$Language) {
   u = data %>% filter(Language==language)
   v = data.frame(SV = c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE), Head = c("L", "R", "root", "L", "R", "root"), Frequency = as.numeric(u[2:7]))
   model = summary(glm(SV ~ Unembedded, weights=Frequency, data=v %>% mutate(Unembedded = (Head == "root")), family="binomial"))
   cat(language, " & ", sum(u[2:4])/sum(u[2:7]), " & ", model$coefficients[2,1], " & ", model$coefficients[2,4], "\\\\ \n")
}
sink()
