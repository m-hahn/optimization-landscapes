#!/usr/bin/env python
# -*- coding: utf-8 -*-

import random

# from https://github.com/iswoc/iswoc-treebank
fileNames = """                                                                                            
  Ælfric's Lives of Saints                            | Old English         | aels         | 3137 tokens                                                                                                   
  Apollonius of Tyre                                  | Old English         | apt         | 5541 tokens                                                                                                     
  Anglo-Saxon Chronicles                              | Old English         | chrona      | 5939 tokens                                                                                                     
  Orosius                                             | Old English         | or          | 1728 tokens                                                                                                     
  West-Saxon Gospels                                  | Old English         | wscp        | 13061 tokens                                                                                                    
  La Vie Saint Eustace                                | Old French          | eustace     | 2340 tokens                                                                                                     
  Crónica Geral de Espanha 2-12                       | Portuguese          | cge1        | 12074 tokens                                                                                                    
  Crónica Geral de Espanha 155-167                    | Portuguese          | cge2        | 10547 tokens                                                                                                    
  Décadas Livro 5, VIII, 9-14                         | Portuguese          | coutdec-v-8 | 13794 tokens                                                                                                    
  Crónica de Alfonso XI                               | Spanish             | alfonso-xi  | 7942 tokens                                                                                                     
  Crónica de España                                   | Spanish             | ce          | 4627 tokens                                                                                                     
  El Conde Lucanor                                    | Spanish             | cdeluc      | 17551 tokens                                                                                                    
  Estoria de Espanna I                                | Spanish             | ee1         | 9488 tokens                                                                                                     
  General Estoria parte IV Daniel                     | Spanish             | ge4         | 9233 tokens                                                                                                     
  Libro delos claros varones                          | Spanish             | varones     | 5820 tokens    """
fileNames = map(lambda x:map(lambda y:y.strip(), x.split("|")), fileNames.strip().split("\n"))


def readISWOCCorpus(language, partition):
    print(language)
    print(fileNames)
    language = language.replace("_"," ")
    relevantFiles =map(lambda x:x[2],  filter(lambda x:x[1] == language, fileNames))
    path = "/u/scr/corpora/iswoc/iswoc-treebank"
    data = []
    for name in relevantFiles:
       with open(path+"/"+name+".conll", "r") as inFile:
          data = data + ["# newdoc id = "+name+"\n"+x for x in inFile.read().strip().split("\n\n") if len(x) > 3]
#          print(data[:5])
 #         quit()
    random.Random(465).shuffle(data)
    if partition == "train":
       data = data[500:]
    elif partition == "dev":
       data = data[:500]
    elif partition == "together":
       pass
    else:
        assert False
    print "Read "+str(len(data))+ " sentences from "+str(len(relevantFiles))+" datasets. "+partition
    return data

#data = readISWOCCorpus("Old_English")
#print len(data)
