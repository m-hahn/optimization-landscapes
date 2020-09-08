import sys


def readSWBDTreebank(partition):
      assert partition == "together"
      path = "/u/scr/mhahn/CORPORA/ptb-ud2/ptb-ud2-swbd.conllu"
      with open(path, "r") as inFile:
          data = inFile.read().strip().split("\n\n")
          if len(data) == 1:
            data = data[0].split("\r\n\r\n")
          assert len(data) > 1, (path, [len(x) for x in data], "\n\n" in data[0], "\r\n\r\n" in data[0] )
      assert len(data) > 0, (language, partition, files)
      print >> sys.stderr, "Read "+str(len(data))+ " sentences from 1 "+partition+" datasets."
      return data


