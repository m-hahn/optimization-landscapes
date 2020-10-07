import os
import subprocess
import sys
keys = {}
import sys

from ud_languages import languages

import random
import subprocess


script = __file__.replace("_all", "")


with open("outputs/"+script+".tsv", "w") as outFile:
   print >> outFile, "\t".join(['Language', 'No', 'Yes'])
for language in languages:
   subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--language="+language])

#   break

