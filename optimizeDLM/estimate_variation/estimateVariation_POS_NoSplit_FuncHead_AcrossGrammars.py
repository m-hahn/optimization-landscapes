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
script = "estimateVariation_POS_NoSplit_FuncHead.py"
results_ = []
dirs_ = []
for g in grammars:
     grammarID = g[g.rfind("_")+1:-4]
     subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--language="+language, "--grammar="+grammarID])
     results = open("/u/scr/mhahn/TMP_"+language, "r").read().strip().split("\n")
     
     dir1, dir2 = results[0].strip().split("\t")
     direction = (sign(float(dir1)) == sign(float(dir2)))
     results_.append([float(x) for x in results[1:]])
     dirs_.append(direction)
#     if len(results_) > 2:
 #       print(results_)
  #      break
import torch
dirs = torch.FloatTensor(dirs_)
results = torch.FloatTensor(results_)
print(results.size(), dirs.size())
#print(results)
print("Subsampling result:", dirs[results.argmin(dim=0)].mean())
print(dirs.mean())




