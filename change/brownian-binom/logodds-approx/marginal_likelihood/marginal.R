data = read.csv("33model.py.txt", sep=" ")
names(data) <- c("Years", "foo", "LogLikelihood")
library(tidyr)
library(dplyr)

sink("results.txt")
print(data %>% group_by(Years) %>% summarise(LogLikelihood = log(mean(exp(LogLikelihood-max(LogLikelihood)))) + max(LogLikelihood)))
sink()

