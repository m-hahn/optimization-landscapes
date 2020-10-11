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

with open("../../landscapes_2.6_new.R.tsv", "r") as inFile:
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
import torch




dat["ObservedN"] = len(observedLanguages)
#dat["ObservedN"] = 3




dat["TrialsSuccess"] = torch.FloatTensor([valueByLanguage[x][0] for x in observedLanguages])
dat["TrialsTotal"] = torch.FloatTensor([valueByLanguage[x][1] for x in observedLanguages])
dat["TraitObserved"] = torch.FloatTensor([valueByLanguage[x][2]*2-1 for x in observedLanguages])
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


dat["Trait2Observed"] = 2*(dat["TrialsSuccess"]/dat["TrialsTotal"])-1

traits = torch.cat([dat["TraitObserved"], dat["Trait2Observed"]], dim=0)
print(traits)


alpha1 = torch.FloatTensor([0.0])
rho1 = torch.FloatTensor([0.0])
alpha2 = torch.FloatTensor([0.0])
rho2 = torch.FloatTensor([0.0])


Bdiag1 = torch.FloatTensor([0.0])
Bdiag2 = torch.FloatTensor([0.0])


driftTowardsNeighbors1 = torch.FloatTensor([-2.0])
driftTowardsNeighbors2 = torch.FloatTensor([-2.0])


Sigma_sigma1 = torch.FloatTensor([0.0])
Sigma_sigma2 = torch.FloatTensor([0.0])
Sigma_corr = torch.FloatTensor([0.0])


Omega_cholesky = torch.zeros(2*dat["ObservedN"], 2*dat["ObservedN"])
Omega_cholesky.uniform_(-0.1, 0.1)
cholesky_mask = torch.FloatTensor([[0 if i <= j else 1 for j in range(2*dat["ObservedN"])] for i in range(2*dat["ObservedN"])])
Omega_cholesky_diag = torch.FloatTensor([0.0 for i in range(2*dat["ObservedN"])])
Omega_cholesky_diag.uniform_(0.001, 0.1)

parameters = [Omega_cholesky, alpha1, rho1, alpha2, rho2, Bdiag1, Bdiag2, driftTowardsNeighbors1, driftTowardsNeighbors2, Sigma_sigma1, Sigma_sigma2, Sigma_corr, Omega_cholesky_diag]
for x in parameters:
   x.requires_grad=True
optimizer = torch.optim.SGD(lr=0.0001, params=parameters)

#distanceMatrix = torch.FloatTensor([[kernel[i//2][j//2] if i%2 == j%2 else 100000000000 for j in range(2*dat["ObservedN"])] for i in range(2*dat["ObservedN"])])
distanceMatrix = torch.FloatTensor([[kernel[i][j] for j in range(dat["ObservedN"])] for i in range(dat["ObservedN"])])

print(distanceMatrix)

identityMatrix = torch.diag(torch.FloatTensor([1.]).expand(dat["ObservedN"]))
identityMatrix2 = torch.diag(torch.FloatTensor([1.]).expand(2*dat["ObservedN"]))

from scipy.linalg import expm


#class MyMatrixExponential(torch.autograd.Function):
#   @staticmethod
#    def forward(ctx, input):
#        ctx.save_for_backward(input)
#        return torch.FloatTensor(expm(-0.1 * BFull.detach().numpy))
#   @staticmethod
#     def backward(ctx, grad_output):
#       return None
#

BZeros = torch.zeros(dat["ObservedN"], dat["ObservedN"])


for iteration in range(100000):
    kernel1 = torch.log(1+torch.exp(alpha1))*(torch.exp(-torch.log(1+torch.exp(rho1)) * distanceMatrix) - identityMatrix)
    kernel2 = torch.log(1+torch.exp(alpha2))*(torch.exp(-torch.log(1+torch.exp(rho2)) * distanceMatrix) - identityMatrix)
    
    B1 = -kernel1
#    print("Interaction terms only", B1[:3, :3])
    B1ForDiagonal = -B1.sum(dim=1)
 #   print("ForDiagonal", B1ForDiagonal[:3])
  #  print("Drift weight", torch.diag(torch.log(1+torch.exp(driftTowardsNeighbors1))))
   # print("Center drift weight", torch.log(1+torch.exp(Bdiag1)))
    B1 = B1 + torch.diag(B1ForDiagonal)
    B1 = torch.log(1+torch.exp(driftTowardsNeighbors1)) * B1
    B1 = B1 + torch.diag(torch.log(1+torch.exp(Bdiag1)).expand(dat["ObservedN"]))
    #print("B1", B1[:3, :3])
#    #print(B1)
 #   S1, U1 = torch.symeig(B1, eigenvectors=True)
  #  assert float(S1.min()) > 0, S1.min()  
   # print(S1.min())
    #quit()

    B2 = -kernel1
    B2ForDiagonal = -B2.sum(dim=1)
    B2 = B2 + torch.diag(torch.log(1+torch.exp(driftTowardsNeighbors2)) * B2ForDiagonal + torch.log(1+torch.exp(Bdiag2)).expand(dat["ObservedN"]))
    
    
    
    # This could be avoided if representing Omega in terms of blocks 
    BFull1 = torch.cat([B1, BZeros], dim=1)
    BFull2 = torch.cat([BZeros, B2], dim=1)
    BFull = torch.cat([BFull1, BFull2], dim=0)
    #print(BFull)
    
    
    variance1=torch.log(1+torch.exp(Sigma_sigma1))
    variance2=torch.log(1+torch.exp(Sigma_sigma2))
    correlation=torch.tanh(Sigma_corr) * torch.sqrt(variance1*variance2)
    Sigma1 = torch.diag(variance1.expand(dat["ObservedN"]))
   # print(Sigma1)
    Sigma2 = torch.diag(variance2.expand(dat["ObservedN"]))
    
    Sigma12 = torch.diag(correlation.expand(dat["ObservedN"]))
  #  print(Sigma12)
    Sigma_top = torch.cat([Sigma1, Sigma12], dim=1)
    Sigma_bot = torch.cat([Sigma12, Sigma2], dim=1)
    Sigma_Full = torch.cat([Sigma_top, Sigma_bot], dim=0)
 #   print(Sigma_Full)
#    print(correlation)
    
    
    Omega_triang = Omega_cholesky * cholesky_mask + torch.diag(Omega_cholesky_diag)
#    print(Omega_cholesky_diag)
 #   print("Smallest diagonal value", torch.diagonal(Omega_triang).min(), Omega_cholesky_diag.min())
    Omega = torch.matmul(Omega_triang, Omega_triang.t()) 
#    print(Omega)
 #   print(torch.det(Omega))
  #  quit()
    loss = ((torch.matmul(BFull.detach(), Omega) + torch.matmul(Omega, BFull.t().detach())) - Sigma_Full.detach()).pow(2).sum()
#    print("Diagonal loss", (Omega - Omega.t()).pow(2).sum())
#    print(Omega)
#    print(loss)
    #BFullUpper = torch.triu(BFull)

    # SANITY CHECK
    S1, U1 = torch.symeig(B1, eigenvectors=True)
    S2, U2 = torch.symeig(B2, eigenvectors=True)
    assert float(S1.min()) > 0, S1.min()
    assert float(S2.min()) > 0, S2.min()
    if iteration > 50000000: # warmup for Omega 
   #    exponentiated = expm(-0.1 * BFull)
       S1, U1 = torch.symeig(B1, eigenvectors=True)
       S2, U2 = torch.symeig(B2, eigenvectors=True)
   #    print("Recovering matrix")
    #   print((B1-torch.matmul(U1, (S1.unsqueeze(1) * U1.t()))).pow(2).mean())
#       exp1 = torch.matmul(U1, (torch.exp(-0.1*S1).unsqueeze(1) * U1.t()))
#       exp2 = torch.matmul(U2, (torch.exp(-0.1*S2).unsqueeze(1) * U2.t()))
   
#       expFull1 = torch.cat([exp1, BZeros], dim=1)
#       expFull2 = torch.cat([BZeros, exp2], dim=1)
#       expFull = torch.cat([expFull1, expFull2], dim=0)
#   
#       covarianceMatrix = torch.matmul(expFull, torch.matmul(Omega, expFull))
       log_determinantOfExponentialPart1 = (-0.1*S1).sum()
       log_determinantOfExponentialPart2 = (-0.1*S2).sum()
       log_determinantOmega = (Omega_cholesky_diag.pow(2)).log().sum()
       #print(log_determinantOmega)
       #print(log_determinantOfExponentialPart1, log_determinantOfExponentialPart2, log_determinantOmega)
#       OmegaInverse = torch.inverse(Omega_cholesky).t() # only the left part -- taking this times its transpose is the actual inverse
       exponentialPartInverse1 = torch.matmul(U1.t(), torch.exp(0.1*S1).unsqueeze(1) * U1)
       exponentialPartInverse2 = torch.matmul(U2.t(), torch.exp(0.1*S2).unsqueeze(1) * U2)
       forLikelihoodUpper = torch.matmul(dat["TraitObserved"].unsqueeze(0), exponentialPartInverse1).view(-1)
       forLikelihoodLower = torch.matmul(dat["TraitObserved"].unsqueeze(0), exponentialPartInverse2).view(-1)
       forLikelihoodCat = torch.cat([forLikelihoodUpper, forLikelihoodLower], dim=0)
       # Conceptually, compute forLikelihoodCat * Omega_cholesky^{-1}
       forLikelihoodHalf = torch.triangular_solve(input=forLikelihoodCat.unsqueeze(1), A=Omega_triang.t())[0].squeeze(1)
#       forLikelihoodHalf = torch.matmul(forLikelihoodCat, OmegaInverse)
       print("Solution of upper triangular equation", forLikelihoodHalf.mean(), forLikelihoodCat.mean(), Omega_triang.mean())
       forLikelihoodExponent = -0.5 * forLikelihoodHalf.pow(2).sum()
      # print(forLikelihoodExponent)
       print("LogDetermines", log_determinantOmega, log_determinantOfExponentialPart1, log_determinantOfExponentialPart2, "Exponent", forLikelihoodExponent)
       overallLogLikelihood = (-0.5 * (log_determinantOmega + log_determinantOfExponentialPart1 + log_determinantOfExponentialPart2)) + forLikelihoodExponent
     #  print(overallLogLikelihood)
       loss -= overallLogLikelihood
       print("LIKELIHOOD", overallLogLikelihood)
    if iteration % 100 == 0:
       print(iteration, "LOSS", loss, "Correlation", correlation)
    optimizer.zero_grad()
    loss.backward()
    optimizer.step() 
#    Omega_cholesky_diag.data = torch.clamp(Omega_cholesky_diag.data, min=1e-3)
