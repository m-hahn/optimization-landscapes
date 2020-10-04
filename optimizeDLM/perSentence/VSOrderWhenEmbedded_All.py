import os
import subprocess
import sys
keys = {}
import sys

from ud_languages import languages

import random
import subprocess

script = 'VSOrderWhenEmbedded.py'


with open("outputs/"+script+".tsv", "w") as outFile:
   print >> outFile, "\t".join(['Language', 'SV_HeadIsLeft', 'SV_HeadIsRight', 'SV_Root', 'VS_HeadIsLeft', 'VS_HeadIsRight', 'VS_Root'])
for language in languages:
   subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--language="+language])

#   break

