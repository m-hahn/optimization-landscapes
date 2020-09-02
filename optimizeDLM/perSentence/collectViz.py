import glob
import json
files = glob.glob("output/*viz*")
results = []
from collections import defaultdict
byLang = defaultdict(list)
byLangDir = defaultdict(list)
for r in files:
  with open(r, "r") as inFile:
      results.append(inFile.read().strip().split("\n") + [r])
      results[-1][0] = results[-1][0][1:-1].split(", ")
      results[-1][0] = (results[-1][0][-1], len(results[-1][0]))
      if len(results[-1]) > 3 and "Subjects" in results[-1][3]:
        os = results[-1][3]
        exec("os = "+os)
        consistent = os["Subjects"] * os["Objects"] + (1-os["Subjects"]) * (1-os["Objects"])
        lang = r[r.index(".py")+4:r.index("_2.6")]
        byLang[lang].append(consistent)
        byLangDir[lang].append(1 if consistent > 0.5 else 0.0)
      elif results[-1][2].startswith("{'") and False:
         os = (results[-1][2])
         exec("os = "+os)
#         print(os)
         totalS = (os["SV"] + os["VS"])
         totalO = (os["OV"] + os["VO"])
         consistent = (os["SV"] * os["OV"] + os["VS"] * os["VO"])/(totalS*totalO)
         results[-1][2] = ("SYMMETRY", consistent)
         lang = r[r.index(".py")+4:r.index("_2.6")]
         byLang[lang].append(consistent)
         byLangDir[lang].append(1 if consistent > 0.5 else 0.0)
#for x in sorted(results, key=lambda x:x[0][0], reverse=True):
#   print(x)

def mean(x):
  return sum(x)/(0.0001+len(x))

def extreme(x):
   mi = min(x)
   ma = max(x)
   if abs(mi-0.5) > abs(ma-0.5):
     return mi
   else:
     return ma

with open("results/results_i.tsv", "w") as outFile:
 print("\t".join(["Language", "Symmetry", "BinarySymmetry", "ExtremeSymmetry"]), file=outFile)
 for lang in sorted(list(byLang), key=lambda x:mean(byLang[x])):
  print(lang, mean(byLang[lang]), mean(byLangDir[lang]), len(byLang[lang]), byLang[lang])
  print("\t".join([str(x) for x in [lang+"_2.6", mean(byLang[lang]), mean(byLangDir[lang]), extreme(byLang[lang])]]), file=outFile)
print(len(byLang))
