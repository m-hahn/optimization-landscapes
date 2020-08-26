from ud_languages import languages


import random
random.shuffle(languages)
import subprocess

with open("outputs/"+__file__+".tsv", "w") as outFile:
   print("\t".join(["Language", "Fraction", "DepLen"]), file=outFile)
for language in languages:
   subprocess.call(["/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7", __file__.replace("_All.py", ".py"), language])

