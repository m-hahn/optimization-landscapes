from ud_languages import languages


import random
random.shuffle(languages)
import subprocess

for language in languages:
   subprocess.call(["/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7", "optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_Best_ByGroup_SO_Run.py", language])

