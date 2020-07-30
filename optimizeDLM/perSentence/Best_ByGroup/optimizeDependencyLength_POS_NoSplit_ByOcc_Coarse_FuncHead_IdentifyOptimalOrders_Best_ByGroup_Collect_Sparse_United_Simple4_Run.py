import sys
import glob
import subprocess
import sys
import torch
import glob


from ud_languages import languages

with open("results/Simple4.txt", "w") as outFile:
 print("\t".join(["Language", "Model", "Fraction", "DepLen"]), file=outFile)
for language in languages:
   subprocess.call(["/u/nlp/anaconda/main/anaconda3/envs/py37-mhahn/bin/python", "optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_Best_ByGroup_Collect_Sparse_United_Simple4.py", language])


