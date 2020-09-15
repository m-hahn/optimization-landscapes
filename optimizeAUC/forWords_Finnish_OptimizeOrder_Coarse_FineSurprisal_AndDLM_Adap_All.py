with open("languagesWithoutTrain2.6.py", "r") as inFile:
   languages = inFile.read().strip().split("\n")
import subprocess
from random import choice

while True:
   language = choice(languages)
   if "German" in language:
      language = "German-GSD_2.6"
   elif "Japanese" in language:
      language = "Japanese-GSD_2.6"
   elif "Czech" in language:
      continue
   subprocess.call(["/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7", "forWords_Finnish_OptimizeOrder_Coarse_FineSurprisal_AndDLM_Adap.py", "--language="+language])
