import pystan
from math import sqrt, log
import math

with open("../geolocations.tsv", "r") as inFile:
  geolocations = [x.split("\t") for x in inFile.read().strip().split("\n")][1:]
print(geolocations)
languages = [x[1] for x in geolocations]
latitudes = [float(x[4]) for x in geolocations]
longitudes = [float(x[5]) for x in geolocations]
latitudes = dict(list(zip(languages, latitudes)))
longitudes = dict(list(zip(languages, longitudes)))


with open("../trees2.tsv", "r") as inFile:
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

with open("../groups2.tsv", "r") as inFile:
  dates = [x.split("\t") for x in inFile.read().strip().split("\n")][1:]
print([len(x) for x in dates])
dates = dict(dates)
dates["_ROOT_"] = -50000
print(dates)
for x in allLangs:
  if x not in observedLangs:
    if x not in dates:
       print(x)

with open("../../landscapes_2.6_POS_Agg.R.tsv", "r") as inFile:
   data = [x.replace('"', '').split("\t") for x in inFile.read().strip().split("\n")]
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
   x = float(line[header["Congruence_VN.x"]])
   y = float(line[header["Count"]])
   assert y == round(y)
   y = round(y)
   x = round(x*y)
   z = float(line[header["Congruence_VN.y"]])
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
observedLanguages = [x for x in list(observedLangs) if x in valueByLanguage]
hiddenLanguages = hiddenLangs
totalLanguages = ["_ROOT_"] + hiddenLanguages + observedLanguages
lang2Code = dict(list(zip(totalLanguages, range(len(totalLanguages)))))
lang2Observed = dict(list(zip(observedLanguages, range(len(observedLanguages)))))

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

from collections import defaultdict
fromParentsToDescendants = defaultdict(list)
for lang, parent in parents.items():
   fromParentsToDescendants[parent].append(lang)
fromParentsToDescendants["_ROOT_"] = []
for lang in fromParentsToDescendants:
    if lang not in parents and lang != "_ROOT_":
        fromParentsToDescendants["_ROOT_"].append(lang)
print(fromParentsToDescendants)

def mean(x):
    return sum(x)/len(x)

done = set()
def getGeolocation(lang):
   if lang in done:
       return
   for lang2 in fromParentsToDescendants[lang]:
       assert lang2 != lang, lang
       getGeolocation(lang2)
   if lang not in latitudes:
     print(lang, fromParentsToDescendants[lang])
     latitudes[lang] = mean([latitudes[x] for x in fromParentsToDescendants[lang]])
     longitudes[lang] = mean([longitudes[x] for x in fromParentsToDescendants[lang]])
   done.add(lang)

getGeolocation("_ROOT_")
print(latitudes)
print(longitudes)

totalLanguages = ["_ROOT_"] + sorted(hiddenLanguages) + sorted(observedLanguages)

import geopy.distance


kernelTime = [[0 for _ in range(len(totalLanguages))] for _ in range(len(totalLanguages))]
for i in range(len(kernelTime)):
   for j in range(i):
     l1 = totalLanguages[i]
     l2 = totalLanguages[j]
     d1 = int(dates.get(l1, 2000))
     d2 = int(dates.get(l1, 2000))
     kernelTime[i][j] = abs(d1-d2)/1000
     kernelTime[j][i] = abs(d1-d2)/1000


kernel = [[0 for _ in range(len(totalLanguages))] for _ in range(len(totalLanguages))]
for i in range(len(kernel)):
   for j in range(i):
     l1 = totalLanguages[i]
     l2 = totalLanguages[j]
     lat1, long1 = latitudes[l1], longitudes[l1]
     lat2, long2 = latitudes[l2], longitudes[l2]
     distance = geopy.distance.geodesic((lat1, long1), (lat2, long2)).km/10000
#     print(lat1, long1, lat2, long2, l1, l2, geopy.distance.geodesic((lat1, long1), (lat2, long2)).km/10000)
     kernel[i][j] = distance
     kernel[j][i] = distance
print(kernel[5][5])
print(kernel[8][8])
dat = {}

dat["ObservedN"] = len(observedLanguages)
dat["TrialsSuccess"] = [valueByLanguage[x][0] for x in observedLanguages]
dat["TrialsTotal"] = [valueByLanguage[x][1] for x in observedLanguages]
dat["TraitObserved"] = [valueByLanguage[x][2]*2-1 for x in observedLanguages]
assert min(dat["TraitObserved"]) < 0
assert max(dat["TraitObserved"]) <= 1
dat["HiddenN"] = len(hiddenLanguages)+1
dat["TotalN"] = dat["ObservedN"] + dat["HiddenN"]
assert dat["TotalN"] == len(totalLanguages)
dat["IsHidden"] = [1]*dat["HiddenN"] + [0]*dat["ObservedN"]
dat["ParentIndex"] = [0] + [1+lang2Code[parents.get(x, "_ROOT_")] for x in hiddenLanguages+observedLanguages]
dat["Total2Observed"] = [0]*dat["HiddenN"] + list(range(1,1+len(observedLanguages)))
dat["Total2Hidden"] = [1] + list(range(2,2+len(hiddenLanguages))) + [0 for _ in observedLanguages]
dat["ParentDistance"] = [0] + [distanceToParent[x] for x in hiddenLanguages+observedLanguages]
dat["prior_only"] = 0
dat["Components"] = 2
print(dat)
dat["DistanceMatrix"] = kernel
dat["DistanceMatrixTime"] = kernelTime

sm = pystan.StanModel(file=f'{__file__[:-3]}.stan')


fit = sm.sampling(data=dat, iter=2000, chains=4)
la = fit.extract(permuted=True)  # return a dictionary of arrays
import numpy as np
with open(f"fits/{__file__}.txt", "w") as outFile:
   print(fit, file=outFile)
#print((la["Lrescor_Sigma"] > 0).mean(axis=0))
print((la["Sigma"] > 0).mean(axis=0))
print((la["Omega"] > 0).mean(axis=0))
# Correlation
#print(la["Sigma"][1,2] / (la["Sigma"][1,1].sqrt() * la["Sigma"][2,2].sqrt()))
with open(f"fits/CORR_Sigma_{__file__}.txt", "w") as outFile:
  for x in la["Sigma"][:,0,1] / np.sqrt(la["Sigma"][:,0,0] * la["Sigma"][:,1,1]):
      print(round(float(x),4), file=outFile)
with open(f"fits/CORR_Omega_{__file__}.txt", "w") as outFile:
  for x in la["Omega"][:,0,1] / np.sqrt(la["Omega"][:,0,0] * la["Omega"][:,1,1]):
      print(round(float(x),4), file=outFile)

