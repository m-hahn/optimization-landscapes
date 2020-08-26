import os
import sys
import os
import subprocess
import random
from math import exp, sqrt
import sys
import os

script = "estimateParseability_Lexicalized2.py"


#print(parsingDone)
model = "6758749"
failures = 0
language = "English_2.6"
lr_policy = random.choice([0.002, 0.001, 0.001, 0.0005, 0.0005, 0.0005]) #random.choice([0.01, 0.001])
entropy_weight = random.choice([1.0, 0.1, 0.01, 0.001, 0.001, 0.001, 0.0001])

parameters = map(str, [lr_policy,	0.9,	entropy_weight,	0.001,	0.9,	0.999,	0.2,	20,	15,	2,	100,	2,	True,	200,	300,	0.0,	300])

max_updates = 200000000


command = map(str,["/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7", script, language, "NONE"] + parameters + [max_updates, model]) 
print " ".join(command)
#subprocess.call(command)
 
