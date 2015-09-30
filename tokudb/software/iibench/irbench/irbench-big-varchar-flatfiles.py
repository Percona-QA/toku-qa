#!/usr/bin/python -W ignore::DeprecationWarning
#
# Copyright (C) 2009 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Implements a modified version of the insert benchmark as defined by Tokutek.

   A typical command line is:
     iibench.py --db_user=foo --db_password=bar --max_rows=1000000000

   Results are printed after each rows_per_reports rows are inserted.
   The output is:
     Legend:
       #rows = total number of rows inserted
       #seconds = number of seconds for the last insert batch
       #total_seconds = total number of seconds the test has run
       cum_ips = #rows / #total_seconds
       table_size = actual table size (inserts - deletes)
       last_ips = #rows / #seconds
       #queries = total number of queries
       cum_qps = #queries / #total_seconds
       last_ips = #queries / #seconds
       #rows #seconds cum_ips table_size last_ips #queries cum_qps last_qps
     1000000 895 1118 1000000 1118 5990 5990 7 7
     2000000 1897 1054 2000000 998 53488 47498 28 47

  The insert benchmark is defined at http://blogs.tokutek.com/tokuview/iibench

  This differs with the original by running queries concurrent with the inserts.
  For procesess are started and each is assigned one of the indexes. Each
  process then runs index-only queries in a loop that scan and fetch data
  from rows_per_query index entries.

  This depends on multiprocessing which is only in Python 2.6. Backports to
  2.4 and 2.5 are at http://code.google.com/p/python-multiprocessing
"""

__author__ = 'Mark Callaghan'

import optparse
from datetime import datetime
import time
import random
import sys
import math
import string
import os
import base64

#
# flags module, on loan from gmt module by Chip Turner.
#

FLAGS = optparse.Values()
parser = optparse.OptionParser()

def DEFINE_string(name, default, description, short_name=None):
  if default is not None and default != '':
    description = "%s (default: %s)" % (description, default)
  args = [ "--%s" % name ]
  if short_name is not None:
    args.insert(0, "-%s" % short_name)

  parser.add_option(type="string", help=description, *args)
  parser.set_default(name, default)
  setattr(FLAGS, name, default)

def DEFINE_integer(name, default, description, short_name=None):
  if default is not None and default != '':
    description = "%s (default: %s)" % (description, default)
  args = [ "--%s" % name ]
  if short_name is not None:
    args.insert(0, "-%s" % short_name)

  parser.add_option(type="int", help=description, *args)
  parser.set_default(name, default)
  setattr(FLAGS, name, default)

def DEFINE_boolean(name, default, description, short_name=None):
  if default is not None and default != '':
    description = "%s (default: %s)" % (description, default)
  args = [ "--%s" % name ]
  if short_name is not None:
    args.insert(0, "-%s" % short_name)

  parser.add_option(action="store_true", help=description, *args)
  parser.set_default(name, default)
  setattr(FLAGS, name, default)

def ParseArgs(argv):
  usage = sys.modules["__main__"].__doc__
  parser.set_usage(usage)
  unused_flags, new_argv = parser.parse_args(args=argv, values=FLAGS)
  return new_argv

def ShowUsage():
  parser.print_help()

#
# options
#

DEFINE_integer('rows_per_report', 100000, '#rows per progress report printed to stdout.')
DEFINE_integer('cashregisters', 1000, '# cash registers')
DEFINE_integer('products', 10000, '# products')
DEFINE_integer('customers', 100000, '# customers')
DEFINE_integer('max_price', 500, 'Maximum value for price column')
DEFINE_integer('max_rows', 10000, 'Number of rows to insert')
DEFINE_integer('max_table_rows', 500000000, 'number of rows to create')
DEFINE_string('file_name', './irbench.csv', 'name of file to create')

#
# iibench
#

def generate_row(transactionid):
  when = time.time() + (transactionid / 100000.0)
  datetime = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(when))
  cashregisterid = random.randrange(0, FLAGS.cashregisters)
  productid = random.randrange(0, FLAGS.products)
  customerid = random.randrange(0, FLAGS.customers)
  price = ((random.random() * FLAGS.max_price) + customerid) / 100.0
  #big_varchar = ''.join(random.choice(string.letters) for i in xrange(128))
  big_varchar = base64.urlsafe_b64encode(os.urandom(128))
  res = '"%d","%s","%d","%d","%d","%.2f","%s"' % (transactionid,datetime,cashregisterid,customerid,productid,price,big_varchar)
  return res

def Insert():
  # generate insert rows in this loop and place into queue as they're
  # generated.  The execution process will pull them off from here.
  start_time = time.time()
  transactionid = 0
  fo = open(FLAGS.file_name, "w")

  for r in xrange(FLAGS.max_table_rows):
    transactionid = transactionid + 1
    row = generate_row(transactionid)

    fo.write(row + "\n")

    if (transactionid % FLAGS.rows_per_report) == 0:
      now = time.time()
      pct = float(transactionid) / float(FLAGS.max_table_rows) * 100.0
      seconds_to_go = 999999999
      minutes_to_go = 999999999
      if ((pct / 100) != 0):
        seconds_to_go = ((now - start_time) / (pct / 100)) - (now - start_time)
        minutes_to_go = seconds_to_go / 60.0
      print '%d %.1f %.1f %.4f %.1f %.1f' % (
          transactionid,
          now - start_time,
          transactionid / (now - start_time),
          pct,
          seconds_to_go,
          minutes_to_go)
      sys.stdout.flush()

  fo.close()

def main(argv):
  random.seed(3221223452)
  Insert()
  return 0

if __name__ == '__main__':
  new_argv = ParseArgs(sys.argv[1:])
  sys.exit(main([sys.argv[0]] + new_argv))
