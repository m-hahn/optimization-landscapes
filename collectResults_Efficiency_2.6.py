import os
import sys

#group = sys.argv[1]

group = "DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl"

PATH = "/u/scr/mhahn/deps/"+group+"/"

files = os.listdir(PATH)

cache = {}

outHeader = set(["Language", "FileName"])

entries = []

for filename in files:
   if "model" in filename:
      print("READING "+filename )
      part1 = filename.split("_model_")[0]
      if "_" in part1:
        language = part1.split("_")[0]
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
          for line in inFile:
             line = line.strip().split("\t")
             if len(line) < 2:
                continue
             entry = dict(list(zip(header, line)))
             if language not in entry:
                entry["Language"] = language
             if not entry["Language"].endswith("2.6"):
               continue
             if "FileName" not in header:
                entry["FileName"] = filename[filename.rfind("_")+1:-4]
             entries.append(entry)
outHeader = sorted(list(outHeader))
print(outHeader)

with open(PATH+"auto-summary-lstm_2.6.tsv", "w") as outFile:
  print("\t".join(outHeader) , file=outFile)
  for entry in entries:
    print("\t".join([entry.get(x, "NA") for x in outHeader]), file=outFile)
print("WRITING", PATH+"auto-summary-lstm_2.6.tsv")
