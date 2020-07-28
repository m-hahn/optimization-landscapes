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
parser.add_argument('--model', type=int)

args = parser.parse_args()

myID = random.randint(0,10000000)


posUni = set()
posFine = set() 
deps = ["acl", "acl:relcl", "advcl", "advmod", "amod", "appos", "aux", "auxpass", "case", "cc", "ccomp", "compound", "compound:prt", "conj", "conj:preconj", "cop", "csubj", "csubjpass", "dep", "det", "det:predet", "discourse", "dobj", "expl", "foreign", "goeswith", "iobj", "list", "mark", "mwe", "neg", "nmod", "nmod:npmod", "nmod:poss", "nmod:tmod", "nsubj", "nsubjpass", "nummod", "parataxis", "punct", "remnant", "reparandum", "root", "vocative", "xcomp"] 



PATH = "/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_perSent_perOcc_coarse_funchead_SUBJ_DLM/"+__file__+"_"+args.language+"_"+str(args.model)
import os
#if os.path.exists(PATH):
#   print("Exists")
#   quit()


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
          if line["dep"] == "obj":
              line["dep"] = "obj_"+str(sentenceHash)+"_"+str(line["index"])

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

import scipy.special
import numpy as np
def orderChildrenRelative(sentence, remainingChildren, reverseSoftmax, orderKeys):
       childrenLinearized = []
       relevantSubjects = []
       while len(remainingChildren) > 0:
           logits = np.array([float(distanceWeights[stoi_deps[sentence[x-1]["dependency_key"]]]) for x in remainingChildren])
           softmax = scipy.special.softmax(logits)
           selected = numpy.random.choice(range(0, len(remainingChildren)), p=softmax)
           if sentence[remainingChildren[selected]-1]["dependency_key"] in orderKeys["keys"]:
             relevantSubjects.append(remainingChildren[selected])
           else:
              childrenLinearized.append(remainingChildren[selected])
           del remainingChildren[selected]
       if reverseSoftmax:
           childrenLinearized = childrenLinearized[::-1]
       if False and len(childrenLinearized) == 0 and len(relevantSubjects) == 1:
           return relevantSubjects
       elif len(relevantSubjects) > 0:
          print(remainingChildren)
          print(relevantSubjects)
          print(orderKeys["relative"])
          # find direction where the head is
          print(sentence[relevantSubjects[0]-1]["dependency_key"])
          directionHere = sentence[relevantSubjects[0]-1]["DirectionDecision"]
          lengths_Other = [sentence[x-1]["length"] for x in childrenLinearized]
          lengths_Arguments = [sentence[x-1]["length"] for x in relevantSubjects]
          print(lengths_Other, lengths_Arguments)
          sideLengths_Other = [sum([y["length"] for y in sentence[x-1]["children_"+("HD" if directionHere == "DH" else "DH")]]) for x in childrenLinearized]
          sideLengths_Arguments = [sum([y["length"] for y in sentence[x-1]["children_"+("HD" if directionHere == "DH" else "DH")]]) for x in relevantSubjects]
          print(sideLengths_Other, sideLengths_Arguments)
          quit()
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
      if line["dep"] == "obj":
         line["dep"] = "obj_"+str(sentenceHash)+"_"+str(line["index"])
      line["fine_dep"] = line["dep"]
     
      key = line["fine_dep"] if line["fine_dep"] != "root" else stoi_deps["root"]
      line["dependency_key"] = key
      dhLogit = float(dhWeights[stoi_deps[key]])
      probability = 1/(1 + exp(-dhLogit))
      try:
         argument_index = orderKeys["keys"].index(key)
         dhSampled = True if orderKeys["orders"][argument_index]== 1 else False
      except ValueError:
         dhSampled = (random() < probability)
     
      direction = "DH" if dhSampled else "HD"
      line["DirectionDecision"] = direction
      if printThings: 
         print "\t".join(map(str,["ORD", line["index"], (line["word"]+"           ")[:10], (".".join(list(key)) + "         ")[:22], line["head"], dhSampled, direction, (str(float(probability))+"      ")[:8], str(1/(1+exp(-dhLogits[key])))[:8], (str(distanceWeights[stoi_deps[key]])+"    ")[:8] , str(originalDistanceWeights[key])[:8]    ]  ))

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
      x["reordered_index"] = i+1
   for i,x in enumerate(linearized):
      if x["head"] == 0: # root
         x["reordered_head"] = 0
      else:
         x["reordered_head"] = 1+moved[x["head"]-1]
   for x in linearized:
       annotateLength(x, sentence)
   return linearized, overallLogprobSum


def annotateLength(x, sentence):
   if "length" in x:
       return x["length"]
   length = 1
   for y in x.get("children_DH", []):
      length += annotateLength(sentence[y-1], sentence)
   for y in x.get("children_HD", []):
      length += annotateLength(sentence[y-1], sentence)
   x["length"] = length
   return length

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

dhWeights = [0.0] * len(itos_deps)
distanceWeights = [0.0] * len(itos_deps)
for i, key in enumerate(itos_deps):
   dhLogits[key] = 0.0
   originalDistanceWeights[key] = 0.0 #random()  


__file__Optimize = "optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead.py"
TARGET_DIR = "/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_perSent_perOcc_coarse_funchead/"
print "Saving"
with open(TARGET_DIR+"/"+args.language+"_"+__file__Optimize+"_model_"+str(args.model)+".tsv", "r") as inFile:
   next(inFile)
   for line in inFile:
      dhWeight, dep, distanceWeight, language, model = line.strip().split("\t")
      if dep == "obj":
        continue
      dhWeights[stoi_deps[dep]] = float(dhWeight)
      distanceWeights[stoi_deps[dep]] = float(distanceWeight)





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
                    assert realHead > 0, realHead
                    assert depLength >= 1
       return depLengthTotal

from collections import defaultdict
subjectsPerSentence = defaultdict(list)
for dep in stoi_deps:
   if dep.startswith("nsubj_") or dep.startswith("obj_"):
       _, sentHash, _ = dep.split("_")
       subjectsPerSentence[sentHash].append(dep)

def sd(x):
    x = torch.FloatTensor(x)
    return (x.pow(2).mean() - x.mean().pow(2)).sqrt()
from math import sqrt
counter = 0




def detectOrder(subject, verb, objects):
    subject = subject["reordered_index"]
    verb = verb["reordered_index"]
    objects = [x["reordered_index"] for x in objects]
    assert verb != subject
    assert (all([y != verb for y in objects]))
    assert (all([y != subject for y in objects]))

    objects = [(y, "O") for y in objects]
    elements = objects + [(subject, "S"), (verb, "V")]
    elements.sort()
    order = "".join([y[1] for y in elements])
    while "OO" in order:
       order = order.replace("OO", "O")
    #print(order)
    return order
#    quit()

def mean(x):
   return sum(x)/(len(x)+0.001)


def product(l, power):
    if power == 0:
       return [[]]
    r = product(l, power-1)
    r2 = []
    for x in l:
       for s in r:
         r2.append([x] + s)
    return r2

with open(PATH, "w") as outFile:
  corpus = list(CorpusIterator(args.language, partition="together").iterator(rejectShortSentences = True))
  shuffle(corpus)

  best1 = {1 : [], -1 : []}
  mean1 = {1: [], -1 : []}
  real1 = []
  realOrder1 = []
  for sentence in corpus:
       if counter > 200000:
           print "Quitting at counter "+str(counter)
           quit()
       counter += 1
       if counter % 100 == 0:
          print(counter, (counter+0.0001)/len(corpus))
       printHere = (counter % 500 == 0)
       current = [sentence]
       assert len(current)==1
   #    if len(sentence) <= 2:
    #      print("Skipping short sentence")
       sentenceHash = hash_(" ".join([x["word"] for x in sentence]))
       subjects = subjectsPerSentence[sentenceHash]
       batchOrdered, overallLogprobSum = orderSentence(current[0], dhLogits, printHere, {"verb" : "NONE", "dependents" : [], "orders" : [], "relative" : "NONE", "keys" : []})
       depLengthReal = getDependencyLength(batchOrdered)
       arguments = [x for x in current[0] if (x["dep"].startswith("nsubj") or x["dep"].startswith("obj")) and "reordered_index" in x]
       print(arguments)
       print(subjects)
       verbs = {y : [] for y in set([x["head"] for x in arguments])}
       for a in arguments:
            verbs[a["head"]].append(a)
       print(verbs)
       
       for verb in verbs:
         #realOrderType = detectOrder(current[0][verb-1], verbs[verb])
         bestLengthsPerOrder = {-1 : None, 1 : None}
         lengthsPerOrder = {-1 : None, 1 : None}
         bestResult = {-1 : None, 1 : None}
         lengthsPerType = defaultdict(list)
         print(len(verbs[verb]))
         orders_ = product([-1, 1], len(verbs[verb]))
         print(orders_)
         for orders in orders_:
           best = len(sentence) * len(sentence)
           depLengths = []
           for relative in ["SO", "OS"]:
               batchOrdered, overallLogprobSum = orderSentence(current[0], dhLogits, printHere, {"verb" : verb, "dependents" : verbs[verb], "orders" : orders, "relative" : relative, "keys" : [x["dep"] for x in verbs[verb]]})
               depLength = getDependencyLength(batchOrdered)
               lengthsPerType[detectOrder(subjectItem, verbObject, objectItems)].append(depLength)
               if depLength < best:
                 bestResult[order] = " ".join([x["word"] for x in batchOrdered])
               best = min(best, depLength)
               depLengths.append(depLength)
#           print("          Dependency length", best, sum(depLengths)/(0.001+len(depLengths)), sd(depLengths)/sqrt(100))
           bestLengthsPerOrder[order] = best
           lengthsPerOrder[order] = sum(depLengths)/(0.001+len(depLengths))
         bestLengthsPerType = {x : min(y) for x, y in lengthsPerType.iteritems()}
#         print(bestLengthsPerType)
         best1[1].append(bestLengthsPerOrder[1])
         mean1[1].append(lengthsPerOrder[1])
         best1[-1].append(bestLengthsPerOrder[-1])
         mean1[-1].append(lengthsPerOrder[-1])
         real1.append(depLengthReal)
         realOrder1.append(realOrder)
         print >> outFile, subject +"\t"+str(depLengthReal) + "\t" + str("Real_"+realOrderType)
         for x, y in bestLengthsPerType.iteritems():
            print >> outFile, subject +"\t"+str(y) + "\t" + str(x)

#       if counter % 10 == 0:
 #          print(mean(best1[1]), mean(best1[-1]), mean(mean1[1]), mean(mean1[-1]), mean(real1), mean(realOrder1), mean([1 if x < y else (0 if x == y else -1) for x, y in zip(best1[1], best1[-1])]))

