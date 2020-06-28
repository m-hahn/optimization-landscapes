#/u/nlp/bin/stake.py -g 11.5g -s run-stats-pretrain2.json "python readDataDistEnglishGPUFree.py"

import random
import sys

import torch.nn as nn
import torch
from torch.autograd import Variable
import math


from pyro.infer import SVI
from pyro.optim import Adam


import pyro
import pyro.distributions as dist

import pyro
from pyro.distributions import Normal, Bernoulli
from pyro.infer import SVI
from pyro.optim import Adam


import os


import argparse
parser = argparse.ArgumentParser()
parser.add_argument('--language', type=str, default="Old_French_2.4")
args = parser.parse_args()




myID = random.randint(0,10000000)




from math import log, exp
from random import random, shuffle


import os
sys.path.append("..")
from corpusIterator_V import CorpusIterator_V

originalDistanceWeights = {}


posFine = set()
posUni = set()


def makeCoarse(x):
   if ":" in x:
      return x[:x.index(":")]
   return x

from collections import defaultdict
docs = defaultdict(int)


def initializeOrderTable():
   orderTable = {}
   keys = set()
   vocab = {}
   distanceSum = {}
   distanceCounts = {}
   depsVocab = set()
   for partition in ["train", "dev"]:
     for sentence, metadata in CorpusIterator_V(args.language,partition).iterator():
      docs[metadata["newdoc id"]] += 1
      for line in sentence:
          vocab[line["word"]] = vocab.get(line["word"], 0) + 1
          line["coarse_dep"] = makeCoarse(line["dep"])
          depsVocab.add(line["coarse_dep"])
          posFine.add(line["posFine"])
          posUni.add(line["posUni"])
  
          if line["coarse_dep"] == "root":
             continue
          posHere = line["posUni"]
          posHead = sentence[line["head"]-1]["posUni"]
          dep = line["coarse_dep"]
          direction = "HD" if line["head"] < line["index"] else "DH"
          key = dep
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
      originalDistanceWeights[key] = (distanceSum[key] / distanceCounts[key])
   return dhLogits, vocab, keys, depsVocab

#import torch.distributions
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
      assert line["coarse_dep"] == "root"


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



def orderChildrenRelative(sentence, remainingChildren, reverseSoftmax, distanceWeights_):
       childrenLinearized = []
       while len(remainingChildren) > 0:
           logits = torch.cat([distanceWeights_[stoi_deps[sentence[x-1]["dependency_key"]]].view(1) for x in remainingChildren])
           softmax = softmax_layer(logits.view(1,-1)).view(-1)
           selected = 0
#           selected = numpy.random.choice(range(0, len(remainingChildren)), p=softmax.data.numpy())
           log_probability = torch.log(softmax[selected])
           assert "linearization_logprobability" not in sentence[remainingChildren[selected]-1]
           sentence[remainingChildren[selected]-1]["linearization_logprobability"] = log_probability
           childrenLinearized.append(remainingChildren[selected])
           del remainingChildren[selected]
       if reverseSoftmax:
          childrenLinearized = childrenLinearized[::-1]

       return childrenLinearized           



def orderSentence(sentence, dhLogits, printThings, dhWeights, distanceWeights):
   sentence, metadata = sentence
   print(metadata)
   print(metadata["newdoc id"], len(sentence))
   root = None
   logits = [None]*len(sentence)
   logProbabilityGradient = 0
   dhWeights_ = dhWeights[stoi_docs[metadata["newdoc id"]]]
   distanceWeights_ = distanceWeights[stoi_docs[metadata["newdoc id"]]]
   for line in sentence:
      line["coarse_dep"] = makeCoarse(line["dep"])
      if line["coarse_dep"] == "root":
          root = line["index"]
          continue
      if line["coarse_dep"].startswith("punct"): # assumes that punctuation does not have non-punctuation dependents!
         continue
      key = line["coarse_dep"]
      line["dependency_key"] = key
      dhLogit = dhWeights_[stoi_deps[key]]
      probability = 1/(1 + torch.exp(-dhLogit))
      dhSampled = (line["index"] < line["head"])
      #else:
      #   dhSampled = (random() < probability.data.numpy())
#      logProbabilityGradient = (1 if dhSampled else -1) * (1-probability)
#      line["ordering_decision_gradient"] = logProbabilityGradient
      line["ordering_decision_log_probability"] = torch.log(1/(1 + torch.exp(- (1 if dhSampled else -1) * dhLogit)))
   
      direction = "DH" if dhSampled else "HD"
#torch.exp(line["ordering_decision_log_probability"]).data.numpy()[0],
      if printThings: 
         print("\t".join(list(map(str,["ORD", line["index"], (line["word"]+"           ")[:10], ("".join(list(key)) + "         ")[:22], line["head"], dhSampled, direction, (str(probability.data.numpy())+"      ")[:8], str(1/(1+exp(-dhLogits[key])))[:8], (str(distanceWeights_[stoi_deps[key]].data.numpy())+"    ")    ]  ))))

      headIndex = line["head"]-1
      sentence[headIndex]["children_"+direction] = (sentence[headIndex].get("children_"+direction, []) + [line["index"]])
      sentence[headIndex]["children_decisions_logprobs"] = (sentence[headIndex].get("children_decisions_logprobs", []) + [line["ordering_decision_log_probability"]])



   for line in sentence:
      if "children_DH" in line:
         childrenLinearized = orderChildrenRelative(sentence, line["children_DH"][:], False, distanceWeights_)
         line["children_DH"] = childrenLinearized
      if "children_HD" in line:
         childrenLinearized = orderChildrenRelative(sentence, line["children_HD"][:], True, distanceWeights_)
         line["children_HD"] = childrenLinearized

#         shuffle(line["children_HD"])
   
   linearized = []
   recursivelyLinearize(sentence, root, linearized, Variable(torch.FloatTensor([0.0])))
   if printThings or len(linearized) == 0:
     print(" ".join(map(lambda x:x["word"], sentence)))
     print(" ".join(map(lambda x:x["word"], linearized)))


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

print(docs)
itos_docs = sorted(list(docs))
stoi_docs = dict(zip(itos_docs, range(len(itos_docs))))
#time
#for d in docs:
 
#quit()

posUni = list(posUni)
itos_pos_uni = posUni
stoi_pos_uni = dict(zip(posUni, range(len(posUni))))

posFine = list(posFine)
itos_pos_ptb = posFine
stoi_pos_ptb = dict(zip(posFine, range(len(posFine))))



itos_pure_deps = sorted(list(depsVocab)) 
stoi_pure_deps = dict(zip(itos_pure_deps, range(len(itos_pure_deps))))
   

itos_deps = sorted(vocab_deps)
stoi_deps = dict(zip(itos_deps, range(len(itos_deps))))






words = list(vocab.items())
words = sorted(words, key = lambda x:x[1], reverse=True)
itos = list(map(lambda x:x[0], words))
stoi = dict(zip(itos, range(len(itos))))

assert stoi[itos[5]] == 5

vocab_size = 50000

depLMean = 10.0
depLSquared = 100.0
l2_weight = 0.001

# 0 EOS, 1 UNK, 2 BOS
#word_embeddings = torch.nn.Embedding(num_embeddings = vocab_size+3, embedding_dim = 50).cuda()
#pos_u_embeddings = torch.nn.Embedding(num_embeddings = len(posUni)+3, embedding_dim = 10).cuda()
#pos_p_embeddings = torch.nn.Embedding(num_embeddings = len(posFine)+3, embedding_dim=10).cuda()



#dropout = nn.Dropout(0.5).cuda()

#rnn = nn.LSTM(70, 128, 2).cuda()
#for name, param in rnn.named_parameters():
#  if 'bias' in name:
#     nn.init.constant(param, 0.0)
#  elif 'weight' in name:
#     nn.init.xavier_normal(param)
#
#decoder = nn.Linear(128,vocab_size+3).cuda()
#pos_ptb_decoder = nn.Linear(128,len(posFine)+3).cuda()
#
#components = [word_embeddings, pos_u_embeddings, pos_p_embeddings, rnn, decoder, pos_ptb_decoder]


#def parameters_lm():
# for c in components:
#   for param in c.parameters():
#      yield param



initrange = 0.1

batchSize = 1

lr_regression = 0.001
lr_lm = 0.1


crossEntropy = 10.0

def encodeWord(w):
   return stoi[w]+3 if stoi[w] < vocab_size else 1

#loss = torch.nn.CrossEntropyLoss(reduce=False, ignore_index = 0)



#import torch.cuda
import torch.nn.functional

logsoftmax = torch.nn.LogSoftmax()

def deepCopy(sentence):
  result = []
  for w in sentence:
     entry = {}
     for key, value in w.items():
       entry[key] = value
     result.append(entry)
  return result

#dhWeights_Prior = Normal(, Variable(torch.FloatTensor([1.0]* len(itos_deps))))
#distanceWeights_Prior = Normal(Variable(torch.FloatTensor([0.0] * len(itos_deps))), Variable(torch.FloatTensor([1.0]* len(itos_deps))))

counter = 0
corpus = CorpusIterator_V(args.language,"train")

#def guide(corpus):
#  mu_DH = pyro.param("mu_DH", Variable(torch.FloatTensor([0.0]*len(itos_deps)), requires_grad=True))
#  mu_Dist = pyro.param("mu_Dist", Variable(torch.FloatTensor([0.0]*len(itos_deps)), requires_grad=True))
#
#  sigma_DH = pyro.param("sigma_DH", Variable(torch.FloatTensor([1.0]*len(itos_deps)), requires_grad=True))
#  sigma_Dist = pyro.param("sigma_Dist", Variable(torch.FloatTensor([1.0]*len(itos_deps)), requires_grad=True))
#
#  dhWeights = pyro.sample("dhWeights", dist.Normal(mu_DH, sigma_DH)) #Variable(torch.FloatTensor([0.0] * len(itos_deps)), requires_grad=True)
#  distanceWeights = pyro.sample("distanceWeights", dist.Normal(mu_Dist, sigma_Dist)) #Variable(torch.FloatTensor([0.0] * len(itos_deps)), requires_grad=True)
#

#dhWeights = pyro.sample("dhWeights", dhWeights_Prior) #Variable(torch.FloatTensor([0.0] * len(itos_deps)), requires_grad=True)
#distanceWeights = pyro.sample("distanceWeights", distanceWeights_Prior) #Variable(torch.FloatTensor([0.0] * len(itos_deps)), requires_grad=True)
dhWeights = Variable(torch.FloatTensor([0.0] * len(itos_deps) * len(docs)).view(len(docs), len(itos_deps)))
distanceWeights = Variable(torch.FloatTensor([0.0] * len(itos_deps) * len(docs)).view(len(docs), len(itos_deps)))

dhWeights.requires_grad=True
distanceWeights.requires_grad=True

dhWeightsBase = Variable(torch.FloatTensor([0.0] * len(itos_deps) * len(docs)).view(len(docs), len(itos_deps)))
distanceWeightsBase = Variable(torch.FloatTensor([0.0] * len(itos_deps) * len(docs)).view(len(docs), len(itos_deps)))

dhWeightsBase.requires_grad=True
distanceWeightsBase.requires_grad=True



#print(dhWeights.sum().backward())

def forward(corpus, q):
       point, metadata = corpus.getSentence(q)
       print(metadata["newdoc id"])

       current = [(point, metadata)]
       global counter
       counter += 1
       printHere = (counter % 100 == 0)
       batchOrderedLogits = list(zip(*map(lambda z:orderSentence(z[1], dhLogits, z[0] % batchSize==0 and printHere, dhWeights, distanceWeights), zip(range(len(current)),current))))
      
       batchOrdered = batchOrderedLogits[0]
       lengths = list(map(len, current))
       maxLength = lengths[int(0.8*batchSize)]

       assert batchSize == 1
       
       if printHere:
         print("BACKWARD 3 "+__file__+" "+args.language+" "+str(myID)+" "+str(counter))

       logitCorr = batchOrdered[0][-1]["relevant_logprob_sum"]
#       pyro.sample("result_Correct_{}".format(q),  Bernoulli(logits=logitCorr), obs=Variable(torch.FloatTensor([1.0])))
       print(logitCorr)
       return logitCorr

optim = torch.optim.Adam([dhWeights, distanceWeights], lr=0.001)

def backward(loss):
    if float(loss) == 0:
      return
    optim.zero_grad()
    loss.backward()
    optim.step()

print(docs)
times = {'Graal_1225_prose': 1225, 'Aucassin_early13_verse-prose': 1210, 'QuatreLivresReis_late12_prose': 1180, 'TroyesYvain_1180_verse': 1180, 'Roland_1100_verse': 1100, 'BeroulTristan_late12_verse': 1180, 'StLegier_1000_verse': 1000, 'StAlexis_1050_verse': 1050, 'Strasbourg_842_prose': 842, 'Lapidaire_mid12_prose': 1150}

timesVector = (torch.FloatTensor([times[itos_docs[i]] for i in range(len(docs))])/100.0)

#covarianceMatrix = 

print(timesVector)

print(times)
quit()

for epoch in range(100):
   corpus.permute()
   for q in range(corpus.length()):
      loss = forward(corpus, q)
      backward(loss)


   if epoch % 1 == 0:
       print("Saving")
       save_path = "../raw-results/"
       #save_path = "/afs/cs.stanford.edu/u/mhahn/scr/deps/"
       with open(save_path+"/manual_output_ground_coarse/"+args.language+"_"+__file__+"_model_"+str(myID)+".tsv", "w") as outFile:
          print("\t".join(list(map(str,["Epochs", "DH_Mean_NoPunct", "DH_Sigma_NoPunct", "Distance_Mean_NoPunct", "Distance_Sigma_NoPunct", "Dependency"]))), file=outFile)
          dh_numpy = pyro.get_param_store().get_param("mu_DH").data.numpy()
          dh_sigma_numpy = pyro.get_param_store().get_param("sigma_DH").data.numpy()
          dist_numpy = pyro.get_param_store().get_param("mu_Dist").data.numpy()
          dist_sigma_numpy = pyro.get_param_store().get_param("sigma_Dist").data.numpy()

          for i in range(len(itos_deps)):
             key = itos_deps[i]
             dependency = key
             print("\t".join(list(map(str,[epoch, dh_numpy[i], dh_sigma_numpy[i], dist_numpy[i], dist_sigma_numpy[i], dependency]))), file=outFile)





