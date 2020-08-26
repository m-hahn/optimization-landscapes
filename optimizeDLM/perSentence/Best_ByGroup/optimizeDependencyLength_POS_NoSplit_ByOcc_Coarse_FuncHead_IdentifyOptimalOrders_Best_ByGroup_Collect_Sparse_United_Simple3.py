                                                                                                                                                                     
from scipy.optimize import linprog          
import numpy as np
import sys
import torch
language = sys.argv[1]
import glob
files = sorted(glob.glob("/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_perSent_perOcc_coarse_funchead/"+language+"_optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead.py_model_*.tsv"))

from collections import defaultdict

data_ = []
print(files)
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
   if True:
    with open("/u/scr/mhahn/deps/DLM_MEMORY_OPTIMIZED/locality_optimized_dlm/manual_output_funchead_fine_depl_perSent_perOcc_coarse_funchead_SUBJ_DLM/optimizeDependencyLength_POS_NoSplit_ByOcc_Coarse_FuncHead_IdentifyOptimalOrders_Best_ByGroup.py_"+language+"_"+model, "r") as inFile:
     data = [x.split("\t") for x in inFile.read().strip().split("\n")]
     data = [x for x in data if len(x) > 2 and not (x[2].startswith("Real_"))]
     if len(data) < 2:
       continue
    bySentence = {x : [] for x in set([x[0] for x in data])}
    for line in data:
      bySentence[line[0]].append(line)
    bySentenceIndices = sorted(list(bySentence))
 #   print(len(bySentence))
#    quit()
    bySentence = {x : bySentence[x] for x in bySentenceIndices[:2000]} # Restrict to small set to make the linear programming efficient
    sentenceIndices = sorted(list(bySentence))
  
    # with objects. E.g. SOV, OSV, VSO, VOS, SVO, OVS
    # penalty for OS
    # penalty for VS
    ResultsWithO = [] #{"forward" : [], "backward" : []}
    for version in ["both"]:
      orders  = list(set([x[2] for x in data]))
      orders += list(set([x[2][::-1] for x in data]))
      orders = list(set(orders))
      orders = sorted(orders)
      print(orders)
      lengthWithO = []
      for x in sentenceIndices:
         byOrder = {x: 10000 for x in orders}
         for y in bySentence[x]:
            byOrder[y[2][::-1]] = min(int(y[1]), byOrder[y[2][::-1]])
            byOrder[y[2]] = min(int(y[1]), byOrder[y[2]])
         lengthWithO.append([byOrder[x] for x in orders])
#      lengthWithO = np.array(lengthWithO)
#      print((lengthWithO < 1000).mean(axis=0))
#      print((lengthWithO < 1000).mean(axis=0) > 0.1)
#      quit()

      OS_Penalty = 1
      VS_Penalty = 0
      for bonused in orders:
        if len([x for x in bonused if x == "O"]) != 1:
             continue
        for OS_Penalty in [0.0, 1.0, 2.0, 3.0]:
         for SV_ConsistencyPenalty in [0.0, 1.0, 2.0, 50.0]: # encourage consistency by forcing SV
          print(bonused, OS_Penalty, SV_ConsistencyPenalty)
          penalty = []
          lengthWithOSparse = []
          equalityConstraintsObj = []
          variablesByX = []
          orderByVar = []
          cachedPenaltyPerOrder = { order: (-0.1 if order == bonused or order == bonused.replace("O", "") else 0.0) + (OS_Penalty if ("O" in order and order.index("O") < order.index("S")) else 0) + (SV_ConsistencyPenalty if order.index("V") < order.index("S") else 0) for order in orders}
          for i_x in range(len(sentenceIndices)):
             variablesByX.append([])
             for i_order in range(len(orders)):
#                 if lengthWithO[i_x][i_order] < 9999:
                      variablesByX[-1].append(len(penalty))
                      penalty.append(cachedPenaltyPerOrder[orders[i_order]])
                      lengthWithOSparse.append(lengthWithO[i_x][i_order])
                      orderByVar.append(orders[i_order])
          penalty = np.array(penalty)
          lengthWithOSparse = np.array(lengthWithOSparse)
          coefficients = (penalty + lengthWithOSparse)
          coefficients = np.reshape(coefficients, (-1, len(orders)))
  #        print(coefficients.shape)
          solution_choices = np.argmin(coefficients, axis=1)
#          print(coefficients[1])
 #         print(solution_choices)
          depLengthAverage = 0
          rewardAverage = 0
          countByOrder = {x : 0 for x in orders}
          for var in range(len(sentenceIndices)):
            i_order = solution_choices[var]
            order = orders[i_order]
            countByOrder[order] += 1.0/len(sentenceIndices)
            depLengthAverage += lengthWithO[var][i_order]
            rewardAverage += float(coefficients[var][i_order])
          depLengthAverage /= len(sentenceIndices)
          rewardAverage /= len(sentenceIndices)

          ResultsWithO.append((OS_Penalty, [(orders[i], float(countByOrder[orders[i]])) for i in range(len(orders)) if countByOrder[orders[i]] > 0.05], depLengthAverage, rewardAverage, SV_ConsistencyPenalty))
   #       print(ResultsWithO)
          #quit()
      #    print(res)
      #    res = linprog(-coefficients, A_eq=equalityConstraintsObj, b_eq=equalityConstraintsBound, bounds=x_bounds)            
       #   print(res)
#      quit()
    break
    
ResultsWithO = sorted(ResultsWithO, key=lambda x:x[3], reverse=True)
for OS_Penalty in [0.0, 1.0, 2.0, 3.0]:
  for x in ResultsWithO:
    if x[0] != OS_Penalty:
       continue
    print(x)

print("================")
print("================")
for x in ResultsWithO:
    if x[0] != 3 or x[4] != 50:
       continue
    print(x)
