import glob
files = glob.glob("output/*viz*")
results = []
for r in files:
  with open(r, "r") as inFile:
      results.append(inFile.read().strip().split("\n") + [r])
      results[-1][0] = results[-1][0][1:-1].split(", ")
      results[-1][0] = (results[-1][0][-1], len(results[-1][0]))
for x in sorted(results, key=lambda x:x[0][0], reverse=True):
   print(x)
