library(tidyr)
library(dplyr)

SCR = "~/scr/"
#SCR = "~/CS_SCR/"
DEPS = paste(SCR,"/deps/", sep="")
#DEPS = "/u/scr/mhahn/deps/"

data = read.csv("../optimizeDLM/output/evaluateCongruence_POS_NoSplit.py.tsv", sep="\t")
data = data %>% group_by(Language) %>% summarise(Congruence_All=mean(Congruence_All), Congruence_VN=mean(Congruence_VN), Congruence_VP=mean(Congruence_VP), Congruence_V=mean(Congruence_V), Congruence_VProp=mean(Congruence_VProp))


families = read.csv("families.tsv", sep="\t")
data = merge(data, families, by=c("Language"), all.x=TRUE)
genera = read.csv("genera.tsv", sep="\t")
data = merge(data, genera, by=c("Language", "Family"), all.x=TRUE)

real = read.csv("../fitGrammars/output/evaluateCongruence_POS_NoSplit.py.tsv", sep="\t")

data = merge(data, real, by=c("Language"))

write.table(data, file="landscapes_2.6_POS_Agg.R.tsv", sep="\t")

