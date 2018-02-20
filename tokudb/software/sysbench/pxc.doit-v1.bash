#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi

#export threadCountList="0016 0032 0064 0128"
#export threadCountList="0001 0002 0004 0008 0016 0032 0064 0128 0256 0512 1024 2048"

if [ -z "$MYSQL_NAME" ]; then
    export MYSQL_NAME=mysql
fi
if [ -z "$MYSQL_VERSION" ]; then
    export MYSQL_VERSION=5.5.30
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    export MYSQL_STORAGE_ENGINE=tokudb
fi
if [ -z "$TARBALL" ]; then
    export TARBALL=blank-toku701-mysql-5.5.30
fi
if [ -z "$TOKUDB_COMPRESSION" ]; then
    export TOKUDB_COMPRESSION=lzma
fi
if [ -z "$BENCH_ID" ]; then
    export BENCH_ID=701.${TOKUDB_COMPRESSION}
fi
if [ -z "$NUM_ROWS" ]; then
    export NUM_ROWS=50000000
fi
if [ -z "$NUM_TABLES" ]; then
    export NUM_TABLES=16
fi
if [ -z "$NUM_DATABASES" ]; then
    export NUM_DATABASES=1
fi
if [ -z "$RUN_TIME_SECONDS" ]; then
    export RUN_TIME_SECONDS=900
fi
if [ -z "$RAND_TYPE" ]; then
    export RAND_TYPE=uniform
fi
if [ -z "$TOKUDB_READ_BLOCK_SIZE" ]; then
    export TOKUDB_READ_BLOCK_SIZE=64K
fi
if [ -z "$SKIP_DB_CREATE" ]; then
    export SKIP_DB_CREATE=N
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    export BENCHMARK_NUMBER=004
fi
if [ -z "$DIRECTIO" ]; then
    export DIRECTIO=Y
fi
if [ -z "$READONLY" ]; then
    export READONLY=off
fi

export BENCHMARK_LOGGING=Y
export LOADER_LOGGING=Y

export MYSQL_DATABASE=test
export MYSQL_USER=root

export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}

if [ -z "$INNODB_CACHE" ]; then
  echo "Need to set INNODB_CACHE"
  exit 1
fi
if [ ${DIRECTIO} == "N" ]; then
  MYSQL_OPTS="--innodb_flush_method=${INNODB_FLUSH_METHOD}"
fi
MYSQL_OPTS="$MYSQL_OPTS --innodb_buffer_pool_size=${INNODB_CACHE} --max_connections=2048"

if [ ${SKIP_DB_CREATE} == "N" ]; then
  timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${DB_DIR}/node1/pxc-mysql.sock shutdown > /dev/null 2>&1
  timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${DB_DIR}/node2/pxc-mysql.sock shutdown > /dev/null 2>&1
  timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${DB_DIR}/node3/pxc-mysql.sock shutdown > /dev/null 2>&1
  ps -ef | grep 'pxc-mysql.sock' | grep ${BUILD_NUMBER} | grep -v grep | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1 || true
  rm -Rf ${DB_DIR}/node*
  BIN=`find ${DB_DIR} -maxdepth 2 -name mysqld -type f -o -name mysqld-debug -type f | head -1`;if [ -z $BIN ]; then echo "Assert! mysqld binary '$BIN' could not be read";exit 1;fi
  export MYEXTRA="${MYEXTRA} ${MYSQL_OPTS}"
  if [ -d ${BIG_DIR}/sysbench_data_template/node1 ]; then
    cp -r ${BIG_DIR}/sysbench_data_template/node1 ${DB_DIR}/node1
    cp -r ${BIG_DIR}/sysbench_data_template/node2 ${DB_DIR}/node2
    cp -r ${BIG_DIR}/sysbench_data_template/node3 ${DB_DIR}/node3
  else
    mkdir ${BIG_DIR}/sysbench_data_template > /dev/null 2>&1
    ${SCRIPT_DIR}/pxc-startup.sh startup
    cp -r ${BIG_DIR}/sysbench_data_template/node1 ${DB_DIR}/node1
    cp -r ${BIG_DIR}/sysbench_data_template/node2 ${DB_DIR}/node2
    cp -r ${BIG_DIR}/sysbench_data_template/node3 ${DB_DIR}/node3
  fi
  ## Starting pxc nodes 
  ${SCRIPT_DIR}/pxc-startup.sh
else
  export MYEXTRA="${MYEXTRA} ${MYSQL_OPTS}"
  timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${DB_DIR}/node1/pxc-mysql.sock shutdown > /dev/null 2>&1
  timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${DB_DIR}/node2/pxc-mysql.sock shutdown > /dev/null 2>&1
  timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${DB_DIR}/node3/pxc-mysql.sock shutdown > /dev/null 2>&1
  ps -ef | grep 'pxc-mysql.sock' | grep ${BUILD_NUMBER} | grep -v grep | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1 || true
  if [ -d ${BIG_DIR}/sysbench_data_template/node1 ]; then
    cp -r ${BIG_DIR}/sysbench_data_template/node1 ${DB_DIR}/node1
    cp -r ${BIG_DIR}/sysbench_data_template/node2 ${DB_DIR}/node2
    cp -r ${BIG_DIR}/sysbench_data_template/node3 ${DB_DIR}/node3
  else
    echo "Assert! could not find data directory template.."
    exit 1
  fi
  ## Starting pxc nodes
  #BIN=`find ${DB_DIR} -maxdepth 2 -name mysqld -type f -o -name mysqld-debug -type f | head -1`;if [ -z $BIN ]; then echo "Assert! mysqld binary '$BIN' could not be read";exit 1;fi
  ${SCRIPT_DIR}/pxc-startup.sh
fi

echo "Running benchmark"
./pxc.run.benchmark-v1.sh
cp ${DB_DIR}/node1/*err ${BIG_DIR}/${BUILD_NUMBER}/${BENCH_ID}_node1.err
cp ${DB_DIR}/node2/*err ${BIG_DIR}/${BUILD_NUMBER}/${BENCH_ID}_node2.err
cp ${DB_DIR}/node3/*err ${BIG_DIR}/${BUILD_NUMBER}/${BENCH_ID}_node3.err

echo "Stopping database"
timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${DB_DIR}/node1/pxc-mysql.sock shutdown > /dev/null 2>&1
timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${DB_DIR}/node2/pxc-mysql.sock shutdown > /dev/null 2>&1
timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${DB_DIR}/node3/pxc-mysql.sock shutdown > /dev/null 2>&1
ps -ef | grep 'pxc-mysql.sock' | grep ${BUILD_NUMBER} | grep -v grep | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1 || true
