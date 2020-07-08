# Optimizing a grammar for dependency length minimization

import random
import sys

objectiveName = "DepL"

import argparse

parser = argparse.ArgumentParser()

parser.add_argument('--language', type=str)
parser.add_argument('--entropy_weight', type=float, default=0.001)
parser.add_argument('--lr_policy', type=float, default=0.1)
parser.add_argument('--momentum', type=float, default=0.9)

args = parser.parse_args()

myID = random.randint(0,10000000)


posUni = set()
posFine = set() 
deps = ["acl", "acl:relcl", "advcl", "advmod", "amod", "appos", "aux", "auxpass", "case", "cc", "ccomp", "compound", "compound:prt", "conj", "conj:preconj", "cop", "csubj", "csubjpass", "dep", "det", "det:predet", "discourse", "dobj", "expl", "foreign", "goeswith", "iobj", "list", "mark", "mwe", "neg", "nmod", "nmod:npmod", "nmod:poss", "nmod:tmod", "nsubj", "nsubjpass", "nummod", "parataxis", "punct", "remnant", "reparandum", "root", "vocative", "xcomp"] 



from math import log, exp
from random import random, shuffle


from corpusIterator_V import CorpusIterator_V as CorpusIterator

originalDistanceWeights = {}


def makeCoarse(x):
   if ":" in x:
      return x[:x.index(":")]
   return x
import hashlib
def hash_(x):
  return hashlib.sha224(x).hexdigest()




hashToSentence = {}

for partition in ["together"]:
  for sentence in CorpusIterator(args.language,partition).iterator():
      sentenceHash = hash_(" ".join([x["word"] for x in sentence]))
      hashToSentence[sentenceHash] = sentence

TARGET_DIR = "/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_perSent/"
import glob
from collections import defaultdict
orderBySentence = {x:[] for x in hashToSentence}
files = glob.glob(TARGET_DIR+"/"+args.language+"*.tsv")
for path in files:
  print(path)
  with open(path, "r") as inFile:
    header = next(inFile).strip().split("\t")
    header = dict(list(zip(header, range(len(header)))))
#             print >> outFile, "\t".join(map(str,["DH_Weight","CoarseDependency","HeadPOS", "DependentPOS", "DistanceWeight", "Language", "FileName"]))
    objDir = None
    orderBySentenceHere = {}
    for line in inFile:
       line = line.strip().split("\t")
       dhWeight = float(line[header["DH_Weight"]])
       dependency = line[header["CoarseDependency"]]
       head = line[header["HeadPOS"]]
       dependent = line[header["DependentPOS"]]
#       print(dhWeight, dependency, head, dependent)
       if dependency == "obj" and head == "VERB" and dependent == "NOUN":
          objDir = 1 if dhWeight > 0 else -1
       elif dependency.startswith("nsubj_"):
          hash_ = dependency[dependency.index("_")+1:]
    #      print(hash_, hash_ in hashToSentence)
          orderBySentenceHere[hash_] = (1 if dhWeight > 0 else -1)
    for hash_, direction in orderBySentenceHere.items():
       orderBySentence[hash_].append(direction * objDir)
def mean(x):
   return sum(x)/(len(x)+1e-10)
fleissKappa = 0.0
countP_, countN_ = 0.0, 0.0
for s, values in orderBySentence.items():
    if len(values) == 0:
      continue
    countP = sum([1 for x in values if x >= 0])
    countN = sum([1 for x in values if x < 0])
    countP_ += countP
    countN_ += countN
    assert countP + countN == len(files), (len(values), len(files), countN+countP, values)
    fleissKappa += countP * (countP-1) + countN * (countN-1)
fleissKappa /= (len(orderBySentence) * len(files) * (len(files)-1)) + 1e-10
fleissKappaExpected = (countP_**2 + countN_**2) / ((countP_+countN_)**2 + 1e-10)
#quit()

def printSent(l):
   for x in l:
      print("\t".join([str(y) for y in [x["index"], x["word"], x["head"], x["posUni"], x["dep"], "------" if (x["dep"] == "nsubj" and x["posUni"] == "NOUN") else ""]]))

sentenceToHash = [(x, mean(y)) for x, y in orderBySentence.items()]
sentenceToHash = sorted(sentenceToHash, key=lambda x:x[1])

def annotateChildren(sentence):
   for l in sentence:
      l["children"] = []
   for l in sentence:
      if l["head"] != 0:
         sentence[l["head"]-1]["children"].append(l["index"]) 

def length(i, sentence):
    if "length" not in sentence[i-1]:
       sentence[i-1]["length"] = 1+sum([length(x, sentence) for x in sentence[i-1]["children"]])
    return sentence[i-1]["length"]


matrix = {}
matrix["order"] = []
matrix["verbDependents"] = []
matrix["objects"] = []
matrix["isRoot"] = []
matrix["verbLength"] = []
matrix["subjectLength"] = []
matrix["realOrders"] = []

def mean(x):
   return sum(x)/(len(x)+1e-10)
for x in sentenceToHash:
 #   print(x)
    order = x[1]
    sent = hashToSentence[x[0]]
    annotateChildren(sent)
    subjects = [i for i in range(len(sent)) if sent[i]["dep"] == "nsubj" and sent[i]["posUni"] == "NOUN" and sent[sent[i]["head"]-1]["posUni"] == "VERB"]
#    print(subjects)
    subjectsOrders = [1 if sent[i]["head"] < sent[i]["index"] else -1 for i in subjects]
    subjectsToVerbs = [sent[sent[i]["head"]-1]["index"]-1 for i in subjects]
#    print(sent)
    verbDependents = [len([x["index"]-1 for x in sent if x["head"] == i+1]) for i in subjectsToVerbs]
    #print(verbDependents)
    objects = [[x["index"]-1 for x in sent if x["head"] == i+1 and x["dep"] == "obj"] for i in subjectsToVerbs]
   # print(subjectsToVerbs)
  #  print(objects)
    isRoot = [1 if sent[i]["dep"] == "root" else 0 for i in subjectsToVerbs]
 #   print(isRoot)
    subjectLength = [length(i+1, sent) for i in subjects]
    verbConstituentLength = [length(i+1, sent) for i in subjectsToVerbs]
#    print(subjectLength, verbConstituentLength)
    if len(subjects) > 0:
       matrix["order"].append(order)
       matrix["verbDependents"].append(mean(verbDependents))
       matrix["objects"].append(mean([len(x) for x in objects]))
       matrix["isRoot"].append(mean(isRoot))
       matrix["verbLength"].append(mean(verbConstituentLength) - mean(subjectLength))
       matrix["subjectLength"].append(mean(subjectLength))
       matrix["realOrders"].append(mean(subjectsOrders))


columns = sorted(list(matrix))
print(columns)
with open("outputs/"+__file__+".tsv", "a") as outFile:
   print >> outFile, "\t".join([args.language] + [str(mean(matrix[x])) for x in columns if x != "realOrders"])
import torch
for x in matrix:
  if x != "order" and x != "realOrders":
     m = mean(matrix[x])
     print("\t".join([x, str(m)]))
     matrix[x] = [y-m for y in matrix[x]]

#matrix = {x : torch.FloatTensor(y) for x,y in matrix.items()}
with open("/u/scr/mhahn/TMP.tsv", "w") as outFile:
  print >> outFile, ("\t".join(columns))
  for i in range(len(matrix["order"])):
     print >> outFile, "\t".join([str(matrix[header][i]) for header in columns]) 
  print(list(matrix))


predictors = [x for x in columns if x not in ["order", "realOrders"]]
outVector = (torch.FloatTensor(matrix["realOrders"]) > 0).long().numpy()
inVector = torch.FloatTensor([matrix[x] for x in predictors]).t().numpy() # [[1 for _ in range(len(matrix["order"]))]] + 




from sklearn.linear_model import LogisticRegression
import statsmodels.api as sm

print("PREDICTING REAL ORDERS")
#### Statsmodels
# first artificially add intercept to x, as advised in the docs:
x_ = sm.add_constant(inVector)
res_sm = sm.Logit(outVector, x_).fit(method="ncg", maxiter=10000) # x_ here
print(res_sm.params)
print(res_sm.summary())
print(predictors)


if mean(matrix["order"]) == 0:
   quit()

print("PREDICTING OPTIMIZED ORDERS")
predictors = [x for x in columns if x not in ["order", "realOrders"]]
outVector = (torch.FloatTensor(matrix["order"]) > 0).long().numpy()
inVector = torch.FloatTensor([matrix[x] for x in predictors]).t().numpy() # [[1 for _ in range(len(matrix["order"]))]] + 

x_ = sm.add_constant(inVector)
res_sm = sm.Logit(outVector, x_).fit(method="ncg", maxiter=10000) # x_ here
print(res_sm.params)
print(res_sm.summary())
print(predictors)


print("PREDICTING REAL ORDERS")
predictors = ["order"]
outVector = (torch.FloatTensor(matrix["realOrders"]) > 0).long().numpy()
inVector = torch.FloatTensor([matrix[x] for x in predictors]).t().numpy() # [[1 for _ in range(len(matrix["order"]))]] + 
x_ = sm.add_constant(inVector)
res_sm = sm.Logit(outVector, x_).fit(method="ncg", maxiter=10000) # x_ here
print(res_sm.params)
print(res_sm.summary())
print(predictors)




#X = torch.zeros(1,len(predictors)+1)
#print(X.size())
#X.requires_grad = True
#optim = torch.optim.SGD([X], lr=0.1)
#sigmoid = torch.nn.Sigmoid()
#for iteration in range(20000):
#   prediction = sigmoid((X*inVector).sum(dim=1))
#   #print(prediction)
#   loglikelihood = torch.where(outVector == 1, prediction.log(), (1-prediction).log())
#   loss = (-loglikelihood).mean()
#   optim.zero_grad()
#   loss.backward()
#   optim.step()
#   if iteration % 100 == 0:
#      print(iteration, loss)
#   #quit()
#print(X)

"""
data = read.csv("~/scr/TMP.tsv", sep="\t")
summary(lm(order ~ isRoot * objects + isRoot * subjectLength + isRoot * verbDependents + isRoot * verbLength, data=data))
summary(lm(realOrders ~ isRoot * objects + isRoot * subjectLength + isRoot * verbDependents + isRoot * verbLength, family="binomial", data=data))
summary(lm(realOrders ~ order, data=data))

KOREAN
('isRoot', 0.4019203910251941)
('verbLength', 9.15230446848022)
('verbDependents', 3.0192388265497403)
('subjectLength', 2.8978235565431123)
('objects', 0.23128491618015348)

                       Estimate Std. Error t value Pr(>|t|)    
(Intercept)            0.251686   0.017963  14.011   <2e-16 ***
isRoot                -0.481512   0.040858 -11.785   <2e-16 ***
objects               -0.371646   0.040274  -9.228   <2e-16 ***
subjectLength          0.129007   0.007998  16.130   <2e-16 ***
verbDependents         0.042010   0.018098   2.321   0.0204 *  
verbLength            -0.053384   0.005049 -10.573   <2e-16 ***
isRoot:objects         0.026194   0.081486   0.321   0.7479    
isRoot:subjectLength  -0.022024   0.015895  -1.386   0.1661    
isRoot:verbDependents -0.015293   0.037680  -0.406   0.6849    
isRoot:verbLength      0.015488   0.009879   1.568   0.1172    


CANTONESE
('isRoot', 0.4092465753025874)
('verbLength', 16.31678082034152)
('verbDependents', 5.099315068003866)
('subjectLength', 3.4195205476182506)
('objects', 0.34931506845934945)

                       Estimate Std. Error t value Pr(>|t|)   
(Intercept)            0.051976   0.057679   0.901  0.36912   
isRoot                -0.262837   0.122215  -2.151  0.03328 * 
objects               -0.173908   0.112853  -1.541  0.12564   
subjectLength          0.065903   0.023152   2.846  0.00511 **
verbDependents         0.018529   0.033380   0.555  0.57974   
verbLength            -0.015838   0.007398  -2.141  0.03407 * 
isRoot:objects         0.001394   0.233113   0.006  0.99524   
isRoot:subjectLength  -0.135547   0.044824  -3.024  0.00298 **
isRoot:verbDependents  0.053997   0.066272   0.815  0.41662   
isRoot:verbLength      0.005574   0.014130   0.394  0.69386   




OLD FRENCH
('isRoot', 0.4968541820383704)
('verbLength', 9.72748581204444)
('verbDependents', 3.0544658274862675)
('subjectLength', 3.4959906238908607)
('objects', 0.33296323707599884)

                        Estimate Std. Error t value Pr(>|t|)    
(Intercept)            0.1685602  0.0067234  25.071  < 2e-16 ***
isRoot                -0.2196769  0.0136535 -16.089  < 2e-16 ***
objects               -0.2891973  0.0147127 -19.656  < 2e-16 ***
subjectLength          0.0507058  0.0024941  20.331  < 2e-16 ***
verbDependents         0.0300897  0.0066248   4.542 5.82e-06 ***
verbLength            -0.0232864  0.0014876 -15.654  < 2e-16 ***
isRoot:objects        -0.1968695  0.0296526  -6.639 3.80e-11 ***
isRoot:subjectLength   0.0081349  0.0050632   1.607    0.108    
isRoot:verbDependents  0.0009704  0.0133811   0.073    0.942    
isRoot:verbLength     -0.0012431  0.0030392  -0.409    0.683    


FRENCH
('isRoot', 0.7063777664467938)
('verbLength', 25.28130596150633)
('verbDependents', 4.958388240794564)
('subjectLength', 6.143444838082426)
('objects', 0.4244973812744367)


                        Estimate Std. Error t value Pr(>|t|)    
(Intercept)           -0.3764815  0.0088672 -42.458  < 2e-16 ***
isRoot                -0.4716010  0.0229846 -20.518  < 2e-16 *** -- always negative
objects               -0.2582857  0.0169962 -15.197  < 2e-16 *** -- always negative
subjectLength          0.0174783  0.0015624  11.187  < 2e-16 *** -- always positive
verbDependents         0.0113472  0.0051182   2.217  0.02674 *  
verbLength            -0.0037931  0.0007849  -4.833 1.45e-06 ***
isRoot:objects         0.0006999  0.0400814   0.017  0.98607    
isRoot:subjectLength  -0.0361248  0.0041246  -8.758  < 2e-16 ***
isRoot:verbDependents  0.0343238  0.0131227   2.616  0.00898 ** 
isRoot:verbLength      0.0129477  0.0020455   6.330 3.03e-10 ***


"""
  
