#!/bin/bash
SCRIPT_DIR=$(cd `dirname $0` && pwd)

if [ ${MYSQL_STORAGE_ENGINE} == "rocksdb" ]; then
  MYSQLD_OPTS="--mysqld=--plugin-load=rocksdb=ha_rocksdb.so --mysqld=--init-file=${SCRIPT_DIR}/MyRocks.sql --mysqld=--default-storage-engine=ROCKSDB"
elif [ ${MYSQL_STORAGE_ENGINE} == "tokudb" ]; then
  MYSQLD_OPTS="--mysqld=--plugin-load=tokudb=ha_tokudb.so --mysqld=--init-file=${SCRIPT_DIR}/TokuDB.sql --mysqld=--default-storage-engine=TOKUDB"
else
  MYSQL_OPTS=""
fi

if [ -z ${NUM_ROWS} -a  -z ${NUM_TABLES} ]; then
  NUM_ROWS=10
  NUM_TABLES=1000000
fi

if [ -z $3 ]; then
  echo "No valid parameters were passed. Need relative workdir (1st option), relative PS version (2nd option) settings and storage engine (3rd option). Retry."
  echo "Usage example:"
  echo "$./sysbench_create_db_template.sh /sda/datadir 56 innodb"
  echo "Supported storage engines : innodb/myisam/tokudb"
  exit 1
else
  WORK_DIR=$1
  PS_VERSION=$2
  SE=$3
fi

if [ -r /usr/lib64/libjemalloc.so.1 ]; then export LD_PRELOAD=/usr/lib64/libjemalloc.so.1
elif [ -r /usr/lib/x86_64-linux-gnu/libjemalloc.so.1 ]; then export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1
elif [ -r $WORK_DIR/$BASE/lib/mysql/libjemalloc.so.1 ]; then export LD_PRELOAD=$WORK_DIR/$BASE/lib/mysql/libjemalloc.so.1
else echo 'Error: jemalloc was not loaded as it was not found' ; exit 1; fi

echo "This script will create ${NUM_TABLES} tables with ${NUM_ROWS} rows in each tables"
cd $WORK_DIR
if [ -z ${DB_DIR} ]; then
  $SCRIPT_DIR/get_percona.sh $PS_VERSION 2 > ps_download.log 2>&1
  BASE=`ls -1d ?ercona-?erver* | grep -v ".tar" | head -n1`
  BASE=$WORK_DIR/$BASE
else
  BASE=${DB_DIR}
fi
if [ "`$BASE/bin/mysqld --version | grep -oe '5\.[1567]' | head -n1`" == "5.7" ]; then
  DATA_DIR="run_dir_57_${BENCH_SIZE}_$SE"
else
  DATA_DIR="run_dir_${BENCH_SIZE}_$SE"
fi

mkdir -p $WORK_DIR/${DATA_DIR}

$BASE/bin/mysqld --no-defaults --initialize-insecure --basedir=${DB_DIR} --datadir=$WORK_DIR/${DATA_DIR}/data >  ${DB_DIR}/startup.err 2>&1

$BASE/bin/mysqld ${MYEXTRA} $MYSQLD_OPTS  --basedir=${DB_DIR} --datadir=$WORK_DIR/${DATA_DIR}/data ${MYSQL_OPTS} --port=${MYSQL_PORT} --pid-file=${DB_DIR}/data/pid.pid --core-file --socket=$WORK_DIR/${DATA_DIR}/socket.sock --log-error=$WORK_DIR/${DATA_DIR}/data/error.log.out >  $WORK_DIR/${DATA_DIR}/data/mysqld.out 2>&1 &
	
for X in $(seq 0 60); do
  sleep 1
  if ${DB_DIR}/bin/mysqladmin -uroot -S$WORK_DIR/${DATA_DIR}/socket.sock ping > /dev/null 2>&1; then
    ${DB_DIR}/bin/mysql -uroot -S$WORK_DIR/${DATA_DIR}/socket.sock -e"create database test;"
    break
  fi
done
# Running sysbench
echo "Running sysbench"
if [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "0.5" ]; then
  sysbench --test=/usr/share/doc/sysbench/tests/db/parallel_prepare.lua --mysql-table-engine=$SE --rand-type=$RAND_TYPE --num-threads=${NUM_TABLES} --oltp-tables-count=${NUM_TABLES}  --oltp-table-size=${NUM_ROWS} --mysql-db=test --mysql-user=root  --db-driver=mysql --mysql-socket=$WORK_DIR/$DATA_DIR/socket.sock    run > $WORK_DIR/sysbench_prepare.log 2>&1
elif [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "1.0" ]; then
  sysbench /usr/share/sysbench/oltp_insert.lua --mysql-storage-engine=$SE --rand-type=$RAND_TYPE  --threads=${NUM_TABLES} --tables=${NUM_TABLES}  --table-size=${NUM_ROWS} --mysql-db=test --mysql-user=root    --db-driver=mysql --mysql-socket=$WORK_DIR/$DATA_DIR/socket.sock    prepare > $WORK_DIR/sysbench_prepare.log 2>&1
fi

#Stopping mysqld
echo "Stopping mysqld process"
$BASE/bin/mysqladmin --socket=$WORK_DIR/$DATA_DIR/socket.sock -uroot shutdown

echo "Data directory template is available in $WORK_DIR/$DATA_DIR/mysqld.1/data"

