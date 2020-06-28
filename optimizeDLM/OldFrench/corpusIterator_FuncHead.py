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

             sentence[i]["dep"] = sentence[head]["dep"]
             sentence[head]["dep"] = "lifted_"+dep
             assert sentence[i]["index"] == i+1
   return sentence

class CorpusIteratorFuncHead():
   def __init__(self, language, partition="train", storeMorph=False, splitLemmas=False):
      self.basis = CorpusIterator(language, partition=partition, storeMorph=storeMorph, splitLemmas=splitLemmas)
   def permute(self):
      self.basis.permute()
   def length(self):
      return self.basis.length()
   def iterator(self, rejectShortSentences = False):
     iterator = self.basis.iterator(rejectShortSentences=rejectShortSentences)
     for sentence, metadata in iterator:
         reverse_content_head(sentence)
         yield sentence, metadata
   def getSentence(self, index):
      return reverse_content_head(self.basis.getSentence(index))


