import os
import subprocess
import sys
keys = {}
import sys

from ud_languages import languages

import random
import subprocess

script = 'VSOrderWhenNoObject.py'


with open("outputs/"+script+".tsv", "w") as outFile:
   print >> outFile, "\t".join(['Language', 'SV_NoO', 'SV_WithO', 'VS_NoO', 'VS_WithO'])
for language in languages:
   subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--language="+language])

#   break

