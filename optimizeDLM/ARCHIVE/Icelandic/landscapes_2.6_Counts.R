library(tidyr)
library(dplyr)

DEPS = "~/CS_SCR/deps/"
#DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_icelandic", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
dataBackup = data
dataO = data %>% filter(CoarseDependency == "obj")
dataS = data %>% filter(CoarseDependency == "nsubj")

data = merge(dataO, dataS, by=c("Language", "FileName"))




data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))


data %>% group_by(Language) %>% summarise(observations=NROW(OSSameSide), OSSameSide = mean(OSSameSide))

library(ggplot2)
ggplot(data %>% filter(end.x == start.x+100 | end.x==1200 | start.x==1900) %>% group_by(end.x) %>% summarise(OSSameSide = mean(OSSameSide)), aes(x=end.x,y=OSSameSide)) + geom_line()

dataOptim = data %>% filter(end.x == start.x+100 | end.x==1200 | start.x==1900) %>% group_by(end.x) %>% summarise(OSSameSide = mean(OSSameSide)) %>% rename(year=end.x, Symmetry=OSSameSide) %>% mutate(Type="Optim")


dataReals = read.csv("~/change/results/order_S.tsv", sep="\t")
dataRealo = read.csv("~/change/results/order.tsv", sep="\t")
dataReals
names(dataReals)
dataReal = merge(dataReals, dataRealo, by=c("year", "text"))
dataReal$SV_ = dataReal$SV/(dataReal$SV+dataReal$VS)
dataReal$OV_ = dataReal$OV/(dataReal$OV+dataReal$VO)
dataReal$Symmetry = dataReal$SV_ * dataReal$OV_ + (1-dataReal$SV_) * (1-dataReal$OV_)
dataReal$Symmetry
dataReal$Type = "Real"
cor(dataReal$Symmetry, dataReal$year)
#savehistory(file="symmetry.R")
library(ggplot2)

data = rbind(dataOptim, dataReal %>% select(year, Symmetry, Type))

plot = ggplot(data, aes(x=year, y=Symmetry, color=Type, group=Type)) + geom_line()
ggsave(plot, file="Icelandic.pdf")




