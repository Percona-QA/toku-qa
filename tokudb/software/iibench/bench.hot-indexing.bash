#/bin/bash

export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.30
export MYSQL_STORAGE_ENGINE=tokudb
export SCP_FILES=Y
export DIRECTIO=Y
export BENCHMARK_NUMBER=999
export ADDITIONAL_WRITERS=0
export MAX_ROWS=1000000000
export ROWS_PER_REPORT=100000
export RUN_MINUTES=20
export UNIQUE_CHECKS=1
export INSERT_ONLY=1

# run an arbitrary sql statement (create a hot index during the benchmark)
export RUN_ARBITRARY_SQL=Y
export arbitrarySqlWaitSeconds=300


# run once for pre-optimization
export TARBALL=blank-prezhot-mysql-5.5.30
export BENCH_ID=prezhot.quicklz
./run.benchmark.sh

# and again for post-optimization
export TARBALL=blank-zhot-mysql-5.5.30
export BENCH_ID=zhot.quicklz
./run.benchmark.sh
