import os
import subprocess
import sys
keys = {}
import sys

from ud_languages import languages

import random
import subprocess

for language in languages:
   script = 'collectSentencesProperties_FuncHead.py'
   subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--language="+language])

#   break

