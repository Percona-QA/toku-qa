#/bin/bash

export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.39
export SCP_FILES=Y
export DIRECTIO=Y
export BENCHMARK_NUMBER=999
export ADDITIONAL_WRITERS=0
export MAX_ROWS=100000000
export ROWS_PER_REPORT=100000
export RUN_MINUTES=10
export UNIQUE_CHECKS=1
export INSERT_ONLY=1

export INNODB_CACHE=4G
export TOKUDB_DIRECTIO_CACHE=4G

# ****** PMPROF ENABLED ******
#     ****** PMPROF ENABLED ******
#         ****** PMPROF ENABLED ******
#export PMPROF_ENABLED=Y

# TokuDB - MySQL 5.5
export TARBALL=blank-toku750-mysql-5.5.39
export MYSQL_STORAGE_ENGINE=tokudb
export DIRECTIO=Y
export TOKUDB_READ_BLOCK_SIZE=64K
export TOKUDB_COMPRESSION=quicklz
export BENCH_ID=${MINI_BENCH_ID}-${TOKUDB_DIRECTIO_CACHE}G.quicklz
./run.benchmark.sh
