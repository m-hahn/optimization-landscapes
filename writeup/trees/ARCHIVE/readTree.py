with open("../families.tsv", "r") as inFile:
    languages = [x for x in inFile.read().strip().split("\n")[1:]]
print(languages)
languages = [x[:x.index("\t")].replace("_2.6", "")  for x in languages]
languages = set(languages)

def recurse(node):
    name = node.name
    length = node.length
    if name is None:
        pass
    else:
        name = name[:name.index("[")].replace("'", "").strip()
        if "{" in name:
            name = name[:name.index("{")-1]
        if name in languages:
   #        print(name, len(node.descendants))
    #       print("RETURNING")
           return {"name" : node.name, "language" : name, "length" : length}
        else:
            None
    children = []
    for child in node.descendants:
        processed = recurse(child)
        if processed is None:
            continue
        else:
            children.append(processed)
  #          print(processed)
 #           print("IN", len(children))
#    print("OUT", len(children))
    if len(children) == 0:
        return None
    if len(children) == 1:
       children[0]["length"] += length
       return children[0]
    else:
        return {"name" : node.name, "length" : length, "children" : children}

from newick import loads
with open("/home/user/Downloads/41562_2018_457_MOESM4_ESM.csv", "r") as inFile:
    next(inFile)
    for line in inFile:
        family, tree_number, tree_source, bl_method, tree_set, tree = line.strip().split("\t")
        tree = loads(tree)
#        print(tree)
        for d in tree:
            resulting_tree = recurse(d)
            if resulting_tree is not None:
                print(resulting_tree)

