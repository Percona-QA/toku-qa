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
export RUN_MINUTES=120
export UNIQUE_CHECKS=1
export INSERT_ONLY=1


for checkpointingPeriod in 015 030 060 120 240 480 960 ; do
    export TOKUDB_CHECKPOINTING_PERIOD=${checkpointingPeriod}
    export TARBALL=blank-toku710-mysql-5.5.30
    export MINI_BENCH_ID=710
    export BENCH_ID=${MINI_BENCH_ID}.quicklz.${checkpointingPeriod}
    ./run.benchmark.sh
done


