import readCorpus


texts = readCorpus.texts()
print("...")
print(texts[0])
#print(next(stream))

def collectClauseStatistics(node):
   subjects = [(i,x) for i,x in enumerate(node["children"]) if x["category"].startswith("NP-NOM") and len(x["children"]) > 0]
   accusatives = [(i,x) for i,x in enumerate(node["children"]) if x["category"].startswith("NP-ACC") and len(x["children"]) > 0]
   datives = [(i,x) for i,x in enumerate(node["children"]) if x["category"].startswith("NP-DAT") and len(x["children"]) > 0]
   objects = sorted(accusatives+datives)
   verbs = [(i,x) for i,x in enumerate(node["children"]) if x["category"].startswith("VB")]
   if len(verbs) > 0 and (len(subjects) > 0 or len(objects) > 0):
      if len(subjects) > 0 and len(objects) > 0:
           coexpressed = 1
      else:
           coexpressed = 0
      order = "".join([x[1] for x in sorted([(i, "O") for i, _ in objects] + [(i, "S") for i, _ in subjects] + [(i, "V") for i, _ in verbs])])
      order = order.replace("SS", "S").replace("OO", "O")
#      print(order, coexpressed)
      results[order]+=1
      results[f"COEXPRESSED_{coexpressed}"]+=1
   for child in node["children"]:
     collectClauseStatistics(child)

dates = {}
with open("texts.txt", "r") as inFile:
  for line in inFile:
     line = (line.strip()+"\tNA").split("\t")
     dates[line[0]] = line[1]


def coexpression(results):
   return results["COEXPRESSED_1"] / (results["COEXPRESSED_0"] + results["COEXPRESSED_1"])


def symmetry(results):
   orders = defaultdict(int)
   totalS, totalO, total = 0,0,0
   for x in results:
      if "COEX" in x:
        continue
      orders[x.replace("O", "")] += results[x]
      orders[x.replace("S", "")] += results[x]
      if "S" in x:
        totalS += results[x]
      if "O" in x:
        totalO += results[x]
      total += results[x]
   return (((orders["SV"] * orders["OV"]) + (results["VS"] * orders["VO"]))/ (totalS*totalO), total)


summary = []
from collections import defaultdict
for text in texts:
   results = defaultdict(int)
   stream = readCorpus.readFromFile(text)
   for s in stream:
      collectClauseStatistics(s)
   
   print(dates[text],  coexpression(results), symmetry(results))
   if dates[text] != "NA":
       summary.append((int(dates[text]), coexpression(results), symmetry(results)))
print(sorted(summary))
for x in summary:
   print(x[0], x[1], x[2][0], x[2][1])
   
