                                                                                                                                                                     
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
    withO = []
    withoutO = []
    multipleO = []
    for x in bySentence:
      order = bySentence[x][0][2]
      if "O" not in order:
         withoutO.append(x)
      elif len([x for x in order if x == "O"]) == 1:
         withO.append(x)
      else:
         multipleO.append(x)
    print(len(withO), len(withoutO), len(multipleO)) 

    lengthWithoutO = []
    for x in withoutO:
        vs = min([int(y[1]) for y in bySentence[x] if y[2] == "VS"])
        sv = min([int(y[1]) for y in bySentence[x] if y[2] == "SV"])
        lengthWithoutO.append((vs, sv))
    lengthWithoutO = sorted(lengthWithoutO, key=lambda x:x[0] - x[1])
    lengthWithoutO = np.array(lengthWithoutO)
    print(lengthWithoutO)
    print(data[:5])
    print(objWeight)
    results =[]
    for i in range(11):
       cutoff = int(len(withoutO)*i/10.0)
       results.append((lengthWithoutO[:cutoff, 0].sum() + lengthWithoutO[cutoff:, 1].sum())/len(withoutO))
       print(i, results[-1])
   
    # with objects. E.g. SOV, OSV, VSO, VOS, SVO, OVS
    # penalty for OS
    # penalty for VS
    ResultsWithO = {"forward" : [], "backward" : []}
    for version in ["forward", "backward"][::-1]:
      orders = sorted(list(set([x[2][::-1] if version == "backward" else x[2] for x in data if "O" in x[2]])))
      print(orders)
      lengthWithO = []
      for x in withO:
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
        for OS_Penalty in [0.0, 1.0, 2.0, 3.0]:
          penalty = []
          lengthWithOSparse = []
          equalityConstraintsObj = []
          variablesByX = []
          orderByVar = []
          def getPenalty(order):
              return (-0.1 if order == bonused else 0.0) + (OS_Penalty if order.index("O") < order.index("S") else 0)
          for i_x in range(len(withO)):
             variablesByX.append([])
             for i_order in range(len(orders)):
                 if lengthWithO[i_x][i_order] < 9999:
                      variablesByX[-1].append(len(penalty))
                      penalty.append(getPenalty(orders[i_order]))
                      lengthWithOSparse.append(lengthWithO[i_x][i_order])
                      orderByVar.append(orders[i_order])
          penalty = np.array(penalty)
          lengthWithOSparse = np.array(lengthWithOSparse)
          coefficients = (penalty + lengthWithOSparse) / len(withO)


          equalityConstraintsObj = np.array([[0 for _ in range(coefficients.size)] for _ in range(len(withO))])
          var_counter = 0
          for i_x in range(len(withO)):
              for var in variablesByX[i_x]:
                  equalityConstraintsObj[i_x][var] = 1
          equalityConstraintsBound = np.array([1 for _ in range(len(withO))])
          x_bounds = np.array([[0,1] for _ in range(coefficients.size)])
          res = linprog(coefficients, A_eq=equalityConstraintsObj, b_eq=equalityConstraintsBound, bounds=x_bounds)            
          solution = res.x
      #    print(np.reshape(solution, (-1, 3)))
          print(version, bonused)
          print(OS_Penalty)
          print(orders)
          countByOrder = {x : 0 for x in orders}
          for var in range(len(solution)):
            countByOrder[orderByVar[var]] += float(solution[var]) / len(withO)
          depLengthAverage = (lengthWithOSparse * solution).sum() / len(withO)
          ResultsWithO[version].append((OS_Penalty, [(orders[i], float(countByOrder[orders[i]])) for i in range(len(orders)) if countByOrder[orders[i]] > 0.05], depLengthAverage))
          print(ResultsWithO)
          #quit()
      #    print(res)
      #    res = linprog(-coefficients, A_eq=equalityConstraintsObj, b_eq=equalityConstraintsBound, bounds=x_bounds)            
       #   print(res)
#      quit()
    
    
    
