#/bin/bash

export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.38
export SCP_FILES=Y
export DIRECTIO=Y
export BENCHMARK_NUMBER=999
export ADDITIONAL_WRITERS=3
export MAX_ROWS=1000000000
export ROWS_PER_REPORT=100000
export RUN_MINUTES=1440
export UNIQUE_CHECKS=1
export INSERT_ONLY=1

export INNODB_CACHE=8G
export TOKUDB_DIRECTIO_CACHE=8G
export DEEPDB_CACHE_SIZE=8G

# ****** PMPROF ENABLED ******
#     ****** PMPROF ENABLED ******
#         ****** PMPROF ENABLED ******
#export PMPROF_ENABLED=Y

dateString=`date +%Y%m%d%H%M%S`

TRACE_FILE=/tmp/iibench-block-allocator-trace-${dateString}.log
rm -rf ${TRACE_FILE}

export TOKU_BA_TRACE_PATH=${TRACE_FILE}

export MYSQL_STORAGE_ENGINE=tokudb
export TARBALL=blank-tokudb.current.20140806-mysql-5.5.38
export MINI_BENCH_ID=batrace
export BENCH_ID=${MINI_BENCH_ID}-${TOKUDB_DIRECTIO_CACHE}G.quicklz
./run.benchmark.sh

scp ${TRACE_FILE} ${SCP_TARGET}:~

unset TOKU_BA_TRACE_PATH
