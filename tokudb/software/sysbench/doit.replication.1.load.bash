#!/bin/bash

export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.39
export MYSQL_STORAGE_ENGINE=tokudb
export BENCH_ID=rep.load.test
export NUM_ROWS=5000000
export NUM_TABLES=16
export NUM_DATABASES=1
export BENCHMARK_NUMBER=999
export LOADER_LOGGING=N
export MYSQL_DATABASE=sbtest
export MYSQL_USER=root

echo "Loading Data"
pushd fastload
./run.load.flatfiles.sh
popd

