import pystan
from math import sqrt, log
import math

with open("trees.tsv", "r") as inFile:
  trees = [x.split("\t") for x in inFile.read().strip().split("\n")][1:]
print(trees)

langs = set()
allLangs = set()
parents = {}
for line in trees:
   langs.add(line[0])
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
print(dates)
for x in allLangs:
  if x not in langs:
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
   x = line[header["OSSameSide"]]
   y = line[header["OSSameSide_Real_Prob"]]
   valueByLanguage[language] = [x,y] 

valueByLanguage["ISWOC_Old_English"] = [0.769, 0.49]
valueByLanguage["Archaic_Greek"] = [0.8, 0.56]
valueByLanguage["Classical_Greek"] = [0.53, 0.52]
valueByLanguage["Koine_Greek"] = [0.67, 0.47]

print(valueByLanguage)
quit()

distanceToParent = {}
for _, trajectory in observations.items():
   parent[trajectory[1][0]] = trajectory[0][0]
   distanceToParent[trajectory[1][0]] = trajectory[1][1] - trajectory[0][1]
   assert distanceToParent[trajectory[1][0]] > 0
print(parent)
print(distanceToParent)


observedLanguages = list(langs)
hiddenLanguages = []
totalLanguages = ["_ROOT_"] + hiddenLanguages + observedLanguages
lang2Code = dict(list(zip(totalLanguages, range(len(totalLanguages)))))
lang2Observed = dict(list(zip(observedLanguages, range(len(observedLanguages)))))

dat = {}

dat["ObservedN"] = len(observedLanguages)
dat["TraitsObserved"] = [valueByLanguage[x] for x in observedLanguages]
dat["HiddenN"] = len(hiddenLanguages)+1
dat["TotalN"] = dat["ObservedN"] + dat["HiddenN"]
dat["IsHidden"] = [1]*dat["HiddenN"] + [0]*dat["ObservedN"]
dat["ParentIndex"] = [0] + [] + [1+lang2Code[parent.get(x, "_ROOT_")] for x in observedLanguages]
dat["Total2Observed"] = [0] + [] + list(range(1,1+len(observedLanguages)))
dat["Total2Hidden"] = [1] + [] + [0 for _ in observedLanguages]
dat["ParentDistance"] = [0] + [] + [distanceToParent.get(x, 10) for x in observedLanguages]
dat["prior_only"] = 0
dat["Components"] = 2

print(dat)

sm = pystan.StanModel(file='3model.stan')


fit = sm.sampling(data=dat, iter=2000, chains=4)
la = fit.extract(permuted=True)  # return a dictionary of arrays
print(fit)
print(la)
print("Inferred hidden traits", la["TraitsHidden"].mean(axis=0))
print(la["Rescor"][:, 1, 0])
print(la["Rescor"][:, 1, 0] > 0)
print((la["Rescor"][:, 1, 0] > 0).mean())
