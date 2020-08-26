#data = read.csv("optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_Real_Collect_All.py.tsv", sep="\t")
#data = read.csv("optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_MLE_Collect_All.py.tsv", sep="\t")
data = read.csv("optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_Deterministic_Collect_All.py.tsv", sep="\t")
#data = read.csv("optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_Collect_All.py.tsv", sep="\t")

library(tidyr)
library(dplyr)
library(ggplot2)

ggplot(data, aes(x=Fraction, y=DepLenBest)) + geom_point() + facet_wrap(~Language, scales="free")

ggplot(data, aes(x=Fraction, y=DepLen)) + geom_point() + facet_wrap(~Language, scales="free")

data = data %>% mutate(Freedom = -(Fraction/10*log(Fraction/10+1e-10) + (1-Fraction/10)*log(1-Fraction/10+1e-10)))

data = data %>% mutate(SameSide = (Fraction > 5))

ggplot(data, aes(x=Freedom, y=DepLen, color=SameSide)) + geom_line() + facet_wrap(~Language, scales="free")
ggplot(data, aes(x=Freedom, y=DepLenBest, color=SameSide)) + geom_line() + facet_wrap(~Language, scales="free")




data = read.csv("optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_Real2_Collect_All.py.tsv", sep="\t")

library(tidyr)
library(dplyr)
library(ggplot2)


absolute = data %>% group_by(Language) %>% summarise(DepLen1 = max(DepLen1), DepLenBest1 = max(DepLenBest1), DepLenReal = max(DepLenReal))

ggplot(data, aes(x=Fraction, y=DepLenBest)) + geom_point() + facet_wrap(~Language, scales="free")



data = data %>% mutate(Freedom = -(Fraction/10*log(Fraction/10+1e-10) + (1-Fraction/10)*log(1-Fraction/10+1e-10)))

data = data %>% mutate(SV = (Fraction > 5))

ggplot(data, aes(x=Freedom, y=DepLenBest, color=SV)) + geom_line() + facet_wrap(~Language, scales="free")
# In most cases, the RED line is more efficient





data = read.csv("optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_MLE_Collect_All.py.tsv", sep="\t")

ggplot(data, aes(x=Fraction, y=DepLenBest)) + geom_point() + facet_wrap(~Language, scales="free")



data = data %>% mutate(Freedom = -(Fraction/10*log(Fraction/10+1e-10) + (1-Fraction/10)*log(1-Fraction/10+1e-10)))

data = data %>% mutate(SV = (Fraction > 5))

ggplot(data, aes(x=Freedom, y=DepLenBest, color=SV)) + geom_line() + facet_wrap(~Language, scales="free")






data = read.csv("optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_Real2_OBJ_Collect_All.py.tsv", sep="\t")

library(tidyr)
library(dplyr)
library(ggplot2)


absolute = data %>% group_by(Language) %>% summarise(DepLen1 = max(DepLen1), DepLenBest1 = max(DepLenBest1), DepLenReal = max(DepLenReal))

ggplot(data, aes(x=Fraction, y=DepLenBest)) + geom_point() + facet_wrap(~Language, scales="free")



data = data %>% mutate(Freedom = -(Fraction/10*log(Fraction/10+1e-10) + (1-Fraction/10)*log(1-Fraction/10+1e-10)))

data = data %>% mutate(OV = (Fraction > 5))

ggplot(data, aes(x=Freedom, y=DepLenBest, color=OV)) + geom_line() + facet_wrap(~Language, scales="free")



