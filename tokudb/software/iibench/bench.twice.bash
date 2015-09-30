#/bin/bash

export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.39
export SCP_FILES=Y
export DIRECTIO=Y
export BENCHMARK_NUMBER=999
export ADDITIONAL_WRITERS=0
export MAX_ROWS=100000000
export ROWS_PER_REPORT=100000
export RUN_MINUTES=999999
export UNIQUE_CHECKS=1
export INSERT_ONLY=1

export INNODB_CACHE=8G
export TOKUDB_DIRECTIO_CACHE=8G
export DEEPDB_CACHE_SIZE=8G

# ****** PMPROF ENABLED ******
#     ****** PMPROF ENABLED ******
#         ****** PMPROF ENABLED ******
#export PMPROF_ENABLED=Y

export MYSQL_STORAGE_ENGINE=wiredtiger
export TARBALL=wiredtiger-20140825-mysql-5.7.4.m14
export MINI_BENCH_ID=mysql5714m14wiredtiger20140825
export BENCH_ID=${MINI_BENCH_ID}
#./run.benchmark.sh

export MYSQL_STORAGE_ENGINE=tokudb
export TARBALL=blank-toku752-mysql-5.5.39
export MINI_BENCH_ID=752
export BENCH_ID=${MINI_BENCH_ID}-${TOKUDB_DIRECTIO_CACHE}G.quicklz
./run.benchmark.sh

export MYSQL_STORAGE_ENGINE=innodb
export TARBALL=blank-mysql5539
export MINI_BENCH_ID=mysql5539
export BENCH_ID=${MINI_BENCH_ID}-${INNODB_CACHE}G
#./run.benchmark.sh

export MYSQL_STORAGE_ENGINE=deepdb
export TARBALL=blank-mysql5536-deepdb1.1.0.16110
export MINI_BENCH_ID=mysql5536deepdb11016110
export BENCH_ID=${MINI_BENCH_ID}-${DEEPDB_CACHE_SIZE}G
#./run.benchmark.sh
