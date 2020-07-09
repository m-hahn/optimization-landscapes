# Optimizing a grammar for dependency length minimization

import random
import sys

objectiveName = "DepL"

import argparse

import readCorpus

matrix = {}
matrix["verbDependents"] = []
matrix["objects"] = []
matrix["isRoot"] = []
matrix["verbLength"] = []
matrix["subjectLength"] = []
matrix["realOrders"] = []
matrix["time"] = []

def mean(x):
   return sum(x)/(len(x)+1e-10)

def length(x):
   if "word" in x and "*" not in x["word"]:
      return 1
   else:
      return sum([length(y) for y in x.get("children", [])])


def isAPronoun(x):
    result = len(x.get("children", [])) == 1 and x["children"][0]["category"].startswith("PRO") and length(x) == 1
#    print(x, result)
    return result

def descent(tree, time):
   children_categories = [x["category"] for x in tree.get("children", [])]
#   print(children_categories)
   if "NP-SBJ" in children_categories:
      subjects = [i for i in range(len(children_categories)) if children_categories[i] == "NP-SBJ" and not isAPronoun(tree["children"][i]) and length(tree["children"][i]) >= 1]
#      print(subjects, tree["children"])
      verbs = [i for i in range(len(children_categories)) if children_categories[i].startswith("V")]
      if len(verbs) > 0 and len(subjects) > 0:
#         print(tree["category"], children_categories, verbs)
         matrix["isRoot"].append(1 if tree["category"].startswith("IP-MAT") else 0)
         if len(verbs) > 1:
            print("WARNING", tree["category"], children_categories, verbs)
         matrix["verbLength"].append(mean([length(tree) - length(tree["children"][i]) for i in subjects]))
         matrix["subjectLength"].append(mean([length(tree["children"][i]) for i in subjects]))
         matrix["objects"].append((len([i for i in range(len(children_categories)) if (children_categories[i].startswith("NP-ACC") or children_categories[i].startswith("NP-DAT")) and not isAPronoun(tree["children"][i]) and length(tree["children"][i]) >= 1])))
         matrix["verbDependents"].append(len(children_categories))
         matrix["realOrders"].append(mean([1 if j > i else -1 for j in subjects for i in verbs]))
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
for x in matrix:
  if x != "order":
     m = mean(matrix[x])
     print("\t".join([x, str(m)]))
     matrix[x] = [y-m for y in matrix[x]]

#matrix = {x : torch.FloatTensor(y) for x,y in matrix.items()}
with open("/u/scr/mhahn/TMP.tsv", "w") as outFile:
  print >> outFile, ("\t".join(columns))
  for i in range(len(matrix["verbLength"])):
     print >> outFile, "\t".join([str(matrix[header][i]) for header in columns]) 
  print(list(matrix))

"""
data = read.csv("~/scr/TMP.tsv", sep="\t")
#summary(lm(order ~ isRoot * objects + isRoot * subjectLength + isRoot * verbDependents + isRoot * verbLength, data=data))
data$time = data$time/1000
summary(lm(realOrders ~ isRoot * objects + isRoot * subjectLength + isRoot * verbDependents + isRoot * verbLength + time, data=data))
#summary(lm(realOrders ~ order, data=data))


"""
  
