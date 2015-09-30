#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi

export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.28
export MYSQL_STORAGE_ENGINE=tokudb
export TARBALL=blank-toku664.52174-mysql-5.5.28
export TOKUDB_COMPRESSION=quicklz
export BENCH_ID=664.52174.${TOKUDB_COMPRESSION}
export NUM_ROWS=50000000
export NUM_TABLES=1
export RUN_TIME_SECONDS=300
export RAND_TYPE=uniform
export TOKUDB_READ_BLOCK_SIZE=64K
export BENCHMARK_NUMBER=004
export DIRECTIO=N
export threadCountList="0032 0064"

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
echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
if [ ${DIRECTIO} == "Y" ]; then
    echo "tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE}" >> my.cnf
    echo "tokudb_directIO=1" >> my.cnf
fi
echo "max_connections=2048" >> my.cnf
mstart
popd

echo "Loading Data"
pushd fastload
./run.load.flatfiles.sh
popd

#echo "Running benchmark"
#./run.benchmark.sh

echo "Stopping database"
mstop
