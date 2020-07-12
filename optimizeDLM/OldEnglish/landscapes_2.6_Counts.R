library(tidyr)
library(dplyr)

DEPS = "~/CS_SCR/deps/"
#DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_funchead_ISWOC_OldEnglish", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
dataBackup = data
data = data %>% filter(HeadPOS == "V", DependentPOS == "N") %>% select(-HeadPOS, -DependentPOS)



#DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl


dataO = data %>% filter(CoarseDependency == "obj")
dataS = data %>% filter(CoarseDependency == "sub")

data = merge(dataO, dataS, by=c("Language", "FileName", "Document"))




data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))


data %>% group_by(Document) %>% summarise(OSSameSide = mean(OSSameSide))

#  Document OSSameSide
#  <fct>         <dbl>
#1 aels          0.267    - 1000
#2 apt           0.867    - (translated?)
#3 chrona        0.8      - 880
#4 or            0.467    - 880 (translated?)
#5 wscp          0.467    - 990 (translated)



