                                                                                                                                                                     
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
     print(data[:5])
     data = [x for x in data if len(x) > 2 and not (x[2].startswith("Real_")) and "O" in x[2]]
     if len(data) < 2:
       print("NO DATA")
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
    for version in ["forward", "backward"][::-1]:
      orders = sorted(list(set([x[2][::-1] if version == "backward" else x[2] for x in data])))
      print(orders)
      lengthWithO = []
      for x in sentenceIndices:
         byOrder = {x: 10000 for x in orders}
         for y in bySentence[x]:
            byOrder[y[2][::-1] if version == "backward" else y[2]] = min(int(y[1]), byOrder[y[2][::-1] if version == "backward" else y[2]])
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
         for SV_ConsistencyPenalty in [0.0]: #, 1.0, 2.0, 3.0]: # encourage consistency by forcing SV
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



# BAMBARA
#(0.0, [('SVO', 0.3426086956521747), ('VOS', 0.41913043478261053), ('VSO', 0.23826086956521697)], 39.28521739130435, 39.24330434782623, 0.0)
#(0.0, [('OSV', 0.3373913043478268), ('OVS', 0.24347826086956478), ('SOV', 0.41913043478261053)], 39.28521739130435, 39.24330434782623, 0.0)
#(0.0, [('SVO', 0.5078260869565245), ('VOS', 0.2539130434782605), ('VSO', 0.23826086956521697)], 39.28521739130435, 39.2344347826089, 0.0)
#(0.0, [('OSV', 0.3408695652173921), ('OVS', 0.5078260869565245), ('SOV', 0.15130434782608676)], 39.28521739130435, 39.2344347826089, 0.0)
#(0.0, [('SVO', 0.31304347826087), ('VOS', 0.15130434782608676), ('VSO', 0.5356521739130458)], 39.28521739130435, 39.231652173913204, 0.0)
#(0.0, [('OSV', 0.5356521739130458), ('OVS', 0.31304347826087), ('SOV', 0.15130434782608676)], 39.28521739130435, 39.231652173913204, 0.0)
#(1.0, [('OSV', 0.3373913043478268), ('OVS', 0.24347826086956478), ('SOV', 0.41913043478261053)], 39.28521739130435, 39.83234782608708, 0.0)
#(1.0, [('OSV', 0.23826086956521697), ('OVS', 0.3426086956521747), ('SOV', 0.41913043478261053)], 39.28521739130435, 39.83182608695668, 0.0)
#(1.0, [('OSV', 0.19478260869565187), ('OVS', 0.18608695652173884), ('SOV', 0.6191304347826094)], 39.485217391304346, 39.80417391304372, 0.0)
#(1.0, [('SVO', 0.5078260869565245), ('VOS', 0.15130434782608676), ('VSO', 0.3408695652173921)], 39.28521739130435, 39.42139130434787, 0.0)
#(1.0, [('SVO', 0.5600000000000018), ('VOS', 0.09913043478260863), ('VSO', 0.3408695652173921)], 39.337391304347825, 39.380521739130664, 0.0)
#(1.0, [('SVO', 0.3426086956521747), ('VOS', 0.07130434782608697), ('VSO', 0.5860869565217405)], 39.36521739130435, 39.37791304347845, 0.0)
#(2.0, [('OSV', 0.19478260869565187), ('OVS', 0.18608695652173884), ('SOV', 0.6191304347826094)], 39.485217391304346, 40.22747826086963, 0.0)
#(2.0, [('OSV', 0.14782608695652155), ('OVS', 0.23304347826086916), ('SOV', 0.6191304347826094)], 39.485217391304346, 40.22365217391315, 0.0)
#(2.0, [('OSV', 0.13739130434782593), ('OVS', 0.14434782608695634), ('SOV', 0.7182608695652163)], 39.68347826086956, 40.17513043478288, 0.0)
#(2.0, [('SVO', 0.5600000000000018), ('VOS', 0.07130434782608697), ('VSO', 0.3686956521739142)], 39.36521739130435, 39.50069565217393, 0.0)
#(2.0, [('SVO', 0.575652173913045), ('VOS', 0.05565217391304351), ('VSO', 0.3686956521739142)], 39.396521739130435, 39.45026086956546, 0.0)
#(2.0, [('SVO', 0.3565217391304358), ('VOS', 0.050434782608695675), ('VSO', 0.5930434782608708)], 39.40695652173913, 39.448521739130626, 0.0)
#(3.0, [('OSV', 0.13739130434782593), ('OVS', 0.14434782608695634), ('SOV', 0.7182608695652163)], 39.68347826086956, 40.51495652173919, 0.0)
#(3.0, [('OSV', 0.10956521739130426), ('OVS', 0.172173913043478), ('SOV', 0.7182608695652163)], 39.68347826086956, 40.51147826086965, 0.0)
#(3.0, [('OSV', 0.09913043478260863), ('OVS', 0.11130434782608686), ('SOV', 0.7895652173913019)], 39.89739130434783, 40.44973913043508, 0.0)
#(3.0, [('SVO', 0.575652173913045), ('VOS', 0.050434782608695675), ('VSO', 0.3739130434782621)], 39.40695652173913, 39.553217391304365, 0.0)
#(3.0, [('SVO', 0.5860869565217405), ('VSO', 0.3739130434782621)], 39.43826086956522, 39.49965217391329, 0.0)
#(3.0, [('SVO', 0.36521739130434894), ('VSO', 0.6034782608695662)], 39.46434782608696, 39.497913043478455, 0.0)

