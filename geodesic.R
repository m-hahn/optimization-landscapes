library(tidyr)
library(dplyr)

families = read.csv("families.tsv", sep="\t")


u = merge(families, read.csv("languages-wals-mapping.csv", sep="\t"), by=c("Language"))

wals = read.csv("81A.tab", sep="\t") %>% rename(iso_code=wals.code)
#Matthew S. Dryer. 2013. Order of Subject, Object and Verb.
#In: Dryer, Matthew S. & Haspelmath, Martin (eds.)
#The World Atlas of Language Structures Online.
#Leipzig: Max Planck Institute for Evolutionary Anthropology.
#(Available online at http://wals.info/chapter/81, Accessed on 2020-09-12.)

u = merge(u, wals, by=c("iso_code"), all.x=TRUE) %>% select(iso_code, Language, Name, name, latitude, longitude)
write.table(u, file="change/geolocations.tsv", sep="\t")

