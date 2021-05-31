import os
import subprocess
import sys
keys = {}
import sys

import random
import subprocess

from ud_languages import languages

script = "evaluateCongruence_POS_NoSplit.py"

with open(f"output/{script}.tsv", "w") as outFile:
  print("\t".join(["Language", "Model", "Congruence_All", "Congruence_VN", "Congruence_VP", "Congruence_V", "Congruence_VProp"]), file=outFile)
for language in languages:
  subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--language="+language])

