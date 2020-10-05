import os
import subprocess
import sys
keys = {}
import sys

if len(sys.argv)>1:
   languages = sys.argv[1].split(",")
else:
   #languages = ["Hindi", "Swedish", "German", "Urdu", "English", "Spanish", "Chinese", "Slovenian", "Estonian", "Norwegian", "Serbian", "Croatian", "Finnish", "Portuguese", "Catalan", "Russian", "Arabic", "Czech", "Japanese", "French", "Latvian", "Basque", "Danish", "Dutch", "Ukrainian", "Hebrew", "Hungarian", "Persian", "Bulgarian", "Romanian", "Indonesian", "Greek", "Turkish", "Slovak", "Belarusian", "Galician", "Italian", "Lithuanian", "Polish", "Vietnamese", "Korean", "Tamil", "Irish", "Marathi", "Afrikaans", "Telugu" , "Coptic", "Gothic",  "Latin", "Ancient_Greek", "Old_Church_Slavonic"]
   from ud_languages import languages
#languages = ["English", "Japanese", "Chinese"]

import random
import subprocess

relevantPath = "/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm_surp_weighted//manual_output_funchead_fine_depl_surp_weighted/"
languages.remove("Japanese_2.6")
languages.append("Japanese-GSD_2.6")
while len(languages) > 0:
   script = 'optimizeWeighted_NoSplit.py'

   language = random.choice(languages)
   import os
   files = [x for x in os.listdir(relevantPath) if x.startswith(language+"_")]
   posCount = 0
   negCount = 0
  
   print([language, len(files)])
   if len(files) >= 10:
#   if negCount >= 8 and posCount >= 8:
       languages.remove(language) 
       continue


   LR_POLICY = random.choice(["0.1", "0.1", "0.01", "0.01"])
   subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--language="+language,  "--entropy_weight=0.001", "--lr_policy="+LR_POLICY, "--momentum=0.9"])

#   break

