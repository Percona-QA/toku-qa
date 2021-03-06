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

import os
import base64
import string
import MySQLdb
from multiprocessing import Queue, Process, Pipe, Array
import optparse
from datetime import datetime
import time
import random
import sys
import math

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

DEFINE_string('engine', 'innodb', 'Storage engine for the table')
DEFINE_string('db_name', 'test', 'Name of database for the test')
DEFINE_string('db_user', 'root', 'DB user for the test')
DEFINE_string('db_password', '', 'DB password for the test')
DEFINE_string('db_host', 'localhost', 'Hostname for the test')
DEFINE_integer('rows_per_commit', 1000, '#rows per transaction')
DEFINE_integer('rows_per_report', 1000000,
               '#rows per progress report printed to stdout. If this '
               'is too small, some rates may be negative.')
DEFINE_integer('seconds_per_report', -1,'#seconds per progress report, -1 means ignore.')
DEFINE_integer('rows_per_query', 1000,
               'Number of rows per to fetch per query. Each query '
               'thread does one query per insert.')
DEFINE_integer('cashregisters', 1000, '# cash registers')
DEFINE_integer('products', 10000, '# products')
DEFINE_integer('customers', 100000, '# customers')
DEFINE_integer('max_price', 500, 'Maximum value for price column')
DEFINE_integer('max_rows', 10000, 'Number of rows to insert')
DEFINE_boolean('insert_only', False,
               'When True, only run the insert thread. Otherwise, '
               'start 4 threads to do queries.')
DEFINE_string('table_name', 'purchases_index',
              'Name of table to use')
DEFINE_boolean('setup', False,
               'Create table. Drop and recreate if it exists.')
DEFINE_integer('warmup', 0, 'TODO')
DEFINE_string('db_socket', '/tmp/mysql.sock', 'socket for mysql connect')
DEFINE_string('db_config_file', '', 'MySQL configuration file')
DEFINE_integer('max_table_rows', 10000000, 'Maximum number of rows in table')
DEFINE_boolean('with_max_table_rows', False,
               'When True, allow table to grow to max_table_rows, then delete oldest')
DEFINE_boolean('read_uncommitted', False, 'Set cursor isolation level to read uncommitted')
DEFINE_integer('unique_checks', 1, 'Set unique_checks')
DEFINE_integer('tokudb_commit_sync', 1, 'Flush transaction log when transactions commit.')
DEFINE_integer('run_minutes', -1, 'Number of minutes to run, -1 = run to max_rows.')
DEFINE_integer('max_ips', -1, 'Maximum inserts per second, -1 = go ahead, make my day.')
DEFINE_boolean('innodb_compression', False,'Enable innodb compression.')
DEFINE_integer('innodb_key_block_size', 8,'Key block size when innodb compression enabled.')
DEFINE_boolean('clustering', False,'Create clustering index for queries.')
DEFINE_integer('data_length_max', 10, 'Max size of data in data column')
DEFINE_integer('data_length_min', 10, 'Min size of data in data column')
DEFINE_integer('data_random_pct', 50, 'Percentage of row that has random data')


#
# iibench
#

insert_done='insert_done'

def get_conn():
  return MySQLdb.connect(host=FLAGS.db_host, user=FLAGS.db_user,
                         db=FLAGS.db_name, passwd=FLAGS.db_password,
                         unix_socket=FLAGS.db_socket, read_default_file=FLAGS.db_config_file)

def create_table():
  conn = get_conn()
  cursor = conn.cursor()
  cursor.execute('drop table if exists %s' % FLAGS.table_name)

  extraDDL=''
  
  if FLAGS.innodb_compression:
    # print 'enabling innodb compression, key_block_size = %d' % (FLAGS.innodb_key_block_size)
    extraDDL='ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=%d' % (FLAGS.innodb_key_block_size)

  if FLAGS.clustering:
    print 'creating clustered key'
    keytype='clustering key'
  else:
    print 'creating non-clustered key'
    keytype='key'
  
  cursor.execute('create table %s ( '
                 'transactionid int not null auto_increment, '
                 'dateandtime datetime, '
                 'cashregisterid int not null, '
                 'customerid int not null, '
                 'productid int not null, '
                 'price float not null, '
                 'data varchar(4000), '
                 'primary key (transactionid), '
                 '%s registerproduct (cashregisterid, productid)) '
                 'engine=%s %s' % (FLAGS.table_name, keytype, FLAGS.engine, extraDDL))
  cursor.close()
  conn.close()

def get_max_pk(conn):
  cursor = conn.cursor()
  cursor.execute('select max(transactionid) from %s' % FLAGS.table_name)
  # catch empty database
  try:
    max_pk = int(cursor.fetchall()[0][0])
  except:
    max_pk = 0
  cursor.close()
  return max_pk

def generate_cols():
  cashregisterid = random.randrange(0, FLAGS.cashregisters)
  productid = random.randrange(0, FLAGS.products)
  customerid = random.randrange(0, FLAGS.customers)
  price = ((random.random() * FLAGS.max_price) + customerid) / 100.0
  data_len = random.randrange(FLAGS.data_length_min, FLAGS.data_length_max+1)
  # multiply by 0.75 to account of base64 overhead
  rand_data_len = int(data_len * 0.75 * (float(FLAGS.data_random_pct) / 100))
  rand_data = base64.b64encode(os.urandom(rand_data_len))
  nonrand_data_len = data_len - len(rand_data)
  data = '%s%s' % ('a' * nonrand_data_len, rand_data)
  return cashregisterid, productid, customerid, price, data

def generate_row(datetime):
  cashregisterid, productid, customerid, price, data = generate_cols()
  res = '("%s",%d,%d,%d,%.2f,"%s")' % (
      datetime,cashregisterid,customerid,productid,price,data)
  return res

def generate_pk_query(row_count, start_time):
  if FLAGS.with_max_table_rows and row_count > FLAGS.max_table_rows :
    pk_txid = row_count - FLAGS.max_table_rows + random.randrange(FLAGS.max_table_rows)
  else:
    pk_txid = random.randrange(max(row_count,1))

  sql = 'SELECT transactionid FROM %s WHERE '\
        '(transactionid >= %d) LIMIT %d' % (
      FLAGS.table_name, pk_txid, FLAGS.rows_per_query)
  return sql

def generate_register_query(row_count, start_time):
  productid = random.randrange(0, FLAGS.products)
  cashregisterid = random.randrange(0, FLAGS.cashregisters)

  sql = 'SELECT dateandtime,customerid,price,data FROM %s '\
        'FORCE INDEX (registerproduct) WHERE '\
        'cashregisterid = %d and productid > %d '\
        'LIMIT %d' % (
      FLAGS.table_name, cashregisterid, productid, FLAGS.rows_per_query)
  return sql

def generate_insert_rows(row_count):
  when = time.time() + (row_count / 100000.0)
  datetime = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(when))
#  rows = [generate_row(datetime) for i in xrange(FLAGS.rows_per_commit)]
  rows = [generate_row(datetime) for i in range(min(FLAGS.rows_per_commit, FLAGS.max_rows))]
  return ',\n'.join(rows)

def Query(max_pk, query_func, shared_arr):
  db_conn = get_conn()

  row_count = max_pk
  start_time = time.time()
  loops = 0

  cursor = db_conn.cursor()
  if FLAGS.read_uncommitted:  cursor.execute('set transaction isolation level read uncommitted')

  while True:
    query = query_func(row_count, start_time)
    cursor.execute(query)
    count = len(cursor.fetchall())
    loops += 1
    if (loops % 4) == 0:
      row_count = shared_arr[0]
      shared_arr[1] = loops
      if not FLAGS.read_uncommitted:
        cursor.execute('commit')

  cursor.close()
  db_conn.close()

def get_latest(counters, row_count):
  total = 0
  for c in counters:
    total += c[1]
    c[0] = row_count
  return total

def Insert(rounds, max_pk, insert_q, pdc_arr, pk_arr, market_arr, register_arr):
  # generate insert rows in this loop and place into queue as they're
  # generated.  The execution process will pull them off from here.
  start_time = time.time()
  prev_time = start_time
  last_ips_time = start_time
  inserted = 0
  last_ips_rows = inserted
  last_num_minutes = 0

  counters = [pdc_arr, pk_arr, market_arr, register_arr]
  for c in counters:
    c[0] = max_pk

  prev_sum = 0
  prev_inserted = 0
  table_size = 0
  # we use the tail pointer for deletion - it tells us the first row in the
  # table where we should start deleting
  tail = 0
  sum_queries = 0
  interval_number = 1

  for r in xrange(rounds):
    if (FLAGS.run_minutes > 0):
      # check how many minutes we've run for
      num_minutes = round((time.time() - start_time) / 60,1)

      #if (num_minutes > last_num_minutes):
      #  print '  ** %.1f minutes elapsed' % (num_minutes)
      #  last_num_minutes = num_minutes

      # tmc1
      if (num_minutes >= FLAGS.run_minutes):
        now = time.time()
        if not FLAGS.insert_only:
          sum_queries = get_latest(counters, max_pk + inserted)
        print '%d %.1f %.1f %.1f %d %.1f %.0f %.1f %.1f' % (
            inserted + max_pk,
            now - prev_time,
            now - start_time,
            inserted / (now - start_time),
            table_size,
            (inserted - prev_inserted) / (now - prev_time),
            sum_queries,
            sum_queries / (now - start_time),
            (sum_queries - prev_sum) / (now - prev_time))
        sys.stdout.flush()
        break

    if (FLAGS.max_ips > 0):
      now_ips = time.time()
      if (now_ips - last_ips_time > 1):
        last_ips_time = now_ips
        last_ips_rows = inserted
      else:
        if (inserted - last_ips_rows >= FLAGS.max_ips):
          # sit in a loop
          now_ips = time.time()
          while (now_ips - last_ips_time < 1):
            # print 'sleeping in timer loop'
            time.sleep(.1)
            now_ips = time.time()
          last_ips_time = now_ips
          last_ips_rows = inserted

    rows = generate_insert_rows(max_pk + inserted)
    sql = 'insert into %s '\
          '(dateandtime,cashregisterid,customerid,productid,price,data) '\
          'values %s' % (FLAGS.table_name, rows)
    insert_q.put(sql)
    inserted += FLAGS.rows_per_commit
    table_size += FLAGS.rows_per_commit

    # tmc2
    num_seconds_interval = (time.time() - prev_time)

    if (((inserted % FLAGS.rows_per_report) == 0) and (FLAGS.rows_per_report > 0)):
      # row based interval reporting
      now = time.time()
      if not FLAGS.insert_only:
        sum_queries = get_latest(counters, max_pk + inserted)
      print '%d %.1f %.1f %.1f %d %.1f %.0f %.1f %.1f' % (
          inserted + max_pk,
          now - prev_time,
          now - start_time,
          inserted / (now - start_time),
          table_size,
          (inserted - prev_inserted) / (now - prev_time),
          sum_queries,
          sum_queries / (now - start_time),
          (sum_queries - prev_sum) / (now - prev_time))
      sys.stdout.flush()
      prev_time = now
      prev_sum = sum_queries
      prev_inserted = inserted
      interval_number = interval_number + 1
    elif ((num_seconds_interval >= FLAGS.seconds_per_report) and (FLAGS.seconds_per_report > 0)):
      # time based interval reporting
      now = time.time()
      if not FLAGS.insert_only:
        sum_queries = get_latest(counters, max_pk + inserted)
      print '%d %.1f %.1f %.1f %d %.1f %.0f %.1f %.1f' % (
          inserted + max_pk,
          FLAGS.seconds_per_report,
          FLAGS.seconds_per_report * interval_number,
          inserted / (now - start_time),
          table_size,
          (inserted - prev_inserted) / (now - prev_time),
          sum_queries,
          sum_queries / (now - start_time),
          (sum_queries - prev_sum) / (now - prev_time))
      sys.stdout.flush()
      prev_time = now
      prev_sum = sum_queries
      prev_inserted = inserted
      interval_number = interval_number + 1

    # deletes
    if FLAGS.with_max_table_rows:
      if table_size > FLAGS.max_table_rows:
        sql = ('delete from %s where(transactionid>=%d and transactionid<%d);'
               % (FLAGS.table_name, tail, tail + FLAGS.rows_per_commit))
        insert_q.put(sql)
        table_size -= FLAGS.rows_per_commit
        tail += FLAGS.rows_per_commit

  # block until the queue is empty
  insert_q.put(insert_done)
  insert_q.close()

def statement_executor(stmt_q, db_conn, cursor):

  while True:
    stmt = stmt_q.get()  # get the statement we need to execute from the queue

    if stmt == insert_done: break
    # execute statement and commit
    cursor.execute(stmt)
    db_conn.commit()
  stmt_q.close()

def run_benchmark():
  random.seed(3221223452)
  rounds = int(math.ceil(float(FLAGS.max_rows) / FLAGS.rows_per_commit))

  if FLAGS.setup:
    create_table()
    max_pk = 0
  else:
    conn = get_conn()
    max_pk = get_max_pk(conn)
    conn.close()

  # Get the queries set up
  pdc_count = Array('i', [0,0])
  pk_count = Array('i', [0,0])
  market_count = Array('i', [0,0])
  register_count = Array('i', [0,0])

  if not FLAGS.insert_only:
    query_register = Process(target=Query, args=(max_pk, generate_register_query, register_count))

  # set up a queue that will be shared across the insert generation / insert
  # execution processes

  db_conn = get_conn()
  cursor = db_conn.cursor()
  if FLAGS.engine == 'tokudb':
    cursor.execute('set tokudb_commit_sync=%d' % (FLAGS.tokudb_commit_sync))

  cursor.execute('set unique_checks=%d' % (FLAGS.unique_checks))

  stmt_q = Queue(1)
  insert_delete = Process(target=statement_executor, args=(stmt_q, db_conn, cursor))
  inserter = Process(target=Insert, args=(rounds,max_pk,stmt_q,
                        pdc_count, pk_count, market_count, register_count))

  # start up the insert execution process with this queue
  insert_delete.start()
  inserter.start()

  # start up the query processes
  if not FLAGS.insert_only:
    query_register.start()

  # block until the inserter is done
  insert_delete.join()

  # close the connection and then terminate the insert / delete process
  cursor.close()
  db_conn.close()
  inserter.terminate()
  insert_delete.terminate()

  if not FLAGS.insert_only:
    query_register.terminate()

  print 'Done'

def main(argv):
  print '#rows #seconds #total_seconds cum_ips table_size last_ips #queries cum_qps last_qps'
  run_benchmark()
  return 0

if __name__ == '__main__':
  new_argv = ParseArgs(sys.argv[1:])
  sys.exit(main([sys.argv[0]] + new_argv))
