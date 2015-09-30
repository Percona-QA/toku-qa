#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi


if [ -z "$GO_FAST" ]; then
    export GO_FAST=Y
fi
if [ -z "$MYSQL_NAME" ]; then
    export MYSQL_NAME=mysql
fi
if [ -z "$MYSQL_VERSION" ]; then
    export MYSQL_VERSION=5.6.7
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    export MYSQL_STORAGE_ENGINE=tokudb
fi
if [ -z "$TARBALL" ]; then
    #export TARBALL=blank-toku650.48167-${MYSQL_NAME}-${MYSQL_VERSION}
    export TARBALL=blank-5254.50325.fastupdate-mysql-5.6.7
fi
if [ -z "$TOKUDB_COMPRESSION" ]; then
    export TOKUDB_COMPRESSION=lzma
fi
if [ -z "$BENCH_ID" ]; then
    export BENCH_ID=toku567.50325.${GO_FAST}
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
export LOADER_LOGGING=Y

export MYSQL_DATABASE=sbtest
export MYSQL_USER=root

export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}

echo "Creating database from ${TARBALL} in ${DB_DIR}"
pushd $DB_DIR
mkdb-quiet $TARBALL
popd

echo "Configuring my.cnf and starting database"
pushd $DB_DIR
if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    if [ -z "$INNODB_CACHE" ]; then
        echo "Need to set INNODB_CACHE"
        exit 1
    fi
    echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
else
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    if [ ${GO_FAST} == "Y" ]; then    
        echo "tokudb_enable_fast_upsert=1" >> my.cnf
        echo "tokudb_enable_fast_update=1" >> my.cnf
    else
        echo "tokudb_enable_fast_upsert=0" >> my.cnf
        echo "tokudb_enable_fast_update=0" >> my.cnf
    fi
fi
echo "max_connections=2048" >> my.cnf
mstart
popd

echo "Loading Data"
pushd fastload
./run.load.flatfiles.sh
popd

echo "Running benchmark"
./run.benchmark.sh

echo "Stopping database"
mstop
