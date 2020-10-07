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
partition = "together"
sentences = list(CorpusIterator(args.language,partition).iterator())
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

from collections import defaultdict
matrix = {}
for x in ["Yes", "No"]:
   matrix[x] = 0
def mean(x):
   return sum(x)/(len(x)+1e-10)
for sent in sentences:
  annotateChildren(sent)
  for word in sent:
   if "children" not in word:
     continue
   if word["posUni"] == "VERB":
    subjects = [i for i in word["children"] if sent[i-1]["dep"] == "nsubj" and sent[i-1]["posUni"] == "NOUN"]
    objects = [i for i in word["children"] if sent[i-1]["dep"] == "obj"]
    if len(subjects) > 0 or len(objects) > 0:
      coexpressed = "Yes" if len(subjects) > 0 and len(objects) > 0 else "No"
      matrix[coexpressed] += 1
columns = sorted(list(matrix))
print(columns)
with open("outputs/"+__file__+".tsv", "a") as outFile:
   print >> outFile, "\t".join([args.language] + [str(matrix[x]) for x in columns])

