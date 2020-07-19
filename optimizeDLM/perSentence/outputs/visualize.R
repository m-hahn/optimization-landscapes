#data = read.csv("optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_Real_Collect_All.py.tsv", sep="\t")
#data = read.csv("optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_Deterministic_Collect_All.py.tsv", sep="\t")
data = read.csv("optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_Collect_All.py.tsv", sep="\t")

library(tidyr)
library(dplyr)
library(ggplot2)


ggplot(data, aes(x=Fraction, y=DepLen)) + geom_point() + facet_wrap(~Language, scales="free")

data = data %>% mutate(Freedom = -(Fraction/10*log(Fraction/10+1e-10) + (1-Fraction/10)*log(1-Fraction/10+1e-10)))

data = data %>% mutate(SameSide = (Fraction > 5))

ggplot(data, aes(x=Freedom, y=DepLen, color=SameSide)) + geom_line() + facet_wrap(~Language, scales="free")



