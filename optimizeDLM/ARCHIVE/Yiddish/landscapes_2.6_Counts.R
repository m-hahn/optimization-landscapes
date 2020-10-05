library(tidyr)
library(dplyr)

#DEPS = "~/CS_SCR/deps/"
DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_funchead_Yiddish", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
dataBackup = data
#DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl


dataS = data %>% filter(CoarseDependency == "NP-SBJ")
dataO = data %>% filter(CoarseDependency == "NP-ACC")

data = merge(dataO, dataS, by=c("Language", "FileName", "Document"))




data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))


data %>% group_by(Document) %>% summarise(OSSameSide = mean(OSSameSide))



data$Document = as.numeric(as.character(data$Document))

summary(glm(OSSameSide ~ Document, data=data))


