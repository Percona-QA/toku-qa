#/bin/bash

export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.38
export SCP_FILES=Y
export DIRECTIO=Y
export BENCHMARK_NUMBER=999
export ADDITIONAL_WRITERS=0
export MAX_ROWS=1000000000
export ROWS_PER_REPORT=100000
export RUN_MINUTES=480
export UNIQUE_CHECKS=1
export INSERT_ONLY=0

export INNODB_CACHE=8G
export TOKUDB_DIRECTIO_CACHE=8G
export DEEPDB_CACHE_SIZE=8G

# ****** PMPROF ENABLED ******
#     ****** PMPROF ENABLED ******
#         ****** PMPROF ENABLED ******
#export PMPROF_ENABLED=Y

#export MYSQL_STORAGE_ENGINE=tokudb
#export TARBALL=blank-percona-5620.a2
#export MINI_BENCH_ID=750ps56
#export BENCH_ID=${MINI_BENCH_ID}-${TOKUDB_DIRECTIO_CACHE}G.quicklz
#./run.benchmark.sh

#export MYSQL_STORAGE_ENGINE=tokudb
#export TARBALL=blank-tokudb.750.a2-mysql-5.5.39
#export MINI_BENCH_ID=750msql55
#export BENCH_ID=${MINI_BENCH_ID}-${TOKUDB_DIRECTIO_CACHE}G.quicklz
#./run.benchmark.sh

export MYSQL_STORAGE_ENGINE=tokudb
export TARBALL=blank-toku717.e-mysql-5.5.38
export MINI_BENCH_ID=717emysql
export BENCH_ID=${MINI_BENCH_ID}-${TOKUDB_DIRECTIO_CACHE}G.quicklz
./run.benchmark.sh

export MYSQL_STORAGE_ENGINE=tokudb
export TARBALL=blank-toku750rc2.e-mysql-5.5.39
export MINI_BENCH_ID=750rc2emysql
export BENCH_ID=${MINI_BENCH_ID}-${TOKUDB_DIRECTIO_CACHE}G.quicklz
./run.benchmark.sh

#export MYSQL_STORAGE_ENGINE=tokudb
#export TARBALL=blank-toku717.e-mariadb-5.5.38
#export MINI_BENCH_ID=717emariadb
#export BENCH_ID=${MINI_BENCH_ID}-${TOKUDB_DIRECTIO_CACHE}G.quicklz
#./run.benchmark.sh

#export MYSQL_STORAGE_ENGINE=tokudb
#export TARBALL=blank-toku750rc2.e-mariadb-5.5.39
#export MINI_BENCH_ID=750rc2emariadb
#export BENCH_ID=${MINI_BENCH_ID}-${TOKUDB_DIRECTIO_CACHE}G.quicklz
#./run.benchmark.sh




