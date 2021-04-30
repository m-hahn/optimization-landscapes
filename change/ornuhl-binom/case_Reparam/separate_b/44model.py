import pystan
from math import sqrt, log
import math

with open("../../trees2.tsv", "r") as inFile:
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

with open("../../groups2.tsv", "r") as inFile:
  dates = [x.split("\t") for x in inFile.read().strip().split("\n")][1:]
print([len(x) for x in dates])
dates = dict(dates)
dates["_ROOT_"] = -50000
print(dates)
for x in allLangs:
  if x not in observedLangs:
    if x not in dates:
       print(x)

with open("../../../../analysis/landscapes_2.6_new.R.tsv", "r") as inFile:
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
 
   #assert language in parents, language
   x = int(line[header["OSSameSideSum"]])
   y = int(line[header["OSSameSideTotal"]])
   z = float(line[header["OSSameSide_Real_Prob"]])
   valueByLanguage[language] = [x,y,z] 

valueByLanguage["ISWOC_Old_English"] = [10, 13, 0.49]
valueByLanguage["Archaic_Greek"] = [8, 10, 0.56]
valueByLanguage["Classical_Greek"] = [5, 10, 0.52]
valueByLanguage["Koine_Greek"] = [6, 10, 0.47]

print(valueByLanguage)

print(observedLangs)
print(allLangs)
hiddenLangs = [x for x in allLangs if x not in observedLangs and x != "_ROOT_"]
print(hiddenLangs)

#observedLanguages = [x for x in list(observedLangs) if parents[x] not in observedLangs] # This is for understanding what the model does on only synchronic data


with open("../../../../analysis/case_marking/case_marking_revised.tsv", "r") as inFile:
   case_marking = [x.replace('"', "").split(",") for x in inFile.read().strip().split("\n")]
case_marking = {x[2] : True if x[3] == "TRUE" else False for x in case_marking[1:]}

with open("../../../../analysis/case_marking/case_marking_groups.tsv", "r") as inFile:
   for line in inFile:
      x, y = line.strip().split("\t")
      assert x not in case_marking
      case_marking[x] = True if y == "TRUE" else False

def caseMarking(lang):
    if lang in case_marking:
      return case_marking[lang]
    if "_Greek" in lang:
      return True
    assert False, lang


itos_categorical = ["Case", "No Case"]
print(itos_categorical)
stoi_categorical = dict(list(zip(itos_categorical, range(len(itos_categorical)))))

observedLanguages = [x for x in list(observedLangs) if x in valueByLanguage]
hiddenLanguages = hiddenLangs
totalLanguages = ["_ROOT_"] + hiddenLanguages + observedLanguages
lang2Code = dict(list(zip(totalLanguages, range(len(totalLanguages)))))
lang2Observed = dict(list(zip(observedLanguages, range(len(observedLanguages)))))


assert 'Latin_2.6' in valueByLanguage
assert 'Latin_2.6' in totalLanguages
assert 'Latin_2.6' in lang2Code

distanceToParent = {}
for language in allLangs:
   parent = parents.get(language, "_ROOT_")
   if language in observedLangs and parent == "_ROOT_":
     print("ROOT", language)
   dateLang = dates.get(language, 2000)
   dateParent = dates[parent]
   distanceToParent[language] = (float(dateLang)-float(dateParent))/1000
print(distanceToParent)
print(parents.get("Classical_Chinese_2.6"))
assert "Classical_Chinese_2.6" in observedLangs
#quit()

dat = {}

dat["ObservedN"] = len(observedLanguages)
dat["TrialsSuccess"] = [valueByLanguage[x][0] for x in observedLanguages]
dat["TrialsTotal"] = [valueByLanguage[x][1] for x in observedLanguages]
dat["TraitObserved"] = [valueByLanguage[x][2]*2-1 for x in observedLanguages]
dat["HiddenN"] = len(hiddenLanguages)+1
dat["TotalN"] = dat["ObservedN"] + dat["HiddenN"]
dat["IsHidden"] = [1]*dat["HiddenN"] + [0]*dat["ObservedN"]
dat["ParentIndex"] = [0] + [1+lang2Code[parents.get(x, "_ROOT_")] for x in hiddenLanguages+observedLanguages]
dat["Total2Observed"] = [0]*dat["HiddenN"] + list(range(1,1+len(observedLanguages)))
dat["Total2Hidden"] = [1] + list(range(2,2+len(hiddenLanguages))) + [0 for _ in observedLanguages]
dat["OrderCategory"] = [0] + [1 if caseMarking(x) else 2 for x in hiddenLanguages+observedLanguages]
dat["ParentDistance"] = [0] + [distanceToParent[x] for x in hiddenLanguages+observedLanguages]
dat["prior_only"] = 0
dat["Components"] = 2
dat["NumberOfCategories"] = len(stoi_categorical)

print(dat)

sm = pystan.StanModel(file=f'{__file__[:-3]}.stan')


fit = sm.sampling(data=dat, iter=2000, chains=4)
la = fit.extract(permuted=True)  # return a dictionary of arrays
import numpy as np
with open(f"fits/{__file__}.txt", "w") as outFile:
   print(fit, file=outFile)
print((la["Sigma"] > 0).mean(axis=0))
print((la["Omega"] > 0).mean(axis=0))
# Correlation
#print(la["Sigma"][1,2] / (la["Sigma"][1,1].sqrt() * la["Sigma"][2,2].sqrt()))
with open(f"fits/CORR_Sigma_{__file__}.txt", "w") as outFile:
  for x in la["Sigma"][:,0,1] / np.sqrt(la["Sigma"][:,0,0] * la["Sigma"][:,1,1]):
      print(round(float(x), 4), file=outFile)
print(la["Omega"].shape)
with open(f"fits/stationary_fit_{__file__}.txt", "w") as outFile:
 print("Group", "Mean1", "Mean2", "Cov11", "Cov12", "Cov22", file=outFile)
 for i, cat in enumerate(stoi_categorical):
   print(cat.replace(" ", ""), la["alpha"][:,i,0].mean(), la["alpha"][:,i,1].mean(), la["Omega"][:,i,0,0].mean(), la["Omega"][:,i,0,1].mean(), la["Omega"][:,i,1,1].mean(), file=outFile)
