import os
import random
#import accessISWOCData
#import accessTOROTData
import sys

header = ["index", "word", "lemma", "posUni", "posFine", "morph", "head", "dep", "_", "_"]

with open("perseus-authors.txt", "r") as inFile:
   perseusAuthors = inFile.read().strip().split("\n")
print(perseusAuthors)
perseusAuthors = {x[1] : int(x[2]) for x in [y.split("\t") for y in perseusAuthors]}
print(perseusAuthors)
with open("perseus-docs.txt", "r") as inFile:
   perseusDocs = inFile.read().strip().split("\n")
fromDocToYear = {}
for i in range(0, len(perseusDocs), 3):
  author = perseusDocs[i].replace("=", "").strip()
  filename = perseusDocs[i+1]
  filename = filename[filename.rfind("/")+1:]
  print(author, filename, perseusAuthors[author])
  fromDocToYear[filename] = perseusAuthors[author]


def readUDCorpus(language, partition, ignoreCorporaWithoutWords=True):
      assert partition == "together"
      l = language.split("_")
      language = "_".join(l[:-1])
      version = l[-1]
      #print(l, language)
      basePath = "/u/scr/corpora/Universal_Dependencies/Universal_Dependencies_"+version+"/ud-treebanks-v"+version+"/"
      files = os.listdir(basePath)
      files = list(filter(lambda x:x.startswith("UD_"+language.replace("-Adap", "")), files))
      print >> sys.stderr, ("FILES", files)
      data = []
      for name in files:
        if "Sign" in name:
           print >> sys.stderr, ("Skipping "+name)
           continue
        assert ("Sign" not in name)
        if "Chinese-CFL" in name or "English-ESL" in name or "Hindi_English" in name or "French-FQB" in name or "Latin-ITTB" in name or "Latin-LLCT" in name:
           print >> sys.stderr, ("Skipping "+name)
           continue
        suffix = name[len("UD_"+language):]
        if name == "UD_French-FTB":
            subDirectory = "/u/scr/mhahn/corpus-temp/UD_French-FTB/"
        else:
            subDirectory =basePath+"/"+name
        subDirFiles = os.listdir(subDirectory)
        partitionHere = partition
            
        candidates = list(filter(lambda x:"-ud-" in x and x.endswith(".conllu"), subDirFiles))
        print >> sys.stderr, ("SUBDIR FILES", subDirFiles)

        print >> sys.stderr, candidates
        assert len(candidates) >= 1, candidates
        for cand in candidates:
           try:
              dataPath = subDirectory+"/"+cand
              with open(dataPath, "r") as inFile:
                 newData = inFile.read().strip().split("\n\n")
                 assert len(newData) > 1
                 data = data + newData
           except IOError:
              print >> sys.stderr, ("Did not find "+dataPath)

      assert len(data) > 0, (language, partition, files)


      print >> sys.stderr, ("Read "+str(len(data))+ " sentences from "+str(len(files))+" "+partition+" datasets. "+str(files)+"   "+basePath)
      return data

class CorpusIterator_V():
   def __init__(self, language, partition="together", epoch=None, storeMorph=False, splitLemmas=False, shuffleData=True, shuffleDataSeed=None, splitWords=False, ignoreCorporaWithoutWords=True):
      self.years = {"archaic" : (-1000, -525), "classical" : (-525, -325), "koine" : (-325, 1000)}[epoch]
      print >> sys.stderr, ("LANGUAGE", language)
      if splitLemmas:
           assert language == "Korean"
      self.splitLemmas = splitLemmas
      self.splitWords = splitWords
      assert self.splitWords == (language == "BKTreebank_Vietnamese")

      self.storeMorph = storeMorph
      data = readUDCorpus(language, partition, ignoreCorporaWithoutWords=ignoreCorporaWithoutWords)
      if shuffleData:
       if shuffleDataSeed is None:
         random.shuffle(data)
       else:
         random.Random(shuffleDataSeed).shuffle(data)

      self.data = data
      self.partition = partition
      self.language = language
      self.data = list(self.iterator_filter())
      print("EPOCH", epoch, len(self.data))
      assert len(data) > 0, (language, partition)
   def permute(self):
      random.shuffle(self.data)
   def length(self):
      return len(self.data)
   def processSentence(self, sentence):
        sentence = list(map(lambda x:x.split("\t"), sentence.split("\n")))
        result = []
        metadata = {}
        for i in range(len(sentence)):
           if sentence[i][0].startswith("#"):
              posEq = sentence[i][0].index(" = ")
              key = sentence[i][0][2:posEq]
              value = sentence[i][0][posEq+3:]
              metadata[key] = value
              continue
           if "-" in sentence[i][0]: # if it is NUM-NUM
              continue
           if "." in sentence[i][0]:
              continue
           sentence[i] = dict([(y, sentence[i][x]) for x, y in enumerate(header)])
           sentence[i]["head"] = int(sentence[i]["head"])
           sentence[i]["index"] = int(sentence[i]["index"])
           sentence[i]["word"] = sentence[i]["word"].lower()
           if self.language == "Thai-Adap":
              assert sentence[i]["lemma"] == "_"
              sentence[i]["lemma"] = sentence[i]["word"]
           if "ISWOC" in self.language or "TOROT" in self.language:
              if sentence[i]["head"] == 0:
                  sentence[i]["dep"] = "root"

           if self.splitLemmas:
              sentence[i]["lemmas"] = sentence[i]["lemma"].split("+")

           if self.storeMorph:
              sentence[i]["morph"] = sentence[i]["morph"].split("|")

           if self.splitWords:
              sentence[i]["words"] = sentence[i]["word"].split("_")


           sentence[i]["dep"] = sentence[i]["dep"].lower()
           if self.language == "LDC2012T05" and sentence[i]["dep"] == "hed":
              sentence[i]["dep"] = "root"
           if self.language == "LDC2012T05" and sentence[i]["dep"] == "wp":
              sentence[i]["dep"] = "punct"

           sentence[i]["coarse_dep"] = sentence[i]["dep"].split(":")[0]



           result.append(sentence[i])
 #          print sentence[i]
        return (result, metadata)
   def getSentence(self, index):
      result = self.processSentence(self.data[index])[0]
      return result
   def iterator(self):
     for sentence in self.data:
           yield self.processSentence(sentence)[0]

   def iterator_filter(self):
     for sentence in self.data:
        processed = self.processSentence(sentence)

        metadata = processed[1]
        if "source" in metadata:
          year = 100 if "New Test" in metadata["source"] else (-450 if "Histories" in metadata["source"] else "NA")
        elif "sent_id" in metadata:
          text_id = metadata["sent_id"]
          text_id = text_id[:text_id.index("@")]
          year = fromDocToYear[text_id]
#        print(year, self.years, year >= self.years[0] and year <= self.years[1])
        if year >= self.years[0] and year <= self.years[1]:
           yield sentence

