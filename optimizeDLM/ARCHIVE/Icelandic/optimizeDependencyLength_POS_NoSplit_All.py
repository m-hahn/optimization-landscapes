import os
import subprocess
import sys
keys = {}
import sys

import random
import subprocess
ranges = []
#ranges.append((1400, 1600))
#ranges.append((1600, 1800))

ranges.append((1100, 1200))
ranges.append((1200, 1300))
ranges.append((1300, 1400))
ranges.append((1400, 1500))
ranges.append((1500, 1600))
ranges.append((1600, 1700))
ranges.append((1700, 1800))
ranges.append((1800, 1900))
ranges.append((1900, 2100))

for _ in range(500):
   range_ = random.choice(ranges)
   script = 'optimizeDependencyLength_POS_NoSplit.py'

   import os

   LR_POLICY = random.choice(["0.1", "0.1", "0.01"])
   subprocess.call(['/u/nlp/anaconda/ubuntu_16/envs/py27-mhahn/bin/python2.7', script, "--start="+str(range_[0]), "--end="+str(range_[1]),  "--entropy_weight=0.001", "--lr_policy="+LR_POLICY, "--momentum=0.9"])

#   break

