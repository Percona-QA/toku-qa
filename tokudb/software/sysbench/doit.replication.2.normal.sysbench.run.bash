#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi

export threadCountList="064"
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.39
export MYSQL_STORAGE_ENGINE=tokudb
export BENCH_ID=rep.run.test
export NUM_ROWS=5000000
export NUM_TABLES=16
export NUM_DATABASES=1
export RUN_TIME_SECONDS=3600
export RAND_TYPE=uniform
export BENCHMARK_NUMBER=999
export READONLY=off
export BENCHMARK_LOGGING=Y
export MYSQL_DATABASE=sbtest
export MYSQL_USER=root

echo "Running benchmark"
./run.benchmark.sh

