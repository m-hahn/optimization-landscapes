from ud_languages import languages
import sys, os
version = sys.argv[1]
from corpusIterator_V import CorpusIterator_V as CorpusIterator
                                        
basePath = "/u/scr/corpora/Universal_Dependencies/Universal_Dependencies_"+version+"/ud-treebanks-v"+version+"/"                                           
files = os.listdir(basePath)                                             
files = sorted(list(set([x[:x.index("-")][3:]+"_2.6" for x in files])))
print(files)
languages = set(languages)
with open("excluded.tex", "w") as outFile:
 for language in files:
   if language not in languages:
       try:
         corpus = sorted(list(CorpusIterator(language, "together").iterator()))
         print >> outFile, (language + " & "+str( len(corpus)) + " & " +str(sum([len(x) for x in corpus]))+ "\\\\")
       except AssertionError:
#         print(e)
         continue
