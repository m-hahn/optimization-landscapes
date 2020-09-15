import os
DIR = "/u/scr/mhahn/deps/hillclimbing-auc/"
files = [x for x in sorted(os.listdir(DIR)) if "DLM" in x]
from collections import defaultdict
same = defaultdict(int)


dist_d, dist_n, dist_a = 0, 0, 0

def standardise(x):
   if x.index("O") < x.index("S"):
      return x[::-1]
   return x

for f in files:
   data = [x.split("\t") for x in open(DIR+"/"+f, "r").read().strip().split("\n")]
   args = data[0][0][1:-1].split(", ")
   data = dict(data[1:])
   language = f[f.index("_")+1:f.index("_for")]
   order = standardise("".join([x[0] for x in sorted([("V", int(data["HEAD"])), ("S", int(data["nsubj"])), ("O", int(data["obj"]))],key= lambda x:x[1])]))
   correl = [x for x in ["lifted_case", "lifted_cop", "LIFTED_mark", "nmod", "obl", "xcomp", "acl", "aux", "amod", "nummod", "nsubj"] if x in data]
   def d(x):
      return int(data[x]) < int(data["HEAD"])

   np = "".join([x[0] for x in sorted([("_", int(data["HEAD"])), ("A", int(data["amod"])), ("N", int(data["nummod"])), ("D", int(data["det"]))],key= lambda x:x[1])])
   dist_d += abs(np.index("D") - np.index("_"))/(len(files)+0.0)
   dist_n += abs(np.index("N") - np.index("_"))/(len(files)+0.0)
   dist_a += abs(np.index("A") - np.index("_"))/(len(files)+0.0)
   args_ = dict([x.split("=") for x in args[3:-3]])
   print(language, "\t", order, [x for x in correl if d(x) == d("obj")], "\t", [x for x in correl if d(x) != d("obj")], "\t", args[:3], "\t", np, "\t", args_.get("aucWeight", "NA"))
   for x in correl:
     if d(x) == d("obj"):
         same[x] += 1.0/len(files)
print(same)
print(dist_d, dist_n, dist_a)
