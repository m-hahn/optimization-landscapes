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
parser.add_argument('--model', type=str, default="REAL")

args = parser.parse_args()
assert args.model == "REAL"
myID = random.randint(0,10000000)


posUni = set()
posFine = set() 
deps = ["acl", "acl:relcl", "advcl", "advmod", "amod", "appos", "aux", "auxpass", "case", "cc", "ccomp", "compound", "compound:prt", "conj", "conj:preconj", "cop", "csubj", "csubjpass", "dep", "det", "det:predet", "discourse", "dobj", "expl", "foreign", "goeswith", "iobj", "list", "mark", "mwe", "neg", "nmod", "nmod:npmod", "nmod:poss", "nmod:tmod", "nsubj", "nsubjpass", "nummod", "parataxis", "punct", "remnant", "reparandum", "root", "vocative", "xcomp"] 



from math import log, exp
from random import random, shuffle


from corpusIterator_FuncHead import CorpusIteratorFuncHead as CorpusIterator

originalDistanceWeights = {}


def makeCoarse(x):
   if ":" in x:
      return x[:x.index(":")]
   return x
import hashlib
def hash_(x):
  return hashlib.sha224(x).hexdigest()

def initializeOrderTable():
   orderTable = {}
   keys = set()
   vocab = {}
   distanceSum = {}
   distanceCounts = {}
   depsVocab = set()
   depsVocab.add("root")
   for partition in ["together"]:
     for sentence in CorpusIterator(args.language,partition).iterator():
      sentenceHash = hash_(" ".join([x["word"] for x in sentence]))
      for line in sentence:
          vocab[line["word"]] = vocab.get(line["word"], 0) + 1
          posFine.add(line["posFine"])
          posUni.add(line["posUni"])
  
          if line["dep"] == "root":
             continue
          posHere = line["posUni"]
          posHead = sentence[line["head"]-1]["posUni"]
          if line["dep"] == "nsubj":
              line["dep"] = "nsubj_"+str(sentenceHash)+"_"+str(line["index"])

          line["fine_dep"] = line["dep"]
          depsVocab.add(line["fine_dep"])


          dep = line["fine_dep"]
          direction = "HD" if line["head"] < line["index"] else "DH"
          key = dep
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


# "linearization_logprobability"
def recursivelyLinearize(sentence, position, result, gradients_from_the_left_sum):
   line = sentence[position-1]
   # Loop Invariant: these are the gradients relevant at everything starting at the left end of the domain of the current element
   allGradients = gradients_from_the_left_sum + sum(line.get("children_decisions_logprobs",[]))

#   if "linearization_logprobability" in line:
#      allGradients += line["linearization_logprobability"] # the linearization of this element relative to its siblings affects everything starting at the start of the constituent, but nothing to the left of it
#   else:
#      assert line["fine_dep"] == "root"
#

   # there are the gradients of its children
   if "children_DH" in line:
      for child in line["children_DH"]:
         allGradients = recursivelyLinearize(sentence, child, result, allGradients)
   result.append(line)
   if "children_HD" in line:
      for child in line["children_HD"]:
         allGradients = recursivelyLinearize(sentence, child, result, allGradients)
   return allGradients

import numpy.random

softmax_layer = torch.nn.Softmax()
logsoftmax = torch.nn.LogSoftmax()



def orderChildrenRelative(sentence, remainingChildren, reverseSoftmax, orderKeys):
       childrenLinearized = []
       relevantSubject = None
       while len(remainingChildren) > 0:
           selected = 0 #numpy.random.choice(range(0, len(remainingChildren)), p=softmax.data.numpy())
           if sentence[remainingChildren[selected]-1]["dependency_key"] == orderKeys["subject"]:
             relevantSubject = remainingChildren[selected]
           else:
              childrenLinearized.append(remainingChildren[selected])
           del remainingChildren[selected]
       if relevantSubject is not None:
          childrenLinearized.insert(orderKeys["key"] % (len(childrenLinearized)+1), relevantSubject)
       return childrenLinearized           



def orderSentence(sentence, dhLogits, printThings, orderKeys):
   root = None
   logits = [None]*len(sentence)
   logProbabilityGradient = 0
   sentenceHash = hash_(" ".join([x["word"] for x in sentence]))


   for line in sentence:
         line["children_DH"] = []
         line["children_HD"] = []



   for line in sentence:
      line["fine_dep"] = line["dep"]
      if line["fine_dep"] == "root":
          root = line["index"]
          continue
      if line["fine_dep"].startswith("punct"):
         continue
      posHead = sentence[line["head"]-1]["posUni"]
      posHere = line["posUni"]
      if line["dep"] == "nsubj":
         line["dep"] = "nsubj_"+str(sentenceHash)+"_"+str(line["index"])
      line["fine_dep"] = line["dep"]
     
      key = line["fine_dep"] if line["fine_dep"] != "root" else stoi_deps["root"]
      line["dependency_key"] = key
      dhLogit = dhWeights[stoi_deps[key]]
      probability = 1/(1 + torch.exp(-dhLogit))
      if key == orderKeys["subject"]:
          dhSampled = True if orderKeys["order"]== 1 else False
      else:
         dhSampled = (line["index"] < line["head"])

      direction = "DH" if dhSampled else "HD"
      if printThings: 
         print "\t".join(map(str,["ORD", line["index"], (line["word"]+"           ")[:10], (".".join(list(key)) + "         ")[:22], line["head"], dhSampled, direction, (str(float(probability))+"      ")[:8], str(1/(1+exp(-dhLogits[key])))[:8], (str(distanceWeights[stoi_deps[key]].data.numpy())+"    ")[:8] , str(originalDistanceWeights[key])[:8]    ]  ))

      headIndex = line["head"]-1
      sentence[headIndex]["children_"+direction] = (sentence[headIndex].get("children_"+direction, []) + [line["index"]])



   for line in sentence:
      if "children_DH" in line:
         childrenLinearized = orderChildrenRelative(sentence, line["children_DH"][:], False, orderKeys)
         line["children_DH"] = childrenLinearized
      if "children_HD" in line:
         childrenLinearized = orderChildrenRelative(sentence, line["children_HD"][:], True, orderKeys)
         line["children_HD"] = childrenLinearized

   
   linearized = []
   overallLogprobSum = recursivelyLinearize(sentence, root, linearized, Variable(torch.FloatTensor([0.0])))
   if printThings or len(linearized) == 0:
     print " ".join(map(lambda x:x["word"], sentence))
     print " ".join(map(lambda x:x["word"], linearized))


   # store new dependency links
   moved = [None] * len(sentence)
   for i, x in enumerate(linearized):
      moved[x["index"]-1] = i
   for i,x in enumerate(linearized):
      if x["head"] == 0: # root
         x["reordered_head"] = 0
      else:
         x["reordered_head"] = 1+moved[x["head"]-1]
   return linearized, overallLogprobSum


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

#print itos_deps



import os

dhWeights = Variable(torch.FloatTensor([0.0] * len(itos_deps)), requires_grad=True)
distanceWeights = Variable(torch.FloatTensor([0.0] * len(itos_deps)), requires_grad=True)
for i, key in enumerate(itos_deps):
   dhLogits[key] = 0.0
   originalDistanceWeights[key] = 0.0 #random()  




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


def getDependencyLength(batchOrdered):
       batchOrdered = [batchOrdered]
   
       lengths = map(len, current)
       maxLength = lengths[-1]
       loss = 0
       wordNum = 0
       lossWords = 0

       depLengthTotal = 0
       if True:
           for i in range(1,len(batchOrdered[0])+1): 
                    if batchOrdered[0][i-1]["fine_dep"] == "root":
                       continue
                    realHead = batchOrdered[0][i-1]["reordered_head"] 
                    # to make sure reward attribution considers this correctly
                    depLength = abs(i - realHead)
                    depLengthTotal += depLength
       #             print(batchOrdered[0][i-1], depLength, depLengthTotal)
                    assert depLength >= 1
       return depLengthTotal

from collections import defaultdict
subjectsPerSentence = defaultdict(list)
for dep in stoi_deps:
   if dep.startswith("nsubj_"):
       _, sentHash, _ = dep.split("_")
       subjectsPerSentence[sentHash].append(dep)

def sd(x):
    x = torch.FloatTensor(x)
    return (x.pow(2).mean() - x.mean().pow(2)).sqrt()
from math import sqrt
counter = 0

PATH = "/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_perSent_perOcc_coarse_funchead_SUBJ_DLM/"+__file__+"_"+args.language+"_"+str(args.model)
import os
if os.path.exists(PATH):
   quit()
with open(PATH, "w") as outFile:
  corpus = list(CorpusIterator(args.language, partition="together").iterator(rejectShortSentences = True))
  shuffle(corpus)

  for sentence in corpus:
       if counter > 200000:
           print "Quitting at counter "+str(counter)
           quit()
       counter += 1
       printHere = (counter % 500 == 0)
       current = [sentence]
       assert len(current)==1
       if len(sentence) <= 2:
          print("Skipping short sentence")
       sentenceHash = hash_(" ".join([x["word"] for x in sentence]))
       subjects = subjectsPerSentence[sentenceHash]
       batchOrdered, overallLogprobSum = orderSentence(current[0], dhLogits, printHere, {"subject" : "NONE", "order" : "NONE", "key" : "NONE"})
       depLengthReal = getDependencyLength(batchOrdered)
       for subject in subjects:
         print("SUBJECT", subject, counter/float(len(corpus)))
         bestLengthsPerOrder = {-1 : None, 1 : None}
         lengthsPerOrder = {-1 : None, 1 : None}
         for order in [-1, 1]:
           best = len(sentence) * len(sentence)
           depLengths = []
           print("    ORDER", order)
           for key in range(10):
               batchOrdered, overallLogprobSum = orderSentence(current[0], dhLogits, printHere, {"subject" : subject, "order" : order, "key" : key})
               depLength = getDependencyLength(batchOrdered)
               best = min(best, depLength)
               depLengths.append(depLength)
           print("          Dependency length", best, sum(depLengths)/(0.001+len(depLengths)), sd(depLengths)/sqrt(100))
           bestLengthsPerOrder[order] = best
           lengthsPerOrder[order] = sum(depLengths)/(0.001+len(depLengths))
         print >> outFile, subject +"\t"+str(lengthsPerOrder[1] - lengthsPerOrder[-1]) +"\t"+str(bestLengthsPerOrder[1] - bestLengthsPerOrder[-1]) + "\t"+ str(bestLengthsPerOrder[1]) + "\t" + str(lengthsPerOrder[1]) + "\t"+ str(depLengthReal)
