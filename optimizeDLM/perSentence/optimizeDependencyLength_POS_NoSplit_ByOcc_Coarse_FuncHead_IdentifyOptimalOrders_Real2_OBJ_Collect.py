import sys
import torch
language = sys.argv[1]
import glob
files = glob.glob("/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_perSent_perOcc_coarse_funchead/"+language+"_optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead.py_model_*.tsv")


data_ = []
data_Best = []
data_Best1 = []
data_1 = []
data_Real = []

if True:
    objWeight = 1.0
    with open("/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_perSent_perOcc_coarse_funchead_SUBJ_DLM/optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_Real2_OBJ.py_"+language+"_"+"REAL", "r") as inFile:
     fileContent = inFile.read().strip().split("\n")
     data = sorted([(x[0], objWeight*float(x[1])) for x in [x.split("\t") for x in fileContent]])
     dataBest = sorted([(x[0], objWeight*float(x[2])) for x in [x.split("\t") for x in fileContent]])
     dataBest1 = sorted([(x[0], objWeight*float(x[3])) for x in [x.split("\t") for x in fileContent]])
     data1 = sorted([(x[0], objWeight*float(x[4])) for x in [x.split("\t") for x in fileContent]])
     dataReal = sorted([(x[0], objWeight*float(x[5])) for x in [x.split("\t") for x in fileContent]])
    print(data[:5])
    values = torch.FloatTensor(sorted([x[1] for x in data]))
    valuesBest = torch.FloatTensor(sorted([x[1] for x in dataBest]))
    valuesBest1 = torch.FloatTensor(sorted([x[1] for x in dataBest1]))
    values1 = torch.FloatTensor(sorted([x[1] for x in data1]))
    valuesReal = torch.FloatTensor(sorted([x[1] for x in dataReal]))

    results = []
    resultsBest = []
    resultsBest1 = []
    results1 = []
    resultsReal = []
    for i in range(11):
       cutoff = int(len(values)*i/10.0)
       results.append((values[:cutoff].sum() - values[cutoff:].sum())/len(data))
       resultsBest.append((valuesBest[:cutoff].sum() - valuesBest[cutoff:].sum())/len(data))
       resultsBest1.append((valuesBest1[:cutoff].sum() - valuesBest1[cutoff:].sum())/len(data))
       results1.append((values1[:cutoff].sum() - values1[cutoff:].sum())/len(data))
       resultsReal.append((valuesReal[:cutoff].sum() - valuesReal[cutoff:].sum())/len(data))
       print(i, results[-1], values.sum()/len(data))
    print("plot((1:11), c("+", ".join([str(float(x)) for x in results])+"))")
    data_.append(data)
    data_Best.append(dataBest)
    data_Best1.append(dataBest1)
    data_1.append(data1)
    data_Real.append(dataReal)
print(len(data_))
for x in data_:
  print("---")
  print(x[:5])
values = [sum([y[i][1] for y in data_]) for i in range(len(data_[0]))]
values = torch.FloatTensor(sorted(values))
valuesBest = [sum([y[i][1] for y in data_Best]) for i in range(len(data_Best[0]))]
valuesBest = torch.FloatTensor(sorted(valuesBest))
valuesBest1 = [sum([y[i][1] for y in data_Best1]) for i in range(len(data_Best1[0]))]
valuesBest1 = torch.FloatTensor(sorted(valuesBest1))
values1 = [sum([y[i][1] for y in data_1]) for i in range(len(data_1[0]))]
values1 = torch.FloatTensor(sorted(values1))
valuesReal = [sum([y[i][1] for y in data_Real]) for i in range(len(data_Real[0]))]
valuesReal = torch.FloatTensor(sorted(valuesReal))
results = []
resultsBest = []
for i in range(11):
   cutoff = int(len(values)*i/10.0)
   results.append((values[:cutoff].sum() - values[cutoff:].sum())/len(data))
   resultsBest.append((valuesBest[:cutoff].sum() - valuesBest[cutoff:].sum())/len(data))
   resultsBest1.append((valuesBest1[:cutoff].sum() - valuesBest1[cutoff:].sum())/len(data))
   results1.append((values1[:cutoff].sum() - values1[cutoff:].sum())/len(data))
   resultsReal.append((valuesReal[:cutoff].sum() - valuesReal[cutoff:].sum())/len(data))
   print(i, results[-1], values.sum()/len(data))
print("plot((1:11), c("+", ".join([str(float(x)) for x in results])+"))")

with open("outputs/"+__file__[:-3]+"_All.py"+".tsv", "a") as outFile:
   for i in range(len(results)):
      print >> outFile, ("\t".join([language, str(i), str(float(results[i])), str(float(resultsBest[i])), str(float(resultsBest1[i])), str(float(results1[i])), str(float(resultsReal[i]))]))

