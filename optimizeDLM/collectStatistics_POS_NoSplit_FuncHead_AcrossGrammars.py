def sign(x):
   if x> 0:
      return 1
   elif x < 0:
       return -1
   else:
       return 0

import subprocess
import glob
import sys
script = "collectStatistics_POS_NoSplit_FuncHead.py"
results_ = []
dirs_ = []
from ud_languages import languages
with open("/u/scr/mhahn/TMP2.tsv", "w") as outFile:
  print("\t".join(["Language", "Dependency", "C_Len", "Mean_Len", "Med_Len", "TQ_Len", "MeanL_Len", "C_Ch", "Mean_Ch", "Med_Ch", "TQ_Ch", "MeanL_Ch", "C_Sib", "Mean_Sib", "Med_Sib", "TQ_Sib", "MeanL_Sib"]), file=outFile)

  for language in languages:
     subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--language="+language])
     results = open("/u/scr/mhahn/TMP.txt", "r").read().strip().split("\n")
     for r in results:
       print(r.strip(), file=outFile) 

