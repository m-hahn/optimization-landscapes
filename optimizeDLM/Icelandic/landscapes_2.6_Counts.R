library(tidyr)
library(dplyr)

#DEPS = "~/CS_SCR/deps/"
DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_icelandic", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
dataBackup = data
dataO = data %>% filter(CoarseDependency == "obj")
dataS = data %>% filter(CoarseDependency == "nsubj")

data = merge(dataO, dataS, by=c("Language", "FileName"))




data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))


data %>% group_by(Language) %>% summarise(observations=NROW(OSSameSide), OSSameSide = mean(OSSameSide))

ggplot(data %>% filter(end.x == start.x+100 | end.x==1200 | start.x==1900) %>% group_by(end.x) %>% summarise(OSSameSide = mean(OSSameSide)), aes(x=end.x,y=OSSameSide)) + geom_line()


