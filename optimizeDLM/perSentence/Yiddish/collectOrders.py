# Optimizing a grammar for dependency length minimization

import random
import sys

objectiveName = "DepL"

import argparse

import readCorpus

matrix = {}
matrix["realOrders_objects"] = []
matrix["realOrders_subjects"] = []
matrix["time"] = []

def mean(x):
   return sum(x)/(len(x)+1e-10)

def length(x):
   if "word" in x and "*" not in x["word"]:
      return 1
   else:
      return sum([length(y) for y in x.get("children", [])])


def isAPronoun(x):
#    return length(x) <= 1
    result = len(x.get("children", [])) == 1 and x["children"][0]["category"].startswith("PRO") and length(x) == 1
#    print(x, result)
    return result

def subject(x):
   return x.startswith("NP-SBJ")
def object_(x):
   return (x.startswith("NP-ACC") or x.startswith("NP-DAT"))
def descent(tree, time):
   children_categories = [x["category"] for x in tree.get("children", [])]
#  print(children_categories)
   subjects = [i for i in range(len(children_categories)) if subject(children_categories[i]) and not isAPronoun(tree["children"][i]) and length(tree["children"][i]) >= 1]
   objects  = [i for i in range(len(children_categories)) if object_(children_categories[i]) and not isAPronoun(tree["children"][i]) and length(tree["children"][i]) >= 1]
   verbs = [i for i in range(len(children_categories)) if children_categories[i].startswith("V")]
   if len(verbs) > 0:
      matrix["realOrders_objects"].append(mean([1 if j > i else 0 for j in objects for i in verbs]))
      matrix["realOrders_subjects"].append(mean([1 if j > i else 0 for j in subjects for i in verbs]))
      matrix["time"].append(time)
    #print([(x, y[-1]) for x, y in matrix.iteritems() if len(y) > 0])
         
   for c in tree.get("children", []):
      descent(c, time)


texts = readCorpus.texts()
print(texts)
for text in texts:
   sentences = readCorpus.readFromFile(text[1])
   for sent in sentences:
      descent(sent, text[0])
#   break

columns = sorted(list(matrix))
print(columns)
import torch

#matrix = {x : torch.FloatTensor(y) for x,y in matrix.items()}
with open("/u/scr/mhahn/TMP.tsv", "w") as outFile:
  print >> outFile, ("\t".join(columns))
  for i in range(len(matrix["time"])):
     print >> outFile, "\t".join([str(matrix[header][i]) for header in columns]) 
  print(list(matrix))

"""
data = read.csv("~/scr/TMP.tsv", sep="\t")
library(dplyr)
library(tidyr)
data$century = round(data$time/100)

data %>% group_by(century) %>% summarise(realOrders_objects=mean(realOrders_objects), realOrders_subjects = mean(realOrders_subjects), same = realOrders_objects*realOrders_subjects + (1-realOrders_objects)*(1-realOrders_subjects))

"""
  
