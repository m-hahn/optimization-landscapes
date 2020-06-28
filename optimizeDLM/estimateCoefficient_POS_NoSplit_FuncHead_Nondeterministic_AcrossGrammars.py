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
script = "estimateCoefficient_POS_NoSplit_FuncHead_Nondeterministic.py"
results_ = []
dirs_ = []
medians_ = []
for g in grammars:
     grammarID = g[g.rfind("_")+1:-4]
     subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--language="+language, "--grammar="+grammarID])
     results = open("/u/scr/mhahn/TMP.R", "r").read().strip().split("\n")
     results[1] = [float(x) for x in results[1].split("\t")]
     results_.append(float(results[0]))
     dirs_.append(sign(results[1][0]) * sign(results[1][1]))
     medians_.append(float(results[2]))
  #   if len(results_) > 2:
 #       print(results_)
#        break
import torch
print(results_)
print(dirs_)
results = torch.FloatTensor(results_)
dirs = torch.FloatTensor(dirs_)
medians = torch.FloatTensor(medians_)
print(medians[dirs==-1])
print(medians[dirs==1])
print(results[dirs==1].mean() - results[dirs==-1].mean())
print(results[dirs==1].min() - results[dirs==-1].min())

