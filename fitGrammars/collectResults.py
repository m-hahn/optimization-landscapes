import os
import sys

#group = sys.argv[1]

group = "LANDSCAPE/mle-fine_selected"

PATH = "/u/scr/mhahn/deps/"+group+"/"

files = os.listdir(PATH)

cache = {}

outHeader = set(["Language", "FileName", "Language_"])

entries = []

collectedFilesNumber = 0

for filename in files:
   if "model" in filename:
#      print("READING "+filename )
      part1 = filename.split("_model_")[0]
      if "_" in part1:
        language = part1[:part1.index("_infer")]
      else:
        assert False
      with open(PATH+filename, "r") as inFile:
          try:
            header = next(inFile).strip().split("\t")
          except StopIteration:
            print ["EMPTY FILE?",inPath+filename]
            continue
          for x in header:
            outHeader.add(x)
          collectedFilesNumber+= 1
          for line in inFile:
             line = line.strip().split("\t")
             if len(line) < 2:
                continue
             entry = dict(list(zip(header, line)))
             if "Language" not in entry:
                entry["Language"] = language
             if not ("_2.6_" in filename):
               collectedFilesNumber-=1
               break
             entry["Language_"] = entry["Language"].replace("_2.6", "")
             if "FileName" not in header:
                entry["FileName"] = filename[filename.rfind("_")+1:-4]
             entries.append(entry)
outHeader = sorted(list(outHeader))
print(outHeader)

print(collectedFilesNumber)
with open(PATH+"auto-summary-lstm_2.6.tsv", "w") as outFile:
  print("\t".join(outHeader) , file=outFile)
  for entry in entries:
    print("\t".join([entry.get(x, "NA") for x in outHeader]), file=outFile)
print("WRITING", PATH+"auto-summary-lstm_2.6.tsv")
