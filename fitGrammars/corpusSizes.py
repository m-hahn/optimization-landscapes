from ud_languages import languages
from corpusIterator_V import CorpusIterator_V as CorpusIterator

with open("corpora.tex", "w") as outFile:
 for language in sorted(languages):
   corpus = sorted(list(CorpusIterator(language, "together").iterator()))
   print >> outFile, (language.replace("_2.6", "").replace("_", " ")+" & "+"{:,}".format(len(corpus)) + " & " +"{:,}".format(sum([len(x) for x in corpus]))+"\\\\")

