import os
import subprocess
import sys
keys = {}
import sys

import random
import subprocess

relevantPath = "/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl/"

script = "evaluateCongruence_POS_NoSplit.py"

files = os.listdir(relevantPath)
with open(f"output/{script}.tsv", "r") as inFile:
   next(inFile)
   models = [x.split("\t")[1] for x in inFile]
models = set(models)
#with open(f"output/{script}.tsv", "w") as outFile:
#  print("\t".join(["Language", "Model", "Congruence_All", "Congruence_VN", "Congruence_VP", "Congruence_V", "Congruence_VProp"]), file=outFile)
for f in files:
  if "optimizeDependencyLength_POS_NoSplit.py" not in f:
    continue
  try:
     language = f[:f.index("_optimize")]
  except ValueError:
     continue
 # if "German" not in language:
#     continue
  model = f.split("_")[-1].replace(".tsv", "")
  if model in models:
    continue
  subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--language="+language,  "--myID="+model])

