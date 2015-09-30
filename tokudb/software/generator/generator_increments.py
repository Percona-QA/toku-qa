from datetime import datetime
import time
import random
import sys
import math
import string
import os
import base64

def generate_row(c_pk,c_1,c_10,c_100,c_1000,c_10000,c_100000,c_1000000,c_10000000,c_100000000,bigVarcharSize):
  #when = time.time() + (transactionid / 100000.0)
  #datetime = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(when))
  #big_varchar = ''.join(random.choice(string.letters) for i in xrange(128))
  big_varchar = base64.urlsafe_b64encode(os.urandom(bigVarcharSize))
  res = '"%d","%d","%d","%d","%d","%d","%d","%d","%d","%d","%s"' % (c_pk,c_1,c_10,c_100,c_1000,c_10000,c_100000,c_1000000,c_10000000,c_100000000,big_varchar)
  return res

def main():
  rowsToInsert = 50000000
  rowsToReport = 100000
  bigVarcharSize = 256
  csvName = 'stats_data.csv'

  random.seed(3221223452)
  start_time = time.time()
  rowsInserted = 0
  fo = open(csvName, "w")
  
  c_1 = 0
  c_10 = 1
  c_100 = 1
  c_1000 = 1
  c_10000 = 1
  c_100000 = 1
  c_1000000 = 1
  c_10000000 = 1
  c_100000000 = 1

  for r in range(rowsToInsert):
    rowsInserted = rowsInserted + 1
    
    if (rowsInserted % 1) == 0:
      c_1 = c_1 + 1
    if (rowsInserted % 10) == 0:
      c_10 = c_10 + 1
    if (rowsInserted % 100) == 0:
      c_100 = c_100 + 1
    if (rowsInserted % 1000) == 0:
      c_1000 = c_1000 + 1
    if (rowsInserted % 10000) == 0:
      c_10000 = c_10000 + 1
    if (rowsInserted % 100000) == 0:
      c_100000 = c_100000 + 1
    if (rowsInserted % 1000000) == 0:
      c_1000000 = c_1000000 + 1
    if (rowsInserted % 10000000) == 0:
      c_10000000 = c_10000000 + 1
    if (rowsInserted % 100000000) == 0:
      c_100000000 = c_100000000 + 1
    
    row = generate_row(rowsInserted,c_1,c_10,c_100,c_1000,c_10000,c_100000,c_1000000,c_10000000,c_100000000,bigVarcharSize)

    fo.write(row + "\n")

    if (rowsInserted % rowsToReport) == 0:
      now = time.time()
      pct = float(rowsInserted) / float(rowsToInsert) * 100.0
      seconds_to_go = 999999999
      minutes_to_go = 999999999
      if ((pct / 100) != 0):
        seconds_to_go = ((now - start_time) / (pct / 100)) - (now - start_time)
        minutes_to_go = seconds_to_go / 60.0
      print '%d %.1f %.1f %.4f %.1f %.1f' % (
          rowsInserted,
          now - start_time,
          rowsInserted / (now - start_time),
          pct,
          seconds_to_go,
          minutes_to_go)
      sys.stdout.flush()

  fo.close()
  return 0

sys.exit(main())
