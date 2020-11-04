from ud_languages import languages

languages = list(set(languages))

assert len(languages) == len(set(languages))

import os
import random


import subprocess

modelsDir = "/u/scr/mhahn/deps/LANDSCAPE/mle-fine_disjoint/"
modelsDirOut = "/u/scr/mhahn/deps/LANDSCAPE/mle-fine_selecte_disjoint/"

files = os.listdir(modelsDir)
import shutil

for language in languages:
  relevant = [x for x in files if x.startswith(language+"_infer")]
  relevantModelExists = False
  farthestName, farthestCounter = None, 0
  for filename in relevant:
      with open(modelsDir+filename, "r") as inFile:
         header = next(inFile).strip().split("\t")
         line = next(inFile).strip().split("\t")
         counter = int(line[header.index("Counter")])
         print(counter)
         if counter > farthestCounter:
           farthestName = filename
           farthestCounter = counter

  print(farthestName, farthestCounter)
  if farthestName is None:
     continue
  shutil.copyfile(modelsDir+farthestName, modelsDirOut+farthestName)
