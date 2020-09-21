from corpusIterator_V import CorpusIterator_V as CorpusIterator

with open("perseus-authors.txt", "r") as inFile:
   perseusAuthors = inFile.read().strip().split("\n")
print(perseusAuthors)
perseusAuthors = {x[1] : int(x[2]) for x in [y.split("\t") for y in perseusAuthors]}
print(perseusAuthors)
with open("perseus-docs.txt", "r") as inFile:
   perseusDocs = inFile.read().strip().split("\n")
fromDocToYear = {}
for i in range(0, len(perseusDocs), 3):
  author = perseusDocs[i].replace("=", "").strip()
  filename = perseusDocs[i+1]
  filename = filename[filename.rfind("/")+1:]
  print(author, filename, perseusAuthors[author])
  fromDocToYear[filename] = perseusAuthors[author]

from collections import defaultdict
data = list(CorpusIterator("Ancient_Greek_2.6","together").iterator())
byYear = defaultdict(int)
for sent in data:
  metadata = sent[1]
  if "source" in metadata:
    year = 100 if "New Test" in metadata["source"] else (-450 if "Histories" in metadata["source"] else "NA")
    byYear[year] += len(sent[0])
  elif "sent_id" in metadata:
    text_id = metadata["sent_id"]
    text_id = text_id[:text_id.index("@")]
#    print()
    byYear[fromDocToYear[text_id]] += len(sent[0])


print(sorted(list(byYear.iteritems())))


# [(-700, 92689), (-500, 1529), (-450, 127177), (-400, 10396), (-50, 16882), (100, 142070), (200, 26245)]

# Suggested:
# Archaic -6th	92689 
# Classical -5th to -4th	1529+127177+10396=139102
# Koine -3th to +4th	16882+142070+26245=185197



