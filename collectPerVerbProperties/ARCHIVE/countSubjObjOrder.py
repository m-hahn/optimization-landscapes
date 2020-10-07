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

   if "linearization_logprobability" in line:
      allGradients += line["linearization_logprobability"] # the linearization of this element relative to its siblings affects everything starting at the start of the constituent, but nothing to the left of it
   else:
      assert line["fine_dep"] == "root"


   # there are the gradients of its children
   if "children_DH" in line:
      for child in line["children_DH"]:
         allGradients = recursivelyLinearize(sentence, child, result, allGradients)
   result.append(line)
   line["relevant_logprob_sum"] = allGradients
   if "children_HD" in line:
      for child in line["children_HD"]:
         allGradients = recursivelyLinearize(sentence, child, result, allGradients)
   return allGradients

import numpy.random

softmax_layer = torch.nn.Softmax()
logsoftmax = torch.nn.LogSoftmax()



def orderChildrenRelative(sentence, remainingChildren, reverseSoftmax):
       childrenLinearized = []
       while len(remainingChildren) > 0:
           logits = torch.cat([distanceWeights[stoi_deps[sentence[x-1]["dependency_key"]]].view(1) for x in remainingChildren])
           softmax = softmax_layer(logits.view(1,-1)).view(-1)
           selected = numpy.random.choice(range(0, len(remainingChildren)), p=softmax.data.numpy())
           log_probability = torch.log(softmax[selected])
           assert "linearization_logprobability" not in sentence[remainingChildren[selected]-1]
           sentence[remainingChildren[selected]-1]["linearization_logprobability"] = log_probability
           childrenLinearized.append(remainingChildren[selected])
           del remainingChildren[selected]
       if reverseSoftmax:
           childrenLinearized = childrenLinearized[::-1]
       return childrenLinearized           



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
      dhLogit = dhWeights[stoi_deps[key]]
      probability = 1/(1 + torch.exp(-dhLogit))
      dhSampled = (random() < probability.data.numpy())
      line["ordering_decision_log_probability"] = torch.log(1/(1 + torch.exp(- (1 if dhSampled else -1) * dhLogit)))

      direction = "DH" if dhSampled else "HD"
      headIndex = line["head"]-1
      sentence[headIndex]["children_"+direction] = (sentence[headIndex].get("children_"+direction, []) + [line["index"]])
      sentence[headIndex]["children_decisions_logprobs"] = (sentence[headIndex].get("children_decisions_logprobs", []) + [line["ordering_decision_log_probability"]])



   for line in sentence:
      if "children_DH" in line:
         childrenLinearized = orderChildrenRelative(sentence, line["children_DH"][:], False)
         line["children_DH"] = childrenLinearized
      if "children_HD" in line:
         childrenLinearized = orderChildrenRelative(sentence, line["children_HD"][:], True)
         line["children_HD"] = childrenLinearized

   
   linearized = []
   recursivelyLinearize(sentence, root, linearized, Variable(torch.FloatTensor([0.0])))

   # store new dependency links
   moved = [None] * len(sentence)
   for i, x in enumerate(linearized):
      moved[x["index"]-1] = i
   for i,x in enumerate(linearized):
      if x["head"] == 0: # root
         x["reordered_head"] = 0
      else:
         x["reordered_head"] = 1+moved[x["head"]-1]
   return linearized, logits


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
MIXED, SAME, OPPOSITE = 0,0,0
corpus = CorpusIterator(args.language).iterator(rejectShortSentences = True)
for sentence in corpus:
      for line in sentence:
         if line["dep"] == "root":
            continue
         head = sentence[line["head"]-1]
         head["dependents"] = head.get("dependents", []) + [line]
      for line in sentence:
        if "dependents" in line and line["posUni"] == "VERB":
            subjects = [x for x in line["dependents"] if x["dep"] == "nsubj" and x["posUni"] == "NOUN"]
            objects = [x for x in line["dependents"] if x["dep"] == "obj" and x["posUni"] == "NOUN"]
            if len(subjects) > 0 and len(objects) > 0:
               subjects = list(set([x["index"] > line["index"] for x in subjects]))
               objects = list(set([x["index"] > line["index"] for x in objects]))
               if len(subjects) > 1:
                  continue
               if len(objects) > 1:
                  MIXED += 1
               elif objects[0] == subjects[0]:
                  SAME += 1
               else:
                  OPPOSITE += 1
print(args.language + "\t" + str( MIXED) + "\t" +str(SAME) + "\t" + str( OPPOSITE))
