model1 = read.csv("46model.py.txt", header=FALSE)$V1
model0 = read.csv("47model.py.txt", header=FALSE)$V1

len = min(length(model1), length(model0))

model1 = model1[1:len]
model0 = model0[1:len]


m1max = max(model1)
m0max = max(model0)

likelihood1 = log(mean(exp((model1 - m1max)))) + m1max
likelihood0 = log(mean(exp((model0 - m0max)))) + m0max

likelihoodRatio = exp(likelihood1 - likelihood0)
sink("comparison.txt")
cat("Runs of Stepping Stone Sampling for Model 1 and 0: ")
cat(length(model1))
cat(" ")
cat(length(model0))
cat("\n")
cat("Marginal Likelihood, Model 1", likelihood1, "\n")
cat("Marginal Likelihood, Model 0", likelihood0, "\n")

cat("\nLikelihood Ratio:  ")
cat(likelihoodRatio)
cat("\nStandard error ")
cat(sd(exp(model1-model0))/sqrt(length(model1)))
cat("\nLog Lokelihood Ratio:  ")
cat(likelihood1 - likelihood0)
cat("\nStandard error in log space ")
cat(sd((model1-model0))/sqrt(length(model1)))
cat("\nLowest and highest samples  ")
cat(max(model1) - min(model0))
cat(" ")
cat(min(model1) - max(model0))
sink()
