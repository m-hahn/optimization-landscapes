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
parser.add_argument('--myID', type=int, default=random.randint(1000,1000000000))

args = parser.parse_args()

myID = args.myID


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

def initializeOrderTable():
   orderTable = {}
   keys = set()
   vocab = {}
   distanceSum = {}
   distanceCounts = {}
   depsVocab = set()
   for partition in ["together"]:
     for sentence in CorpusIterator(args.language,partition).iterator():
      for line in sentence:
          vocab[line["word"]] = vocab.get(line["word"], 0) + 1
          line["fine_dep"] = line["dep"]
          depsVocab.add(line["fine_dep"])
          posFine.add(line["posFine"])
          posUni.add(line["posUni"])
  
          if line["fine_dep"] == "root":
             continue
          posHere = line["posUni"]
          posHead = sentence[line["head"]-1]["posUni"]
          dep = line["fine_dep"]
          direction = "HD" if line["head"] < line["index"] else "DH"
          key = (posHead, dep, posHere)
          keyWithDir = (dep, direction)
          orderTable[keyWithDir] = orderTable.get(keyWithDir, 0) + 1
          keys.add(key)
          distanceCounts[key] = distanceCounts.get(key,0.0) + 1.0
          distanceSum[key] = distanceSum.get(key,0.0) + abs(line["index"] - line["head"])
   #print orderTable
   dhLogits = {}
   for key in keys:
      hd = orderTable.get((key, "HD"), 0) + 1.0
      dh = orderTable.get((key, "DH"), 0) + 1.0
      dhLogit = log(dh) - log(hd)
      dhLogits[key] = dhLogit
   return dhLogits, vocab, keys, depsVocab

import torch.nn as nn
import torch
from torch.autograd import Variable



import numpy.random

softmax_layer = torch.nn.Softmax()
logsoftmax = torch.nn.LogSoftmax()



direction_counts = {"DH" : 0, "HD" : 0}
direction_counts_v = {"DH" : 0, "HD" : 0}
direction_counts_obj_v = {"DH" : 0, "HD" : 0}
direction_counts_vn = {"DH" : 0, "HD" : 0}
direction_counts_vp = {"DH" : 0, "HD" : 0}
direction_counts_obj = {"DH" : 0, "HD" : 0}
direction_counts_obj_vn = {"DH" : 0, "HD" : 0}
direction_counts_obj_vp = {"DH" : 0, "HD" : 0}

direction_counts_vprop = {"DH" : 0, "HD" : 0}
direction_counts_obj_vprop = {"DH" : 0, "HD" : 0}


from collections import defaultdict

v_obj_dependents = defaultdict(int)
v_nsubj_dependents = defaultdict(int)

def orderSentence(sentence, dhLogits, printThings):
   root = None
   logits = [None]*len(sentence)
   logProbabilityGradient = 0
   for line in sentence:
      line["fine_dep"] = line["dep"]
      if line["fine_dep"] == "root":
          root = line["index"]
          continue
      if line["fine_dep"].startswith("punct"):
         continue
      key = (sentence[line["head"]-1]["posUni"], line["fine_dep"], line["posUni"]) if line["fine_dep"] != "root" else stoi_deps["root"]
      line["dependency_key"] = key
 #     dhLogit = float(dhWeights[stoi_deps[key]])
#      probability = 1/(1 + exp(-dhLogit))
      dhSampled = (line["index"] < sentence[line["head"]-1]["index"])

      direction = "DH" if dhSampled else "HD"
      if key[0] == "VERB" and key[1] == "nsubj":
         direction_counts_v[direction] += 1
      if key[0] == "VERB" and key[1] == "obj":
         direction_counts_obj_v[direction] += 1

      if key == ("VERB", "nsubj", "PROPN"):
         direction_counts_vprop[direction] += 1
      if key == ("VERB", "obj", "PROPN"):
         direction_counts_obj_vprop[direction] += 1
      if key == ("VERB", "nsubj", "PRON"):
         direction_counts_vp[direction] += 1
      if key == ("VERB", "obj", "PRON"):
         direction_counts_obj_vp[direction] += 1
      if key == ("VERB", "nsubj", "NOUN"):
         direction_counts_vn[direction] += 1
      if key == ("VERB", "obj", "NOUN"):
         direction_counts_obj_vn[direction] += 1
      if line["fine_dep"].startswith("nsubj"):
         direction_counts[direction] += 1
         v_nsubj_dependents[key[2]] += 1
      if line["fine_dep"].startswith("obj"):
         direction_counts_obj[direction] += 1
         v_obj_dependents[key[2]] += 1
      if printThings: 
         print "\t".join(map(str,["ORD", line["index"], (line["word"]+"           ")[:10], (".".join(list(key)) + "         ")[:22], line["head"], dhSampled, direction, (str(float(probability))+"      ")[:8], str(1/(1+exp(-dhLogits[key])))[:8], (str(distanceWeights[stoi_deps[key]].data.numpy())+"    ")[:8] , str(originalDistanceWeights[key])[:8]    ]  ))

      headIndex = line["head"]-1
      sentence[headIndex]["children_"+direction] = (sentence[headIndex].get("children_"+direction, []) + [line["index"]])


   return None, None


dhLogits, vocab, vocab_deps, depsVocab = initializeOrderTable()

posUni = list(posUni)
itos_pos_uni = posUni
stoi_pos_uni = dict(zip(posUni, range(len(posUni))))

posFine = list(posFine)
itos_pos_ptb = posFine
stoi_pos_ptb = dict(zip(posFine, range(len(posFine))))



itos_pure_deps = sorted(list(depsVocab)) 
stoi_pure_deps = dict(zip(itos_pure_deps, range(len(itos_pure_deps))))
   

itos_deps = sorted(vocab_deps, key=lambda x:x[1])
stoi_deps = dict(zip(itos_deps, range(len(itos_deps))))

print itos_deps



import os

#if posCount >= 8 and negCount >= 8:
#   print("Enough models!")
#   quit()

dhWeights = Variable(torch.FloatTensor([0.0] * len(itos_deps)), requires_grad=True)
distanceWeights = Variable(torch.FloatTensor([0.0] * len(itos_deps)), requires_grad=True)
for i, key in enumerate(itos_deps):
   dhLogits[key] = 0.0
   if key == "obj": 
       dhLogits[key] = (10.0 if posCount < negCount else -10.0)

   dhWeights.data[i] = dhLogits[key]

   originalDistanceWeights[key] = 0.0 #random()  
   distanceWeights.data[i] = originalDistanceWeights[key]






words = list(vocab.iteritems())
words = sorted(words, key = lambda x:x[1], reverse=True)
itos = map(lambda x:x[0], words)
stoi = dict(zip(itos, range(len(itos))))

if len(itos) > 6:
   assert stoi[itos[5]] == 5



vocab_size = 50000


word_embeddings = torch.nn.Embedding(num_embeddings = vocab_size+3, embedding_dim = 1) #.cuda()
pos_u_embeddings = torch.nn.Embedding(num_embeddings = len(posUni)+3, embedding_dim = 1) #.cuda()
pos_p_embeddings = torch.nn.Embedding(num_embeddings = len(posFine)+3, embedding_dim=1) #.cuda()


baseline = nn.Linear(3, 1) #.cuda()

dropout = nn.Dropout(0.5) #.cuda()



components = [word_embeddings, pos_u_embeddings, pos_p_embeddings, baseline] # rnn

def parameters():
 for c in components:
   for param in c.parameters():
      yield param
 yield dhWeights
 yield distanceWeights

#for pa in parameters():
#  print pa

initrange = 0.1
word_embeddings.weight.data.uniform_(-initrange, initrange)
pos_u_embeddings.weight.data.uniform_(-initrange, initrange)
pos_p_embeddings.weight.data.uniform_(-initrange, initrange)
baseline.bias.data.fill_(0)
baseline.weight.data.uniform_(-initrange, initrange)

batchSize = 1

lr_lm = 0.1


crossEntropy = 10.0

def encodeWord(w):
   return stoi[w]+3 if stoi[w] < vocab_size else 1




import torch.nn.functional


counter = 0
if True:
  corpus = CorpusIterator(args.language).iterator(rejectShortSentences = True)

  while True:
    try:
       batch = map(lambda x:next(corpus), 10*range(1))
    except StopIteration:
       break
    batch = sorted(batch, key=len)
    partitions = range(10)
    shuffle(partitions)
    for partition in partitions:
       if counter > 200000:
           print "Quitting at counter "+str(counter)
           quit()
       counter += 1
       printHere = (counter % 5000 == 0)
       current = batch[partition*1:(partition+1)*1]
       assert len(current)==1
       batchOrdered, overallLogprobSum = orderSentence(current[0], dhLogits, printHere)

DH = (direction_counts["DH"] / (0.0+direction_counts["DH"] + direction_counts["HD"]))
DH_obj = (direction_counts_obj["DH"] / (0.0+direction_counts_obj["DH"] + direction_counts_obj["HD"]))
DH_vn = (direction_counts_vn["DH"] / (0.0+direction_counts_vn["DH"] + direction_counts_vn["HD"]))
DH_obj_vn = (direction_counts_obj_vn["DH"] / (0.0+direction_counts_obj_vn["DH"] + direction_counts_obj_vn["HD"]))
DH_v = (direction_counts_v["DH"] / (0.0+direction_counts_v["DH"] + direction_counts_v["HD"]))
DH_obj_v = (direction_counts_obj_v["DH"] / (0.0+direction_counts_obj_v["DH"] + direction_counts_obj_v["HD"]))
DH_vp = (direction_counts_vp["DH"] / (0.0+direction_counts_vp["DH"] + direction_counts_vp["HD"]))
DH_obj_vp = (direction_counts_obj_vp["DH"] / (0.0+direction_counts_obj_vp["DH"] + direction_counts_obj_vp["HD"]))
DH_vprop = (direction_counts_vprop["DH"] / (0.0+direction_counts_vprop["DH"] + direction_counts_vprop["HD"]))
DH_obj_vprop = (direction_counts_obj_vprop["DH"] / (0.0+direction_counts_obj_vprop["DH"] + direction_counts_obj_vprop["HD"]))
print(direction_counts)
print(direction_counts_obj)
print(direction_counts_vn)
print(direction_counts_obj_vn)
print("all", DH*DH_obj + (1-DH) * (1-DH_obj))
print("VN", DH_vn*DH_obj_vn + (1-DH_vn) * (1-DH_obj_vn))
print("VProp", DH_vprop*DH_obj_vprop + (1-DH_vprop) * (1-DH_obj_vprop))
print("VP", DH_vp*DH_obj_vp + (1-DH_vp) * (1-DH_obj_vp))
print("V", DH_v*DH_obj_v + (1-DH_v) * (1-DH_obj_v))
with open("output/"+__file__+".tsv", "a") as outFile:
   print >> outFile, ("\t".join([str(q) for q in [args.language, args.myID, DH*DH_obj + (1-DH) * (1-DH_obj), DH_vn*DH_obj_vn + (1-DH_vn) * (1-DH_obj_vn), DH_vp*DH_obj_vp + (1-DH_vp) * (1-DH_obj_vp), DH_v*DH_obj_v + (1-DH_v) * (1-DH_obj_v), DH_vprop*DH_obj_vprop + (1-DH_vprop) * (1-DH_obj_vprop)]]))


print(v_obj_dependents, v_nsubj_dependents)
