import pystan
from math import sqrt, log
import math


with open("../historical/us.tsv", "r") as inFile:
    data = [x.replace('"', "").split("\t") for x in inFile.read().strip().split("\n")]
    if len(data[0]) < len(data[1]):
        data[0] = ["_"]+data[0]
header = data[0]
header = dict(list(zip(header, range(len(header)))))
data = data[1:]

langs = set()

observations = {}
valueByLanguage = {}
for line in data:
    trajectory = line[header["Trajectory"]]
    time = line[header["Time"]]
    x = float(line[header["OSSameSide_Real_Prob"]])
    y = float(line[header["OSSameSide"]])
    if trajectory not in observations:
        observations[trajectory] = []
    observations[trajectory].append((line[header["Language"]], int(time)/1000.0, (x,y)))
    langs.add(line[header["Language"]])
    valueByLanguage[line[header["Language"]]] = [x,y]
for _, traj in observations.items():
   print(traj)
   traj.sort(key=lambda x:x[1])

parent = {}
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
