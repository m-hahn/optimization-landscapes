library(tidyr)
library(dplyr)

#DEPS = "~/CS_SCR/deps/"
DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_greek", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
dataBackup = data
dataO = data %>% filter(CoarseDependency == "obj")
dataS = data %>% filter(CoarseDependency == "nsubj")

data = merge(dataO, dataS, by=c("Language", "FileName"))




data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))


data %>% group_by(Language) %>% summarise(OSSameSide = mean(OSSameSide))

#1 archaic        0.8  
#2 classical      0.533
#3 koine          0.667


real1 = read.csv("~/scr/deps/LANDSCAPE/mle-fine-greek/archaic_inferRealGrammars.py_model_1821267.tsv", sep="\t") %>% mutate(Language = "archaic")
real2 = read.csv("~/scr/deps/LANDSCAPE/mle-fine-greek/classical_inferRealGrammars.py_model_9519250.tsv", sep="\t") %>% mutate(Language = "classical")
real3 = read.csv("~/scr/deps/LANDSCAPE/mle-fine-greek/koine_inferRealGrammars.py_model_2082411.tsv", sep="\t") %>% mutate(Language = "koine")

real = rbind(real1, real2)
real = rbind(real, real3)

real %>% filter(Dependency %in% c("obj", "nsubj")) %>% mutate(DHProb = 1/(1+exp(-DH_Mean_NoPunct)))

# archaic: 0.56
# classical 0.52
# koine 0.47

