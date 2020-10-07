import os
import subprocess
import sys
keys = {}
import sys

from ud_languages import languages

import random
import subprocess

script = 'collectSentencesProperties_ByVerb.py'


with open("outputs/"+script+".tsv", "w") as outFile:
   print >> outFile, ("Language\tcorrelatingDependents\tisRoot\tobjects\torder\tsubjectLength\tverbDependents\tverbLength")
for language in languages:
   subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--language="+language])

#   break

