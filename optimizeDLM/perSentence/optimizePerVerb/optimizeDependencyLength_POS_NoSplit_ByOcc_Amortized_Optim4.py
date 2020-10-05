# Optimizing a grammar for dependency length minimization

import random
import sys

objectiveName = "DepL"

import argparse

parser = argparse.ArgumentParser()

parser.add_argument('--language', type=str)
parser.add_argument('--entropy_weight', type=float, default=0.001)
parser.add_argument('--lr_grammar', type=float, default=0.01) #random.choice([0.000001, 0.00001, 0.00002, 0.0001, 0.001, 0.01]))
parser.add_argument('--momentum_grammar', type=float, default=0.8) #random.choice([0.0, 0.2, 0.8, 0.9]))
parser.add_argument('--lr_amortized', type=float, default=random.choice([0.000001, 0.00001, 0.00002, 0.0001, 0.001, 0.01]))
parser.add_argument('--momentum_amortized', type=float, default=random.choice([0.0, 0.2, 0.8, 0.9]))

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
#          if line["dep"] == "nsubj" and posHere == "NOUN" and posHead == "VERB":
 #             line["dep"] = "nsubj_"+str(sentenceHash)+"_"+str(line["index"])

          line["fine_dep"] = line["dep"]
          depsVocab.add(line["fine_dep"])


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


# "linearization_logprobability"
def recursivelyLinearize(sentence, position, result, batch):
   line = sentence[position-1]
   if "children_DH" in line:
      for child in line["children_DH"][batch]:
         recursivelyLinearize(sentence, child, result, batch)
   result.append(line)
   if "children_HD" in line:
      for child in line["children_HD"][batch]:
         recursivelyLinearize(sentence, child, result, batch)

import numpy.random

softmax_layer = torch.nn.Softmax(dim=1)
logsoftmax = torch.nn.LogSoftmax(dim=1)



def orderChildrenRelative(sentence, remainingChildren, reverseSoftmax, wordToDistanceLogits):
       if max([len(x) for x in remainingChildren]) <= 1:
            return remainingChildren, []
          
  #     print(remainingChildren)
       children = sorted(list(set(flatten(remainingChildren))))
 #      if len(children) == 1:
#           return remainingChildren, []
          
       stoi_children = dict(list(zip(children, range(len(children)))))
       childrenLinearized = [[] for _ in range(BATCH_SIZE)]
       if len(children) == 0:
         return childrenLinearized, []
  #     print(children)
       mask = torch.FloatTensor([[0 if child in remainingChildren[i] else -100000000000 for child in children] for i in range(BATCH_SIZE)])
 #      print(mask)
       logits = torch.cat([distanceWeights[stoi_deps[sentence[x-1]["dependency_key"]]].view(1) if x not in wordToDistanceLogits else wordToDistanceLogits[x].view(1) for x in children])
#       print(logits)
       log_probabilities = []
       #print(children)
       #print("============")
       #print(remainingChildren)
       for _ in range(len(children)):
           #print("MASK")
           #print(mask)
           masked_logits = logits.unsqueeze(0) + mask
           softmax = softmax_layer(masked_logits)
           distrib = torch.distributions.categorical.Categorical(probs=softmax)
           selected = distrib.sample()
           log_probability = distrib.log_prob(selected)
           stillHasOpen = (mask.max(dim=1)[0] > -1)
       #    print(stillHasOpen)
           log_probability = log_probability * stillHasOpen.float()
           #print(log_probability)
           log_probabilities.append(log_probability)
           selected_ = selected.cpu()
           mask_ = mask.cpu()
           for i in range(BATCH_SIZE):
             if mask_[i][selected_[i].item()] > -1:
        #       print(children)
         #      print(selected_[i])
               childrenLinearized[i].append(children[selected_[i].item()])
               mask_[i][selected_[i].item()] = -100000000000
           mask = mask_
       if reverseSoftmax:
        for i in range(BATCH_SIZE):
           childrenLinearized[i] = childrenLinearized[i][::-1]
       #print("---")
       #print(children)
       #print(childrenLinearized)
       #print(remainingChildren)
       return childrenLinearized, log_probabilities

def annotateLength(x):
    if "length" not in x:
       length = 0
       for y in x.get("children", []):
          length += annotateLength(y)
       x["length"] = length+1
    return x["length"]

def flatten(y):
    r = []
    for x in y:
      for z in x:
        r.append(z)
    return r

itos_encodings_ = {}
def itos_encodings(x):
   if x not in itos_encodings_:
      itos_encodings_[x] = len(itos_encodings_)
   return itos_encodings_[x]


BATCH_SIZE=12

def orderSentence(sentence, dhLogits, printThings):
   root = None
   logits = [None]*len(sentence)
   logProbabilityGradient = 0
   sentenceHash = hash_(" ".join([x["word"] for x in sentence]))
   assert "children_decisions_logprobs" not in sentence[0]
   if "children" not in sentence[0]:
     sentence[0]["children"] = []
     for line in sentence:
       if line["dep"] == "root":
          root = line["index"]
          continue
       if line["dep"].startswith("punct"):
          continue
       headIndex = line["head"]-1
       sentence[headIndex]["children"] = (sentence[headIndex].get("children", []) + [line])
     for line in sentence:
        annotateLength(line)
      
   subjects_or_objects = [x for x in sentence if x["dep"] in ["nsubj"]]
   if len(subjects_or_objects) > 0:
     encodings = [[x["dep"], x["posUni"], x["length"]] + ["@"+str(z) for z in flatten(sorted([(y["dep"], y["posUni"], y["length"]) for y in sentence[x["head"]-1]["children"]]))] for x in subjects_or_objects]
     maxLength = max([len(x) for x in encodings])
     encodings = [x + ["PAD" for _ in range(maxLength-len(x))] for x in encodings]
  
     numerified = [[itos_encodings(x) for x in y] for y in encodings]
     embedded = amortized_embeddings(torch.LongTensor(numerified))
#     print(embedded)
 #    print(embedded.size())
     convolved = amortized_conv(embedded.transpose(1,2))
  #   print(convolved.size())
     pooled = convolved.max(dim=2)[0]
     decision_logits = amortized_out(pooled)
     if random() < 0.05:
        print("LOGITS FROM MODEL", decision_logits)
     wordToDecisionLogits = {subjects_or_objects[i]["index"] : decision_logits[i,0] for i in range(len(subjects_or_objects))}
     wordToDistanceLogits = {subjects_or_objects[i]["index"] : decision_logits[i,1] for i in range(len(subjects_or_objects))}
   else:
     wordToDecisionLogits = {}
     wordToDistanceLogits = {}
   log_probabilities = []
   for line in sentence:
      for direction in ["DH", "HD"]:
            line["children_"+direction] = [[] for _ in range(BATCH_SIZE)]

   for line in sentence:
      line["fine_dep"] = line["dep"]
      if line["fine_dep"] == "root":
          root = line["index"]
          continue
      if line["fine_dep"].startswith("punct"):
         continue
      posHead = sentence[line["head"]-1]["posUni"]
      posHere = line["posUni"]
#      if line["dep"] == "nsubj" and posHead == "VERB" and posHere == "NOUN":
 #        line["dep"] = "nsubj_"+str(sentenceHash)+"_"+str(line["index"])
      line["fine_dep"] = line["dep"]
     
      key = (posHead, line["fine_dep"], posHere) if line["fine_dep"] != "root" else stoi_deps["root"]
      line["dependency_key"] = key
      if line["index"] in wordToDecisionLogits:
        dhLogit = wordToDecisionLogits[line["index"]]
      else:
        dhLogit = dhWeights[stoi_deps[key]]
      probability = 1/(1 + torch.exp(-dhLogit))
      dhSampled = torch.FloatTensor([1 if (random() < probability.data.numpy()) else 0 for _ in range(BATCH_SIZE)])
      log_probabilities.append(torch.log(1/(1 + torch.exp(- (2*dhSampled-1.0) * dhLogit))))
      #print(dhSampled)
      #print(log_probabilities[-1])
      if printThings: 
         print "\t".join(map(str,["ORD", line["index"], (line["word"]+"           ")[:10], (".".join(list(key)) + "         ")[:22], line["head"], str(round(float(dhSampled[0]),4)), (str(float(probability[0]))+"      ")[:8], (str(distanceWeights[stoi_deps[key]].data.numpy())+"    ")[:8]  ]  ))

      headIndex = line["head"]-1
      for i in range(BATCH_SIZE):
         direction = "DH" if float(dhSampled[i]) > 0.5 else "HD"
         sentence[headIndex]["children_"+direction][i].append(line["index"])


   
   for line in sentence:
      lengths = [len(line["children_DH"][i])+len(line["children_HD"][i]) for i in range(BATCH_SIZE)]
      assert min(lengths) == max(lengths)
      lengthsBefore = min(lengths)
      if len(line["children_DH"]) > 0:
         childrenLinearized, relativeOrderLogprobs = orderChildrenRelative(sentence, line["children_DH"], False, wordToDistanceLogits)
         log_probabilities += relativeOrderLogprobs
         line["children_DH"] = childrenLinearized
      if len(line["children_HD"]) > 0:
         childrenLinearized, relativeOrderLogprobs = orderChildrenRelative(sentence, line["children_HD"], True, wordToDistanceLogits)
         log_probabilities += relativeOrderLogprobs
         line["children_HD"] = childrenLinearized
      lengths = [len(line["children_DH"][i])+len(line["children_HD"][i]) for i in range(BATCH_SIZE)]
      assert lengthsBefore >= min(lengths)
      assert min(lengths) == max(lengths)
      assert lengthsBefore == min(lengths)
  
   linearized = [[] for _ in range(BATCH_SIZE)]
   for i in range(BATCH_SIZE):
      recursivelyLinearize(sentence, root, linearized[i], i)
   if printThings or len(linearized[0]) == 0:
     print " ".join(map(lambda x:x["word"], sentence))
     print " ".join(map(lambda x:x["word"], linearized[0]))
     print " ".join(map(lambda x:x["word"], linearized[1]))
     print " ".join(map(lambda x:x["word"], linearized[2]))
   assert min([len(x) for x in linearized]) == max([len(x) for x in linearized])

   # store new dependency links
   dependencyLengths = [0 for _ in range(BATCH_SIZE)]
   for batch in range(BATCH_SIZE):
     moved = [None] * len(sentence)
     for i, x in enumerate(linearized[batch]):
        moved[x["index"]-1] = i
     for i,x in enumerate(linearized[batch]):
        if x["head"] == 0: # root
           x["reordered_head"] = 0
        else:
          dependencyLengths[batch] += abs(moved[x["head"]-1] - i)
          assert moved[x["head"]-1] != i
   if printThings:
      print(dependencyLengths)
#          x["reordered_head"] = 1+moved[x["head"]-1]
#   if True:  
 #    print " ".join(map(lambda x:x["word"], sentence))
  #   print " ".join(map(lambda x:x["word"], linearized[0]))
   #  print " ".join(map(lambda x:x["word"], linearized[1]))

   if len(linearized[0]) == 1:
        return None, None
 
#   print(log_probabilities)
   return dependencyLengths, torch.stack(log_probabilities, dim=1).sum(dim=1)


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


relevantPath = "/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_funchead_perSent_perOcc/"

import os

dhWeights = Variable(torch.FloatTensor([0.0] * len(itos_deps)), requires_grad=True)
distanceWeights = Variable(torch.FloatTensor([0.0] * len(itos_deps)), requires_grad=True)
hasFoundKey = False
for i, key in enumerate(itos_deps):
   dhLogits[key] = 0.0
   if key == ("VERB", "obj", "NOUN"):
       dhLogits[key] = (10.0 if random() < 0.5 else -10.0)
       hasFoundKey = True
   dhWeights.data[i] = dhLogits[key]
   originalDistanceWeights[key] = 0.0 #random()  
   distanceWeights.data[i] = originalDistanceWeights[key]
assert hasFoundKey, itos_deps
assert abs(float(dhWeights.data.sum())) == 10, dhWeights.data.sum()


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


amortized_embeddings = torch.nn.Embedding(300, 200)
amortized_conv = torch.nn.Conv1d(in_channels=200, out_channels=300, kernel_size=3)
amortized_conv.weight.data.zero_()

amortized_out = torch.nn.Linear(300, 2, bias=False)
relu = torch.nn.ReLU()
amortized_out.weight.data.zero_()

components_baseline = [word_embeddings, pos_u_embeddings, pos_p_embeddings, baseline] # rnn
components_amortized = [amortized_embeddings, amortized_conv, amortized_out]

def parameters():
 for c in components:
   for param in c.parameters():
      yield param
 yield dhWeights
 yield distanceWeights


def parameters_grammar():
 yield dhWeights
 yield distanceWeights

def parameters_baseline():
 for c in components_baseline:
   for param in c.parameters():
      yield param

def parameters_amortized():
 for c in components_amortized:
   for param in c.parameters():
      yield param

def parameters():
   for x in [parameters_grammar(), parameters_amortized()]:
      for y in x:
         yield y


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


optim_grammar = torch.optim.SGD(parameters_grammar(), lr=args.lr_grammar, momentum=args.momentum_grammar)
optim_amortized = torch.optim.SGD(parameters_amortized(), lr=args.lr_amortized, momentum=args.momentum_amortized)

import torch.nn.functional


counter = 0
dependencyLengthsLast = 1000
dependencyLengths = [1000]
dependencyLengthsPerEpoch = []
for epoch in range(5):
  corpus = list(CorpusIterator(args.language, partition="together").iterator(rejectShortSentences = True))
  shuffle(corpus)
  dependencyLengthsPerEpoch.append(sum(dependencyLengths)/(0.0+len(dependencyLengths)))
  dependencyLengths = []
  for sentence in corpus:
       if counter > 200000:
           print "Quitting at counter "+str(counter)
           quit()
       counter += 1
       printHere = (counter % 200 == 0)
       current = [sentence]
       assert len(current)==1
       depLength, overallLogprobSum = orderSentence(current[0], dhLogits, printHere)
       if depLength is None:
          continue
#       print(depLength, overallLogprobSum)
#      
#       if len(sentence) > 3 and len(sentence) < 5 and random() > 0.9:
#           quit()

       loss = (torch.FloatTensor(depLength) * overallLogprobSum).mean()
       if printHere:
         print ["AVERAGE DEPENDENCY LENGTH", crossEntropy, dependencyLengthsPerEpoch[-10:]]
       dependencyLengths.append(sum(depLength)/(1.0*len(depLength)*len(sentence)))
       crossEntropy = 0.99 * crossEntropy + 0.01 *  dependencyLengths[-1]

       optim_grammar.zero_grad()
       optim_amortized.zero_grad()

       loss.backward()
       if printHere:
         print "BACKWARD 3 "+__file__+" "+args.language+" "+str(myID)+" "+str(counter)
       optim_grammar.step()
       optim_amortized.step()
  with open("output/"+__file__+"_"+args.language+"_"+str(myID), "w") as outFile:
          print >> outFile, dependencyLengthsPerEpoch
          print >> outFile, args

