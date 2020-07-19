import sys
import torch
language = sys.argv[1]
import glob
files = glob.glob("/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_perSent_perOcc_coarse_funchead/"+language+"_optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead.py_model_*.tsv")


data_ = []

for filepath in files:
  hasError = False
  with open(filepath, "r") as inFile:
   objWeight = None
   next(inFile)
   for line in inFile:
      try:
         dhWeight, dep, distanceWeight, language, model = line.strip().split("\t")
      except ValueError:
         print("ERROR", line)
         hasError = True
         continue
      if dep == "obj":
         objWeight = 1 if float(dhWeight) > 0 else -1
         break
   if hasError:
       continue
   model = filepath[filepath.rfind("_")+1:-4]
   try:
    with open("/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_perSent_perOcc_coarse_funchead_SUBJ_DLM/optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders.py_"+language+"_"+model, "r") as inFile:
     data = sorted([(x[0], objWeight*float(x[1])) for x in [x.split("\t") for x in inFile.read().strip().split("\n")]])
    print(data[:5])
    values = torch.FloatTensor(sorted([x[1] for x in data]))
    results = []
    for i in range(11):
       cutoff = int(len(values)*i/10.0)
       results.append((values[:cutoff].sum() - values[cutoff:].sum())/len(data))
       print(i, results[-1], values.sum()/len(data))
    print("plot((1:11), c("+", ".join([str(float(x)) for x in results])+"))")
    data_.append(data)
   except FileNotFoundError:
     pass
   except TypeError:
     pass
for x in data_:
  print("---")
  print(x[:5])
values = [sum([y[i][1] for y in data_]) for i in range(len(data_[0]))]
values = torch.FloatTensor(sorted(values))
results = []
for i in range(11):
   cutoff = int(len(values)*i/10.0)
   results.append((values[:cutoff].sum() - values[cutoff:].sum())/len(data))
   print(i, results[-1], values.sum()/len(data))
print("plot((1:11), c("+", ".join([str(float(x)) for x in results])+"))")

