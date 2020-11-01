with open("output/additionalOrders.tex", "w") as outFile:
  with open("categoricalOrderAdditional.tsv", "r") as inFile:
    next(inFile)
    for line in inFile:

        if len(line) < 3:
            continue
        print(line)
        language, order, rationale = line.strip().split("\t")
        if language == "Ancient_Greek_2.6":
            continue
        language = language.replace("_2.6", "").replace("_", " ").replace("ISWOC", "")
        rationale = rationale.replace("GM&R", "\citet{gell-mann-origin-2011}")
        print(" & ".join([language, order, rationale])+ "\\\\", file=outFile)

