import pystan
from math import sqrt, log
import math

with open("trees.tsv", "r") as inFile:
  trees = [x.split("\t") for x in inFile.read().strip().split("\n")][1:]
print(trees)

observedLangs = set()
allLangs = set()
parents = {}
for line in trees:
   observedLangs.add(line[0])
   allLangs.add(line[0])
   for i in range(len(line)-1):
       child = line[i]
       parent = line[i+1]
       if child in parents:
         assert parents[child] == parent, (parents[child], line, child, i)
       parents[child] = parent
       allLangs.add(parent)

with open("groups.tsv", "r") as inFile:
  dates = [x.split("\t") for x in inFile.read().strip().split("\n")][1:]
print([len(x) for x in dates])
dates = dict(dates)
dates["_ROOT_"] = -50000
print(dates)
for x in allLangs:
  if x not in observedLangs:
    if x not in dates:
       print(x)

with open("../landscapes_2.6.R.tsv", "r") as inFile:
   data = [x.replace('"', '').split(" ") for x in inFile.read().strip().split("\n")]
header = data[0]
header = ["ROWNUM"] + header
header = dict(list(zip(header, range(len(header)))))
data = data[1:]
print(header)
valueByLanguage = {}
for line in data:
   language = line[header["Language"]]
   if language == "Ancient_Greek_2.6":
     continue
   x = float(line[header["OSSameSide"]])
   y = float(line[header["OSSameSide_Real_Prob"]])
   valueByLanguage[language] = [x,y] 

valueByLanguage["ISWOC_Old_English"] = [0.769, 0.49]
valueByLanguage["Archaic_Greek"] = [0.8, 0.56]
valueByLanguage["Classical_Greek"] = [0.53, 0.52]
valueByLanguage["Koine_Greek"] = [0.67, 0.47]

print(valueByLanguage)

print(observedLangs)
print(allLangs)
hiddenLangs = [x for x in allLangs if x not in observedLangs]
print(hiddenLangs)

#observedLanguages = [x for x in list(observedLangs) if parents[x] not in observedLangs] # This is for understanding what the model does on only synchronic data
observedLanguages = list(observedLangs)
hiddenLanguages = hiddenLangs
totalLanguages = ["_ROOT_"] + hiddenLanguages + observedLanguages
lang2Code = dict(list(zip(totalLanguages, range(len(totalLanguages)))))
lang2Observed = dict(list(zip(observedLanguages, range(len(observedLanguages)))))

distanceToParent = {}
for language in allLangs:
   parent = parents.get(language, "_ROOT_")
   if language in observedLangs:
     assert parent != "_ROOT_", language
   dateLang = dates.get(language, 2000)
   dateParent = dates[parent]
   distanceToParent[language] = (float(dateLang)-float(dateParent))/1000
print(distanceToParent)
#quit()

dat = {}

dat["ObservedN"] = len(observedLanguages)
dat["TraitsObserved"] = [valueByLanguage[x] for x in observedLanguages]
dat["HiddenN"] = len(hiddenLanguages)+1
dat["TotalN"] = dat["ObservedN"] + dat["HiddenN"]
dat["IsHidden"] = [1]*dat["HiddenN"] + [0]*dat["ObservedN"]
dat["ParentIndex"] = [0] + [1+lang2Code[parents.get(x, "_ROOT_")] for x in hiddenLanguages+observedLanguages]
dat["Total2Observed"] = [0]*dat["HiddenN"] + list(range(1,1+len(observedLanguages)))
dat["Total2Hidden"] = [1] + list(range(2,2+len(hiddenLanguages))) + [0 for _ in observedLanguages]
dat["ParentDistance"] = [0] + [distanceToParent.get(x, 10) for x in hiddenLanguages+observedLanguages]
dat["prior_only"] = 0
dat["Components"] = 2

print(dat)

sm = pystan.StanModel(file='8model.stan')


fit = sm.sampling(data=dat, iter=2000, chains=4)
la = fit.extract(permuted=True)  # return a dictionary of arrays
with open(f"fits/{__file__}.txt", "w") as outFile:
   print(fit, file=outFile)
   print(la, file=outFile)
print(fit)
print(la)
print("Inferred hidden traits", la["TraitsHidden"].mean(axis=0))

