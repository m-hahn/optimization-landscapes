import os
import subprocess
import sys
keys = {}
import sys

from ud_languages import languages

import random
import subprocess

columns = ["Language", "S", "O", "SO"]
script = "arguments.py"

for _ in range(50):
  language = random.choice(languages)
  subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', "optimizeDependencyLength_POS_NoSplit_ByOcc_Amortized_Optim8_i_both_viz.py", "--lr_amortized=0.0001", "--language="+language])

#   break

