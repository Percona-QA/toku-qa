#!/bin/bash
SCRIPT_DIR=$(cd `dirname $0` && pwd)

if [ -z ${NUM_WAREHOUSES} ] && [ -z ${MYSQL_DATABASE} ]; then
  NUM_WAREHOUSES=10
  MYSQL_DATABASE=tpcc
fi

MYSQL_PORT=$RANDOM
if [ -z $3 ]; then
  echo "No valid parameters were passed. Need relative workdir (1st option), relative PS version (2nd option) settings and storage engine (3rd option). Retry."
  echo "Usage example:"
  echo "$./tpcc_create_db_template.sh /sda/datadir 56 innodb"
  echo "Supported storage engines : innodb/myisam/tokudb"
  exit 1
else
  WORK_DIR=$1
  PS_VERSION=$2
  SE=$3
fi

echo "This script will create ${NUM_WAREHOUSES} tpcc warehouses data"
cd $WORK_DIR
if [ -z ${DB_DIR} ]; then
  #$SCRIPT_DIR/get_percona.sh $PS_VERSION 2 > ps_download.log 2>&1
  BASE=`ls -1d ?ercona-?erver* | grep -v ".tar" | head -n1`
  BASE=$WORK_DIR/$BASE
else
  BASE=${DB_DIR}
fi

if [ -r /usr/lib64/libjemalloc.so.1 ]; then export LD_PRELOAD=/usr/lib64/libjemalloc.so.1
elif [ -r /usr/lib/x86_64-linux-gnu/libjemalloc.so.1 ]; then export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1
elif [ -r $BASE/lib/mysql/libjemalloc.so.1 ]; then export LD_PRELOAD=$BASE/lib/mysql/libjemalloc.so.1
else echo 'Error: jemalloc was not loaded as it was not found' ; exit 1; fi

if [ "`$BASE/bin/mysqld --version | grep -oe '5\.[1567]' | head -n1`" == "5.7" ]; then
  DATA_DIR="tpcc_data_dir_57_${SE}_${NUM_WAREHOUSES}"
else
  DATA_DIR="tpcc_data_dir_${SE}_${NUM_WAREHOUSES}"
fi

rm -Rf $WORK_DIR/$DATA_DIR
cd $BASE/mysql-test
perl mysql-test-run.pl \
  --start-and-exit --skip-ndb \
  --vardir=$WORK_DIR/$DATA_DIR \
  --mysqld=--port=$MYSQL_PORT \
  --mysqld=--core-file \
  --mysqld=--log-output=none \
  --mysqld=--secure-file-priv= \
  --mysqld=--max-connections=900 \
  --mysqld=--plugin-load=tokudb=ha_tokudb.so \
  --mysqld=--init-file=$SCRIPT_DIR/TokuDB.sql \
  --mysqld=--socket=$WORK_DIR/$DATA_DIR/socket.sock \
1st


$BASE/bin/mysqladmin --socket=$WORK_DIR/$DATA_DIR/socket.sock -uroot create ${MYSQL_DATABASE}

if [ ${SE} == "innodb" ]; then
  if [ "${INNODB_COMPRESSION}" == "Y" ]; then
    $BASE/bin/mysql --socket=$WORK_DIR/$DATA_DIR/socket.sock -uroot  ${MYSQL_DATABASE} < $SCRIPT_DIR/../tokudb/software/tpcc-percona/fastload/create_schema_${SE}_${INNODB_KEY_BLOCK_SIZE}.sql
  else
    $BASE/bin/mysql --socket=$WORK_DIR/$DATA_DIR/socket.sock -uroot ${MYSQL_DATABASE} <  $SCRIPT_DIR/../tokudb/software/tpcc-percona/fastload/create_schema_${SE}.sql
  fi
  $BASE/bin/mysql --socket=$WORK_DIR/$DATA_DIR/socket.sock -uroot  ${MYSQL_DATABASE} < $SCRIPT_DIR/../tokudb/software/tpcc-percona/fastload/innodb_add_idx.sql
  if [ "${INNODB_FK}" == "Y" ]; then
    $BASE/bin/mysql --socket=$WORK_DIR/$DATA_DIR/socket.sock -uroot ${MYSQL_DATABASE} < $SCRIPT_DIR/../tokudb/software/tpcc-percona/fastload/innodb_add_fkey.sql
  else
    $BASE/bin/mysql --socket=$WORK_DIR/$DATA_DIR/socket.sock -uroot ${MYSQL_DATABASE} < $SCRIPT_DIR/../tokudb/software/tpcc-percona/fastload/innodb_add_fkey_as_idx.sql
  fi
else
  $DB_DIR/bin/mysql --socket=$WORK_DIR/$DATA_DIR/socket.sock -uroot ${MYSQL_DATABASE} <  $SCRIPT_DIR/../tokudb/software/tpcc-percona/fastload/create_schema_${SE}.sql
fi

# Running tpcc data loading script
echo "Running tpcc data loading script"

if [ ! -f $WORK_DIR/tpcc-mysql/tpcc_load ]; then
  cd $WORK_DIR
  bzr branch lp:~percona-dev/perconatools/tpcc-mysql
  cd tpcc-mysql/src
  make > $WORK_DIR/tpcc-mysql-make.log 2>&1
fi

$WORK_DIR/tpcc-mysql/tpcc_load 127.0.0.1:$MYSQL_PORT ${MYSQL_DATABASE} root "" ${NUM_WAREHOUSES}
  
#Stopping mysqld
echo "Stopping mysqld process"
$BASE/bin/mysqladmin --socket=$WORK_DIR/$DATA_DIR/socket.sock -uroot shutdown

echo "Data directory template is available in $WORK_DIR/$DATA_DIR/mysqld.1/data"

