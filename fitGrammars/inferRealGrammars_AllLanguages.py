import os
import subprocess
import sys
keys = {}
import sys

if len(sys.argv)>1:
   languages = sys.argv[1].split(",")
else:
   from ud_languages import languages

import random
import os
import random

PATH = "/u/scr/mhahn/deps/LANDSCAPE/mle-fine"
files = os.listdir(PATH)

import subprocess

failures = 0
while failures < 1000:
  language = random.choice(languages)
  relevant = [x for x in files if x.startswith(language+"_infer")]
  if len(relevant) > 0:
     failures += 1
     continue
  subprocess.call(["/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7", "inferRealGrammars.py", language])

