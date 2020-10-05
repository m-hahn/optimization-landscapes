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

relevantPath = "/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl/"

script = "countSubjObjOrder.py"

with open("countsSubjObjOrder.tsv", "w") as outFile:
 print("Language\tMixed\tSame\tOpposite", file=outFile)
 outFile.flush()
 for language in languages:
   subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--language="+language,  "--entropy_weight=0.001", "--lr_policy=0.1", "--momentum=0.9"],stdout=outFile)

#   break

