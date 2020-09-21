from xml.dom import minidom
import os
import glob
import xml
files = glob.glob("/u/scr/mhahn/treebank_data/v2.1/Greek/texts/*.xml")
with open("perseus-docs.txt", "w") as outFile:
 for f in files:
#  mydoc = xml.dom.minidom.parse(f)
#  items = mydoc.getElementsByTagName('treebank')
#  bibl = items[0].getElementsByTagName('header')[0].getElementsByTagName("fileDesc")[0].getElementsByTagName("biblStruct")
   with open(f, "r") as inFile:
      data = inFile.read().split("\n")
      bibl = [i for i in range(len(data)) if "biblStruct" in data[i]]
      print(bibl)
      assert len(bibl) ==2
      bibl = " ".join([x.strip() for x in data[bibl[0]:bibl[1]+1]])
      print("=====", file=outFile)
      print(f, file=outFile)
      print(bibl, file=outFile)
#      documents = [x[x.index("document_id")+13:x.index("subdoc")-2] for x in data if "document_id" in x]
 #     print("\n".join(documents), file=outFile)

