library(tidyr)
library(dplyr)

SCR = "~/scr/"
#SCR = "~/CS_SCR/"
DEPS = paste(SCR,"/deps/", sep="")
#DEPS = "/u/scr/mhahn/deps/"
data = read.csv("manual_output_funchead_fine_depl_auto-summary-lstm_2.8.tsv", sep="\t")
dataBackup = data
data = data %>% filter(HeadPOS == "VERB", DependentPOS == "NOUN") %>% select(-HeadPOS, -DependentPOS)



#DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl


dataO = data %>% filter(CoarseDependency == "obj")
dataS = data %>% filter(CoarseDependency == "nsubj")

data = merge(dataO, dataS, by=c("Language", "FileName"))

data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))

data = data %>% mutate(Order = ifelse(OSSameSide & OFartherThanS, "VSO", ifelse(OSSameSide, "SOV", "SVO")))

families = unique(read.csv("families_2.8.tsv", sep="\t"))
data = merge(data, families, by=c("Language"), all.x=TRUE)
unique(data[is.na(data$Family),]$Language)


u = data %>% group_by(Language, Family) %>% summarise(OSSameSideSum=sum(OSSameSide), OSSameSideTotal=NROW(OSSameSide), OSSameSide = mean(OSSameSide), OFartherThanS = mean(OFartherThanS))
print(u[order(u$OSSameSide),], n=60)

sigmoid = function(x) {
	return(1/(1+exp(-x)))
}



real = read.csv("../fitGrammars/output/evaluateCongruence_POS_NoSplit.py.tsv", sep="\t")

#real = read.csv("mle-fine_selected_auto-summary-lstm_2.8.tsv", sep="\t")
u = merge(u, real, by=c("Language"))


write.table(u, file="landscapes_2.8_new.R.tsv")
write.table(real, file="landscapes_2.8_new_real.R.tsv")
write.table(data, file="landscapes_2.8_new_data.R.tsv")

