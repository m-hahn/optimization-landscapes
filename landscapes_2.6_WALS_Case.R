library(tidyr)
library(dplyr)

SCR = "~/CS_SCR/"
DEPS = paste(SCR,"/deps/", sep="")
#DEPS = "/u/scr/mhahn/deps/"
data = read.csv(paste(DEPS, "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl", "/", "auto-summary-lstm_2.6.tsv", sep=""), sep="\t")
dataBackup = data
data = data %>% filter(HeadPOS == "VERB", DependentPOS == "NOUN") %>% select(-HeadPOS, -DependentPOS)



#DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl


dataO = data %>% filter(CoarseDependency == "obj")
dataS = data %>% filter(CoarseDependency == "nsubj")

data = merge(dataO, dataS, by=c("Language", "FileName"))

data = data %>% mutate(OFartherThanS = (DistanceWeight.x > DistanceWeight.y))
data = data %>% mutate(OSSameSide = (sign(DH_Weight.x) == sign(DH_Weight.y)))

data = data %>% mutate(Order = ifelse(OSSameSide & OFartherThanS, "VSO", ifelse(OSSameSide, "SOV", "SVO")))

families = read.csv("families.tsv", sep="\t")
data = merge(data, families, by=c("Language"))


u = data %>% group_by(Language, Family) %>% summarise(OSSameSide = mean(OSSameSide), OFartherThanS = mean(OFartherThanS))
print(u[order(u$OSSameSide),], n=60)

sigmoid = function(x) {
	return(1/(1+exp(-x)))
}

u = merge(u, read.csv("languages-wals-mapping.csv", sep="\t"), by=c("Language"))

wals = read.csv("49A.tab", sep="\t") %>% rename(iso_code=wals.code)
#Oliver A. Iggesen. 2013. Number of Cases.
#In: Dryer, Matthew S. & Haspelmath, Martin (eds.)
#The World Atlas of Language Structures Online.
#Leipzig: Max Planck Institute for Evolutionary Anthropology.
#(Available online at http://wals.info/chapter/49, Accessed on 2020-09-20.)

u = merge(u, wals, by=c("iso_code"), all.x=TRUE) %>% mutate(value = (description != "No morphological case-marking"))
crash()
write.csv(u %>% select(iso_code, Language, value), file="case_marking.tsv", sep="\t")



