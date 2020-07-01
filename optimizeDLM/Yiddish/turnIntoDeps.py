import readCorpus
#data = ("1462w-mints.ref")
from collections import defaultdict
templates = defaultdict(int)


def assignHeads(phrase, children):
   if len(children) < 1:
     pass
   elif phrase["category"].startswith("IP-") or phrase["category"].startswith("PRN") or phrase["category"].startswith("QTP"):
      numberOfVerbs = sum([1 if x["category"].startswith("VB") else 0 for x in phrase["children"]])
      if numberOfVerbs == 0:
         head = 0
         pass
      else:
        #assert numberOfVerbs== 1, children
        #print(children)
        head = [i for i in range(len(children)) if children[i].startswith("VB")][0]
      phrase["top_head"] = phrase["children"][head]
      for j in range(len(children)):
        phrase["children"][j]["direct_head"] = phrase["children"][head]
   elif phrase["category"].startswith("CP-"):
#      if children[0] in [ "C ", "WH ", "CONJ "] or children[1].startswith( "WH-") or children[1].startswith("C-"):
          numberOfVerbs = sum([1 if x["category"].startswith("VB") else 0 for x in phrase["children"]])
          if numberOfVerbs == 0:
             if any([x.startswith("MD") for x in children]):
                head = [i for i in range(len(children)) if children[i].startswith("MD")][0]
             elif any([x.get("word", "").startswith("%v") for x in phrase["children"]]):
                head = [i for i in range(len(children)) if phrase["children"][i].get("word", "").startswith("%v")][0]
             elif any([x.startswith("AUX") for x in children]):
                head = [i for i in range(len(children)) if children[i].startswith("AUX")][0]
             elif any([x.startswith("CP") for x in children]):
                head = [i for i in range(len(children)) if children[i].startswith("CP")][0]
             elif any([x.startswith("IP") for x in children]):
                head = [i for i in range(len(children)) if children[i].startswith("IP")][0]
             elif any([x.startswith("CONJ") for x in children]):
                head = [i for i in range(len(children)) if children[i].startswith("CONJ")][0]
             elif any([x.startswith("C ") for x in children]):
                head = [i for i in range(len(children)) if children[i].startswith("C ")][0]
             else:
                head = 0
#                print("ERROR", [x["category"] if x["category"] != "x" else x["word"] for x in phrase["children"]], children)
 #               return
          else:
              head = [i for i in range(len(children)) if children[i].startswith("VB")][0]
          phrase["top_head"] = phrase["children"][head]
          for j in range(len(children)):
            phrase["children"][j]["direct_head"] = phrase["children"][head]

   elif phrase["category"].startswith("PP"):
     head = 0
     phrase["top_head"] = phrase["children"][head]
     for j in range(len(children)):
       phrase["children"][j]["direct_head"] = phrase["children"][head]

#     pass
   elif len(children) == 1:
     head = 0
     phrase["top_head"] = phrase["children"][head]
     pass
   elif phrase["category"].startswith( "NP"):
     head = 0
     phrase["top_head"] = phrase["children"][head]
     for j in range(len(children)):
       phrase["children"][j]["direct_head"] = phrase["children"][head]
     pass
   elif phrase["category"].startswith("TMP"):
     head = 0
     phrase["top_head"] = phrase["children"][head]
     for j in range(len(children)):
       phrase["children"][j]["direct_head"] = phrase["children"][head]
#     pass
   elif phrase["category"] == "ADJP ":
     head = 0
     phrase["top_head"] = phrase["children"][head]
     for j in range(len(children)):
       phrase["children"][j]["direct_head"] = phrase["children"][head]
     pass
   elif phrase["category"].startswith("ADVP"):
     head = 0
     phrase["top_head"] = phrase["children"][head]
     for j in range(len(children)):
       phrase["children"][j]["direct_head"] = phrase["children"][head]
     pass
   elif phrase["category"].startswith("LOC"):
     head = 0
     phrase["top_head"] = phrase["children"][head]
     for j in range(len(children)):
       phrase["children"][j]["direct_head"] = phrase["children"][head]
     pass
#   elif phrase["category"].startswith("QTP"):
 #    print("ERROR", [x["category"] if x["category"] != "x" else x["word"] for x in phrase["children"]], children)
  #   pass
#   elif phrase["category"] == "PRN ":
 #    pass
   elif phrase["category"] == "XX ":
     head = 0
     phrase["top_head"] = phrase["children"][head]
     for j in range(len(children)):
       phrase["children"][j]["direct_head"] = phrase["children"][head]
     pass
   elif phrase["category"] == "C ":
     head = 0
     phrase["top_head"] = phrase["children"][head]
     for j in range(len(children)):
       phrase["children"][j]["direct_head"] = phrase["children"][head]
     pass
   else:
     head = 0
     phrase["top_head"] = phrase["children"][head]
     for j in range(len(children)):
       phrase["children"][j]["direct_head"] = phrase["children"][head]
     pass
   assert "top_head" in phrase, phrase["category"]

def recurse(phrase):
   for child in phrase["children"]:
       recurse(child)
   if len(phrase["children"]) > 0:
      children = [x["category"] for x in phrase["children"]]
      #if not all([x=="x" for x in children]):
      templates[(phrase["category"], tuple(children))]+=1
      assignHeads(phrase, children)
      assert "top_head" in phrase


def linearize(phrase, results):
   if len(phrase["children"]) == 0:
      results.append(phrase)
      phrase["index"] = len(results)

      if phrase["category"] in ["ID", "SA,Assaf"]:
       phrase["EXCLUDED"] = True
      elif phrase["category"] in ['."']:
       phrase["EXCLUDED"] = True
      elif phrase["category"] in ["shtik?", "}"]:
        phrase["EXCLUDED"] = True
      elif phrase["word"] in [".", ","] or "COM:" in phrase["word"]:
         phrase["EXCLUDED"] = True
      else:
       assert phrase["category"] == "x", phrase
       assert "EXCLUDED" not in phrase
      #print(phrase["category"], phrase["word"], phrase.get("EXCLUDED", False))

   else:
#      print(list(phrase))
      for child in phrase["children"]:
        linearize(child, results)
      assert "top_head" in phrase, phrase
      phrase["index"] = phrase["top_head"]["index"]

def createIndices(phrase):
    for x in phrase["children"]:
       createIndices(x)
    if "top_head" in phrase:
       if "index" not in phrase["top_head"]:
          assert False, (phrase["top_head"])
         

def createDependencies(phrase, head, category, dominating, isHead=True):
   phrase["head"] = head
   if phrase["category"] == "ID":
      assert len(phrase["children"]) == 0
      return
   if len(phrase["children"]) == 0:
#      assert phrase["category"] == "x", phrase
      phrase["DominatingCategory"] = dominating
      phrase["Label"] = category.strip()
      if category.strip() == dominating.strip() and not isHead:
         phrase["IsNonHeadCopy"] = True
      pass
   else:

      #print(phrase["category"])
#      print(list(phrase))
      createDependencies(phrase["top_head"], head, phrase["category"], category, isHead=True)
      for child in phrase["children"]:
        if child == phrase["top_head"]:
           continue
        createDependencies(child, phrase["top_head"]["index"], phrase["category"], phrase["category"], isHead=False )
      assert "top_head" in phrase, phrase


import os
def corpusIterator():
  for f in os.listdir("/juice/scr/mhahn/HISTORICAL_CORPORA/yiddish/babel.ling.upenn.edu/research-material/yiddish-corpus/parsed"):
   if not f.endswith(".ref"):
       continue
  # print(f)
   for x in readCorpus.readFromFile(f):
     recurse(x)
     results = []
     linearize(x, results)
     isExcluding = False
  #   print("=====")
     for r in results:
       if "{" in r["word"]:
          r["EXCLUDED"] = True
          #assert not isExcluding
          if "}" in r["word"]:
              pass
          else:
              isExcluding = True
       elif "}" in r["word"]:
          isExcluding = False
          r["EXCLUDED"] = True
       elif isExcluding:
         r["EXCLUDED"] = True
       elif r["word"].startswith("%"):
         r["EXCLUDED"] = True
   
       #print(r["word"], isExcluding, "EXCLUDED" in r)
  #   assert not isExcluding
     #results = results_
     #createIndices(x)
  
    
  #   print([x["word"] for x in results])
     createDependencies(x, 0, "ROOT", "ROOT")
     for z in results:
        #print({x: y for x, y in z.items() if x not in ["children", "top_head", "direct_head", "category"]})
        if z["head"] > 0 and results[z["head"]-1].get("EXCLUDED", False):
            head = z["head"]
            while results[head-1].get("EXCLUDED", False) and head > 0:
                   head = results[head-1]["head"]
            assert head == 0 or not results[head-1].get("EXCLUDED", False)
            z["head"] = head
     results_ = []
     renumbering = {}
     for r in results:
       if not r.get("EXCLUDED", False):
        results_.append(r)
        r["new_index"] = len(results_)
        renumbering[r["index"]] = len(results_)
       elif r["head"] == 0:
     #   print(r, len(results))
        for s in results:
           if s["head"] == r["index"]:
              s["head"] = 0
              break
#        quit()
#     assert len(results_) > 0
     if len(results) - len(results_) > 1:
        show = True
     else:
        show = False
     resultsOld = results
     results = results_
     for r in results:
       r["index"]= r["new_index"]
       if r["head"] > 0:
        r["head"] = renumbering[r["head"]]
     if show and False:
      for z in resultsOld:
        print({x: y for x, y in z.items() if x not in ["children", "top_head", "direct_head", "category"]})
      print("============================")
     for z in results:
 #       print({x: y for x, y in z.items() if x not in ["children", "top_head", "direct_head", "category"]})
          
        if "Label" not in z:
          z["Label"] = "--NONE--"
        if "EXCLUDED" in z:
           z["dep"] = "--NONE--"
        else:
          dominating =z["DominatingCategory"].strip()
          label = z["Label"].strip()
 #         print("BEFORE", (dominating, label))
#          print(label, dominating, label == dominating, "-" in label)
#          if label.startswith("NP") and dominating.startswith("NP"):
 #             print(label, dominating, "SAME?")
          if label == dominating and "-" in label:
             label = label[:label.index("-")]
#             print(label, dominating)
          if "-" in dominating:
             dominating = dominating[:dominating.index("-")]
          dominating = "".join([y for y in dominating if ord(y) > 57 or y == "-"])
          label = "".join([y for y in label if ord(y) > 57 or y == "-"])
          if label[-1] in ["-", "~"]:
            label = label[:-1]
#          print("AFTER", (dominating, label))        
          if "IsNonHeadCopy" in z:
          #   print((dominating, label, z["word"]))
             key = label+"_concat"
          else:
             key = label
          z["dep"] = key if "EXCLUDED" not in z else "--NONE--"
     if len(results) > 0:
        yield results, {"century" : f[:2]}
     #quit()
  #templates = sorted(list(templates.items()), key=lambda x:x[0])
  #for t in templates:
  #   print(t)
  
