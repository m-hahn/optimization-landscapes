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
language = sys.argv[1]
grammars = glob.glob(f"/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_funchead/{language}_optimize*tsv")
script = "estimateRandomInit_POS_NoSplit_FuncHead_Nondeterministic.py"
results_ = []
dirs_ = []
medians_ = []
for dirs in [-1, 1]:
  for _ in range(10):
     subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--language="+language, "--direction="+str(dirs)])
     results = open("/u/scr/mhahn/TMP.R", "r").read().strip().split("\n")
     results_.append(float(results[0]))
     dirs_.append(dirs)
import torch
print(results_)
print(dirs_)
results = torch.FloatTensor(results_)
dirs = torch.FloatTensor(dirs_)
print(results[dirs==1].mean() - results[dirs==-1].mean())

