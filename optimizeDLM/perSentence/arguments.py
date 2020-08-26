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

TARGET_DIR = "/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_funchead_perSent/"
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
matrix["SO"] = []
matrix["S"] = []
matrix["O"] = []
matrix["SON"] = []
matrix["SN"] = []
matrix["ON"] = []

def mean(x):
   return sum(x)/(len(x)+1e-10)
for x in sentenceToHash:
 #   print(x)
    order = x[1]
    sent = hashToSentence[x[0]]
    annotateChildren(sent)
    for word in sent:
#       print(word)
       if word["posUni"] == "VERB":
          hasSubjectN = False
          hasObjectN = False
          hasSubject = False
          hasObject = False
          for child_ in word.get("children", []):
              child = sent[child_-1]
              if child["posUni"] == "NOUN" or True:
                if child["dep"].startswith("nsubj"):
                   hasSubject = True
                elif child["dep"].startswith("obj"):
                   hasObject = True
              if child["posUni"] == "NOUN":
                if child["dep"].startswith("nsubj"):
                   hasSubjectN = True
                elif child["dep"].startswith("obj"):
                   hasObjectN = True
          if hasSubject or hasObject:
              matrix["S"].append(1 if (hasSubject and not hasObject) else 0)
              matrix["O"].append(1 if (not hasSubject and hasObject) else 0)
              matrix["SO"].append(1 if (hasSubject and hasObject) else 0)
              matrix["SN"].append(1 if (hasSubjectN and not hasObjectN) else 0)
              matrix["ON"].append(1 if (not hasSubjectN and hasObjectN) else 0)
              matrix["SON"].append(1 if (hasSubjectN and hasObjectN) else 0)
columns = ["S", "O", "SO", "SN", "ON", "SON"]
print(columns)
total = 1 #sum(matrix["S"]) + sum(matrix["O"]) + sum(matrix["SO"]) + 1e-5
with open("outputs/"+__file__+".tsv", "a") as outFile:
   print >> outFile, "\t".join([args.language] + [str(sum(matrix[x])/total) for x in columns])
   print "\t".join([args.language] + [str(sum(matrix[x])/total) for x in columns])

