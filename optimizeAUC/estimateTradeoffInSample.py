from math import log
# Based on memory-surprisal/code/NOT_USED/optimization/verifyAUCCOmputation.py

def estimateTradeoffInSample(train, args):
    """
    Inputs:
       - train (list): input. IMPORTANT: padding symbols are expected to be encoded as zeros
       - args (dict). Entries:
           -- cutoff
    Outputs:
       - auc
       - trainSurprisalTable
    """

    wordsWithoutSentinels = len([x for x in train if x != 0])

 
    array = train    
    #print array
    numberOfRelevantSentences = 1
    print("Sorting "+str(numberOfRelevantSentences)+" sentences.")
    if numberOfRelevantSentences == 0:
        return 1.0
    indices = range(len(array))
    indices = sorted(indices, key=lambda x:array[x:x+args.cutoff])
    #print indices
    print("Now calculating information")
    
    # bigram surprisal
    startOfCurrentPrefix = None
    
    
    endPerStart = [None for _ in range(len(indices))]
    endPerStart[0] = len(endPerStart)-1
    
    lastCrossEntropy = 10000
    
    trainSurprisalTable = []
    
    for contextLength in range(0, args.cutoff-1):
          crossEntropy = 0
          totalSum = 0
          i = 0
          lengthsOfSuffixes = 0
          countTowardsSurprisal = 0
          while i < len(indices):
               while endPerStart[i] is None:
                   i += 1
               endOfCurrentPrefix = endPerStart[i] # here, end means the last index (not the one where a new thing starts)
               endPerStart[i] = None
               assert endOfCurrentPrefix is not None, (i, len(indices))
               # now we know the range where the current prefix occurs
               countOfCurrentPrefix = ((endOfCurrentPrefix-i+1)) # if contextLength >= 1 else wordsWithoutSentinels)
               assert countOfCurrentPrefix >= 1
               startOfCurrentSuffix = i
               j = i
               firstNonSentinelSuffixForThisPrefix = i # by default, will be modified in time in case sentinels show up
               probSumForThisPrefix = 0
               while j <= endOfCurrentPrefix:
                    # is j the last one?
       
                    assert j == endOfCurrentPrefix or j+1 < len(indices), (i,j)
       
                    assert j < len(indices)
       
                    # when there is nothing to predict
                    if indices[j]+contextLength >= len(array):
                        j+=1
                        startOfCurrentSuffix+=1
                        continue 
       
                    assert indices[startOfCurrentSuffix]+contextLength < len(array), (i,j)
                    assert j >= i
                    assert endOfCurrentPrefix >= j
                    if j == endOfCurrentPrefix or indices[j+1]+contextLength >= len(array) or array[indices[j+1]+contextLength] != array[indices[startOfCurrentSuffix]+contextLength]:
                      endOfCurrentSuffix = j # here, end means the last index (not the one where a new thing starts)
                      lengthOfCurrentSuffix =  endOfCurrentSuffix - startOfCurrentSuffix + 1
                      lengthsOfSuffixes += lengthOfCurrentSuffix
       
                      if array[indices[startOfCurrentSuffix]+contextLength] != 0: # don't incur loss for predicting sentinel
                         countOfCurrentPrefixWithoutSentinelSuffix = endOfCurrentPrefix - firstNonSentinelSuffixForThisPrefix + 1 # here important that sentinel comes first when sorting (is 0)
                         assert countOfCurrentPrefixWithoutSentinelSuffix <= countOfCurrentPrefix, ["endOfCurrentPrefix", endOfCurrentPrefix, "firstNonSentinelSuffixForThisPrefix", firstNonSentinelSuffixForThisPrefix, "i", i]
                         conditionalProbability = float(lengthOfCurrentSuffix) / countOfCurrentPrefixWithoutSentinelSuffix
                         probSumForThisPrefix += conditionalProbability
                         surprisal = -log(conditionalProbability)
                         probabilityThatThisSurprisalIsIncurred = float(lengthOfCurrentSuffix) / wordsWithoutSentinels
                         crossEntropy += probabilityThatThisSurprisalIsIncurred * surprisal
                         totalSum += probabilityThatThisSurprisalIsIncurred
                         countTowardsSurprisal += lengthOfCurrentSuffix
                      else:
                         firstNonSentinelSuffixForThisPrefix = j+1
                      endPerStart[startOfCurrentSuffix] = endOfCurrentSuffix
                      startOfCurrentSuffix = j+1
                    if j == endOfCurrentPrefix:
                      break
                    if indices[j+1]+contextLength >= len(array):
                       startOfCurrentSuffix = j+2
                       j+=2
                    else:
                       j+=1
               i = endOfCurrentPrefix+1
               assert lengthsOfSuffixes >= i-contextLength
               assert min(abs(probSumForThisPrefix - 0.0), abs(probSumForThisPrefix - 1.0)) < 0.001, probSumForThisPrefix
          assert i-lengthsOfSuffixes == contextLength
          #assert lastCrossEntropy >= crossEntropy
       
          print("==================================================countTowardsSurprisal", countTowardsSurprisal)
          print("CONTEXT LENGTH "+str(contextLength)+"   "+str( crossEntropy)+"  "+str((lastCrossEntropy-crossEntropy)))
          assert abs(totalSum - 1.0) < 0.001, totalSum
       
      
          lastCrossEntropy = crossEntropy
          trainSurprisalTable.append(crossEntropy)
    print(trainSurprisalTable)
    mis = [trainSurprisalTable[i] - trainSurprisalTable[i+1] for i in range(len(trainSurprisalTable)-1)]
    tmis = [mis[x]*(x+1) for x in range(len(mis))]
    auc = 0
    memory = 0
    mi = 0
    for i in range(len(mis)):
       mi += mis[i]
       memory += tmis[i]
       auc += mi * tmis[i]
    assert 20>memory, memory
    auc += mi * (20-memory)
    auc = 20*trainSurprisalTable[0] - auc
    return auc, trainSurprisalTable

