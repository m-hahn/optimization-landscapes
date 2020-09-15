import os
import random
import sys

header = ["index", "word", "lemma", "posUni", "posFine", "morph", "head", "dep", "_", "_"]


from corpusIterator_V import CorpusIterator_V as CorpusIterator



 
def reverse_content_head(sentence):
   CH_CONVERSION_ORDER = ["cc", "case", "cop", "mark"]
   # find paths that should be reverted
   for dep in CH_CONVERSION_ORDER:
      for i in range(len(sentence)):
         if sentence[i]["dep"] == dep or sentence[i]["dep"].startswith(dep+":"):
             head = sentence[i]["head"]-1
             grandp = sentence[head]["head"]-1
             assert head > -1
             
             # grandp -> head -> i
             # grandp -> i -> head
             sentence[i]["head"] = grandp+1
             sentence[head]["head"] = i+1

             sentence[i]["coarse_dep"] = sentence[head]["coarse_dep"]
             sentence[i]["dep"] = sentence[head]["dep"]
             sentence[head]["coarse_dep"] = "lifted_"+dep
             sentence[head]["dep"] = "lifted_"+dep
             assert sentence[i]["index"] == i+1
   return sentence

class CorpusIteratorFuncHead():
   def __init__(self, language, partition="train", storeMorph=False, splitLemmas=False, shuffleData=True):
      self.basis_train =list(CorpusIterator(language, partition="train", storeMorph=storeMorph, splitLemmas=splitLemmas, shuffleData=False, shuffleDataSeed=5, errorWhenEmpty=False).iterator(rejectShortSentences=False))
      self.basis_dev = list(CorpusIterator(language, partition="dev", storeMorph=storeMorph, splitLemmas=splitLemmas, shuffleData=False, shuffleDataSeed=5, errorWhenEmpty=False).iterator(rejectShortSentences=False))
      self.basis_test = list(CorpusIterator(language, partition="test", storeMorph=storeMorph, splitLemmas=splitLemmas, shuffleData=False, shuffleDataSeed=5, errorWhenEmpty=False).iterator(rejectShortSentences=False))
      self.basis = self.basis_train + self.basis_dev + self.basis_test
      random.Random(5).shuffle(self.basis)
      if partition == "dev":
          self.basis = self.basis[:100]
      else:
          self.basis = self.basis[100:]
   def iterator(self, rejectShortSentences = False):
     for sentence in self.basis:
         reverse_content_head(sentence)
         yield sentence


