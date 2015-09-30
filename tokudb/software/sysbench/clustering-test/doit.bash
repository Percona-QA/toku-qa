#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi


if [ -z "$MYSQL_NAME" ]; then
    export MYSQL_NAME=mysql
fi
if [ -z "$MYSQL_VERSION" ]; then
    export MYSQL_VERSION=5.5.24
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    export MYSQL_STORAGE_ENGINE=tokudb
fi
if [ -z "$TARBALL" ]; then
    export TARBALL=blank-toku651.49887-${MYSQL_NAME}-${MYSQL_VERSION}
fi
if [ -z "$TOKUDB_COMPRESSION" ]; then
    export TOKUDB_COMPRESSION=lzma
fi
if [ -z "$BENCH_ID" ]; then
    export BENCH_ID=651.49887.${TOKUDB_COMPRESSION}
fi
if [ -z "$NUM_ROWS" ]; then
    export NUM_ROWS=50000000
fi
if [ -z "$NUM_TABLES" ]; then
    export NUM_TABLES=16
fi
if [ -z "$RUN_TIME_SECONDS" ]; then
    export RUN_TIME_SECONDS=300
fi
if [ -z "$RAND_TYPE" ]; then
    export RAND_TYPE=uniform
fi
if [ -z "$TOKUDB_READ_BLOCK_SIZE" ]; then
    export TOKUDB_READ_BLOCK_SIZE=64K
fi

export BENCHMARK_LOGGING=Y

export MYSQL_DATABASE=sbtest
export MYSQL_USER=root

echo "Running benchmark"
./run.benchmark.sh
