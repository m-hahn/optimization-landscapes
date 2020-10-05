# /u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7 generateManyModels_AllTwo.py
import os
import sys

from ud_languages import languages

import random
import subprocess
import os


BASE_DIR = "manual_output_funchead_parser_fine_2.6"
inPath = "/u/scr/mhahn/deps/LANDSCAPE/"+BASE_DIR+"/"

while len(languages) > 0:
   script = "optimizeParseability.py"

   language = random.choice(languages)
   import os
   files = [x for x in os.listdir(inPath) if x.startswith(language+"_")]
#   posCount = 0
#   negCount = 0
#   for name in files:
#     with open(inPath+name, "r") as inFile:
#       for line in inFile:
#           line = line.split("\t")
#           if line[7] == "obj":
#             dhWeight = float(line[6])
#             if dhWeight < 0:
#                negCount += 1
#             elif dhWeight > 0:
#                posCount += 1
#             break
#   
#   print([language, "Neg count", negCount, "Pos count", posCount])
   if len(files) > 8:
       languages.remove(language) 
       continue

   args = {}

   # = random.choice(languages)

   command = map(str,["/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7", script, "--language="+language ] )

   print(command)
   print(" ".join(command))
   subprocess.call(command)
#   break 
