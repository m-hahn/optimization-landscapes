# Optimizing a grammar for dependency length minimization

import random
import sys

objectiveName = "DepL"

import argparse

parser = argparse.ArgumentParser()

parser.add_argument('--language', type=str, default="Old_French_2.6")
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


from corpusIterator_FuncHead import CorpusIteratorFuncHead as CorpusIterator

originalDistanceWeights = {}


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
   for partition in ["together"]:
     for sentence, metadata in CorpusIterator(args.language,partition).iterator():
      docs[metadata["newdoc id"]] += 1
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



def orderChildrenRelative(sentence, remainingChildren, reverseSoftmax, distanceWeights_):
       childrenLinearized = []
       while len(remainingChildren) > 0:
           logits = torch.cat([distanceWeights_[stoi_deps[sentence[x-1]["dependency_key"]]].view(1) for x in remainingChildren])
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
   sentence, metadata = sentence
   root = None
   logits = [None]*len(sentence)
   logProbabilityGradient = 0
   if printThings:
      print(metadata["newdoc id"])
   dhWeights_ = dhWeights[stoi_docs[metadata["newdoc id"]]]
   distanceWeights_ = distanceWeights[stoi_docs[metadata["newdoc id"]]]
   for line in sentence:
      line["fine_dep"] = line["dep"]
      if line["fine_dep"] == "root":
          root = line["index"]
          if printThings:
             print("------ROOT-------")
          continue
      if line["fine_dep"].startswith("punct"):
         continue
      key = (sentence[line["head"]-1]["posUni"], line["fine_dep"], line["posUni"]) if line["fine_dep"] != "root" else stoi_deps["root"]
      line["dependency_key"] = key
      dhLogit = dhWeights_[stoi_deps[key]]
      probability = 1/(1 + torch.exp(-dhLogit))
      dhSampled = (random() < probability.data.numpy())
      line["ordering_decision_log_probability"] = torch.log(1/(1 + torch.exp(- (1 if dhSampled else -1) * dhLogit)))

      direction = "DH" if dhSampled else "HD"
      if printThings: 
         print "\t".join(map(str,["ORD", line["index"], (line["word"]+"           ")[:10], (".".join(list(key)) + "         ")[:22], line["head"], dhSampled, direction, (str(float(probability))+"      ")[:8], str(1/(1+exp(-dhLogits[key])))[:8], (str(distanceWeights_[stoi_deps[key]].data.numpy())+"    ")[:8] ]  ))

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

   
   linearized = []
   recursivelyLinearize(sentence, root, linearized, Variable(torch.FloatTensor([0.0])))
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
   return linearized, logits


dhLogits, vocab, vocab_deps, depsVocab = initializeOrderTable()

print(docs)
print(docs)
times = {'Graal_1225_prose': 1225, 'Aucassin_early13_verse-prose': 1210, 'QuatreLivresReis_late12_prose': 1180, 'TroyesYvain_1180_verse': 1180, 'Roland_1100_verse': 1100, 'BeroulTristan_late12_verse': 1180, 'StLegier_1000_verse': 1000, 'StAlexis_1050_verse': 1050, 'Strasbourg_842_prose': 842, 'Lapidaire_mid12_prose': 1150}

itos_docs = sorted(list(docs), key=lambda x:times[x])
stoi_docs = dict(zip(itos_docs, range(len(itos_docs))))
#time
#for d in docs:
 

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


relevantPath = "/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_funchead_OldFrench/"

import os
files = [x for x in os.listdir(relevantPath) if x.startswith(args.language+"_") and __file__ in x]
posCount = 0
negCount = 0
for name in files:
  with open(relevantPath+name, "r") as inFile:
    for line in inFile:
        line = line.split("\t")
        if line[0] == "obj":
          dhWeight = float(line[2])
          if dhWeight < 0:
             negCount += 1
          elif dhWeight > 0:
             posCount += 1
          break

print(["Neg count", negCount, "Pos count", posCount])
#
#if posCount >= 4 and negCount >= 4:
#   print("Enough models!")
#   quit()

dhWeights = Variable(torch.FloatTensor([0.0] * len(itos_deps) * len(docs)).view(len(docs), len(itos_deps)), requires_grad=True)
distanceWeights = Variable(torch.FloatTensor([0.0] * len(itos_deps) * len(docs)).view(len(docs), len(itos_deps)), requires_grad=True)

print(len(itos_deps), len(docs))
for i, key in enumerate(itos_deps):
   if key == "obj": 
       dhWeights.data[:, i] = (10.0 if posCount < negCount else -10.0)





words = list(vocab.items())
words = sorted(words, key = lambda x:x[1], reverse=True)
itos = list(map(lambda x:x[0], words))
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
while True:
  corpus = CorpusIterator(args.language, partition="together")
  corpus.permute()
  corpus = corpus.iterator(rejectShortSentences = False)

  for current in corpus:
       if counter > 50000000:
           print("Quitting at counter "+str(counter))
           quit()
       counter += 1
       printHere = (counter % 50 == 0)
       current = [current]
       batchOrdered, logits = orderSentence(current[0], dhLogits, printHere)
     
       metadata = current[0][1]
       
       maxLength = len(batchOrdered)
       batchOrdered = [batchOrdered]
       if maxLength <= 2:
         print("Skipping extremely short sentence", metadata)
         continue
       input_words = []
       input_pos_u = []
       input_pos_p = []
       for i in range(maxLength+2):
          input_words.append(map(lambda x: 2 if i == 0 else (encodeWord(x[i-1]["word"]) if i <= len(x) else 0), batchOrdered))
          input_pos_u.append(map(lambda x: 2 if i == 0 else (stoi_pos_uni[x[i-1]["posUni"]]+3 if i <= len(x) else 0), batchOrdered))
          input_pos_p.append(map(lambda x: 2 if i == 0 else (stoi_pos_ptb[x[i-1]["posFine"]]+3 if i <= len(x) else 0), batchOrdered))

       loss = 0
       wordNum = 0
       lossWords = 0
       policyGradientLoss = 0
       baselineLoss = 0
       for c in components:
          c.zero_grad()

       for p in  [dhWeights, distanceWeights]:
          if p.grad is not None:
             p.grad.data = p.grad.data.mul(args.momentum)




       if True:
           words_layer = word_embeddings(Variable(torch.LongTensor(input_words))) #.cuda())
           pos_u_layer = pos_u_embeddings(Variable(torch.LongTensor(input_pos_u))) #.cuda())
           pos_p_layer = pos_p_embeddings(Variable(torch.LongTensor(input_pos_p))) #.cuda())
           inputEmbeddings = dropout(torch.cat([words_layer, pos_u_layer, pos_p_layer], dim=2))
           baseline_predictions = baseline(inputEmbeddings)
           lossesHead = [[Variable(torch.FloatTensor([0.0]))]*1 for i in range(maxLength+1)]

           cudaZero = Variable(torch.FloatTensor([0.0]), requires_grad=False)
           for i in range(1,len(input_words)): 
              for j in range(1):
                 if input_words[i][j] != 0:
                    if batchOrdered[j][i-1]["head"] == 0:
                       realHead = 0
                    else:
                       realHead = batchOrdered[j][i-1]["reordered_head"] 
                    if batchOrdered[j][i-1]["fine_dep"] == "root":
                       continue
                    # to make sure reward attribution considers this correctly
                    registerAt = max(i, realHead)
                    depLength = abs(i - realHead)
                    assert depLength >= 0
                    baselineLoss += torch.nn.functional.mse_loss(baseline_predictions[i][j] + baseline_predictions[realHead][j], depLength + cudaZero )
                    depLengthMinusBaselines = depLength - baseline_predictions[i][j] - baseline_predictions[realHead][j]
                    lossesHead[registerAt][j] += depLengthMinusBaselines
                    lossWords += depLength

           for i in range(1,len(input_words)): 
              for j in range(1):
                 if input_words[i][j] != 0:
                    policyGradientLoss += batchOrdered[j][-1]["relevant_logprob_sum"] * ((lossesHead[i][j]).detach().cpu())
                    if input_words[i] > 2 and j == 0 and printHere:
                       print [itos[input_words[i][j]-3], itos_pos_ptb[input_pos_p[i][j]-3], "Cumul_DepL_Minus_Baselines", lossesHead[i][j].data.cpu().numpy()[0], "Baseline Here", baseline_predictions[i][j].data.cpu().numpy()[0]]
                    wordNum += 1
       if wordNum == 0:
         print input_words
         print batchOrdered
         continue
       if printHere:
         print loss/wordNum
         print lossWords/wordNum
         print ["CROSS ENTROPY", crossEntropy, exp(crossEntropy)]
       crossEntropy = 0.99 * crossEntropy + 0.01 * (lossWords/wordNum)
       probabilities = torch.sigmoid(dhWeights)

       neg_entropy = torch.sum( probabilities * torch.log(probabilities) + (1-probabilities) * torch.log(1-probabilities))

       policy_related_loss = args.lr_policy * (args.entropy_weight * neg_entropy + policyGradientLoss) # lives on CPU
       policy_related_loss.backward()

       loss += baselineLoss # lives on GPU
       if loss is 0:
          continue
       loss.backward()
       if printHere:
         print "BACKWARD 3 "+__file__+" "+args.language+" "+str(myID)+" "+str(counter)

       torch.nn.utils.clip_grad_norm(parameters(), 5.0, norm_type='inf')
       for param in parameters():
         if param.grad is None:
           print "WARNING: None gradient"
           continue
         param.data.sub_(lr_lm * param.grad.data)
       if counter % 10000 == 0:
          TARGET_DIR = "/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/"
          print "Saving"
          with open(TARGET_DIR+"/manual_output_funchead_fine_depl_funchead_OldFrench/"+args.language+"_"+__file__+"_model_"+str(myID)+".tsv", "w") as outFile:
             print >> outFile, "\t".join(list(map(str,["CoarseDependency", "Document", "DH_Weight","DistanceWeight", "HeadPOS", "DependentPOS", "FileName"])))

             for i in range(len(itos_deps)):
                head, rel, dependent = itos_deps[i]
                dependency = key
                for doc in range(len(itos_docs)):
                   outputs = []
                   outputs.append(rel)
                   outputs.append(itos_docs[doc])
                   outputs.append(dhWeights[doc, i])
                   outputs.append(distanceWeights[doc, i])
                   outputs.append(head)
                   outputs.append(dependent)
                   outputs.append(myID)
                   print >> outFile, "\t".join(list(map(str,outputs)))


