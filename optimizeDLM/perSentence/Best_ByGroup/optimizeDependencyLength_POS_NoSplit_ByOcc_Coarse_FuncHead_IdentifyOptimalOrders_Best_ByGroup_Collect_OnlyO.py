                                                                                                                                                                     
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
    withO = sentenceIndices
    ResultsWithO = [] #{"forward" : [], "backward" : []}
    for version in ["forward", "backward"][::-1]:
      orders = sorted(list(set([x[2][::-1] if version == "backward" else x[2] for x in data])))
      print(orders)
      lengthWithO = []
      for x in withO:
         byOrder = {x: 10000 for x in orders}
         for y in bySentence[x]:
            byOrder[y[2][::-1] if version == "backward" else y[2]] = min(int(y[1]), byOrder[y[2][::-1] if version == "backward" else y[2]])
         lengthWithO.append([byOrder[x] for x in orders])
      lengthWithO = np.array(lengthWithO)
#      print((lengthWithO < 1000).mean(axis=0))
#      print((lengthWithO < 1000).mean(axis=0) > 0.1)
#      quit()

      OS_Penalty = 1
      VS_Penalty = 0
      for bonused in orders:
        for OS_Penalty in [0.0, 1.0, 2.0, 3.0]:
          penalty = np.array([[(-0.1 if order == bonused else 0.0) + (OS_Penalty if order.index("O") < order.index("S") else 0) + (VS_Penalty if order.index("V") < order.index("S") else 0) for order in orders] for _ in range(len(withO))])
      #    print(lengthWithO)
      #    print(penalty)
      #    print(lengthWithO.mean(axis=0))
          coefficients = (penalty + lengthWithO) / len(withO)
          coefficients = np.reshape(coefficients, (-1,))
      #    print(coefficients)
          equalityConstraintsObj = np.array([[0 for _ in range(coefficients.size)] for _ in range(len(withO))])
          for i in range(len(withO)):
             equalityConstraintsObj[i][i*len(orders):(i+1)*len(orders)] = 1
      #    equalityConstraintsObj = np.reshape(equalityConstraintsObj, (-1,))
       #   print(equalityConstraintsObj)
          equalityConstraintsBound = np.array([1 for _ in range(len(withO))])
          x_bounds = np.array([[0,1] for _ in range(coefficients.size)])
#          print(x_bounds[coefficients > 1000].shape)
 #         x_bounds[coefficients > 1000][1] = 0
        #  print(coefficients.shape)
         # print(equalityConstraintsObj.shape)
          #print(x_bounds.shape)
          res = linprog(coefficients, A_eq=equalityConstraintsObj, b_eq=equalityConstraintsBound, bounds=x_bounds)            
          solution = res.x
      #    print(np.reshape(solution, (-1, 3)))
          print(version, bonused)
          print(OS_Penalty)
          print(orders)
          print(np.reshape(solution, (-1, len(orders))).mean(axis=0))
          solution = np.reshape(solution, (-1, len(orders)))
          depLengthAverage = (lengthWithO * solution).sum(axis=1).mean()
          frequencyPerOrder = np.reshape(solution, (-1, len(orders))).mean(axis=0)
          ResultsWithO.append((OS_Penalty, [(orders[i], float(frequencyPerOrder[i])) for i in range(len(orders))], depLengthAverage))
          print(ResultsWithO)
          #quit()
      #    print(res)
      #    res = linprog(-coefficients, A_eq=equalityConstraintsObj, b_eq=equalityConstraintsBound, bounds=x_bounds)            
       #   print(res)
#      quit()
    break
    
ResultsWithO = sorted(ResultsWithO, key=lambda x:x[2], reverse=True)
for OS_Penalty in [0.0, 1.0, 2.0, 3.0]:
  for x in ResultsWithO:
    if x[0] != OS_Penalty:
       continue
    print(x)

# BAMBARA
#(0.0, [('SVO', 0.5078245836672494), ('VOS', 0.20260940866402716), ('VSO', 0.2895660090393702)], 39.285217888005164)
#(0.0, [('OSV', 0.28956600903937024), ('OVS', 0.5078245836672494), ('SOV', 0.20260940866402716)], 39.285217888005164)
#(0.0, [('OSV', 0.5356504077328219), ('OVS', 0.2782616986821046), ('SOV', 0.1860878949495532)], 39.2852178821143)
#(0.0, [('SVO', 0.2782616986821046), ('VOS', 0.18608789494955327), ('VSO', 0.5356504077328218)], 39.285217882114296)
#(0.0, [('SVO', 0.2930441553903248), ('VOS', 0.41912889794586833), ('VSO', 0.2878269480056656)], 39.2852178785143)
#(0.0, [('OSV', 0.2878269480056658), ('OVS', 0.2930441553903248), ('SOV', 0.41912889794586833)], 39.2852178785143)
#(1.0, [('OSV', 0.1713051269696363), ('OVS', 0.20956579309289147), ('SOV', 0.619129081362065)], 39.48521660278668)
#(1.0, [('SVO', 0.5599988345552127), ('VOS', 0.08521766279841342), ('VSO', 0.35478350402457787)], 39.35130462882123)
#(1.0, [('SVO', 0.32782701508002315), ('VOS', 0.08608727055636248), ('VSO', 0.5860857157207384)], 39.35043500780371)
#(1.0, [('OSV', 0.1930439267935377), ('OVS', 0.3426078598183751), ('SOV', 0.46434821480305305)], 39.33043574875448)
#(1.0, [('OSV', 0.3373902467260377), ('OVS', 0.21478306722505064), ('SOV', 0.44782668746760107)], 39.313914221421356)
#(1.0, [('SVO', 0.4104349340403432), ('VOS', 0.15130405750628564), ('VSO', 0.43826100983457145)], 39.28521824646364)
#(2.0, [('OSV', 0.12347858658800821), ('OVS', 0.15826114856313078), ('SOV', 0.7182602662889827)], 39.683477694659516)
#(2.0, [('OSV', 0.1947822933680961), ('OVS', 0.1652176345191344), ('SOV', 0.6400000735618454)], 39.52695733691705)
#(2.0, [('OSV', 0.12869589945358467), ('OVS', 0.2330432002395883), ('SOV', 0.6382609017499357)], 39.523478990714665)
#(2.0, [('SVO', 0.5756515721496849), ('VOS', 0.05304358081602428), ('VSO', 0.3713048483481939)], 39.40173948306455)
#(2.0, [('SVO', 0.3495657775441167), ('VOS', 0.05739140509707293), ('VSO', 0.5930428186759625)], 39.393043831010736)
#(2.0, [('SVO', 0.4513043570598976), ('VOS', 0.07130438830067495), ('VSO', 0.477391255961827)], 39.365217879684835)
#(3.0, [('OSV', 0.08782631660673691), ('OVS', 0.12260891129806495), ('SOV', 0.7895647735059163)], 39.897390622338825)
#(3.0, [('OSV', 0.13739113240611028), ('OVS', 0.1278262572013252), ('SOV', 0.7347826118533806)], 39.733044182217206)
#(3.0, [('OSV', 0.09304365077136102), ('OVS', 0.1721737507996646), ('SOV', 0.7347825998861222)], 39.73304414487856)
#(3.0, [('SVO', 0.5860866415781372), ('VOS', 0.035652262316107686), ('VSO', 0.37826109736016045)], 39.45130461906728)
#(3.0, [('SVO', 0.3608698471693726), ('VOS', 0.03565227459439399), ('VSO', 0.6034778794931012)], 39.45130457838304)
#(3.0, [('SVO', 0.4660869804835546), ('VOS', 0.0504347756521164), ('VSO', 0.48347824510620463)], 39.40695707884063)

