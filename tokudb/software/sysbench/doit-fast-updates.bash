#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi

export threadCountList="0064"
export BENCHMARK_LOGGING=Y
export LOADER_LOGGING=Y
export MYSQL_DATABASE=sbtest
export MYSQL_USER=root
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.28
export TARBALL=blank-main.54495-mysql-5.5.28
export NUM_ROWS=10000000
export NUM_TABLES=16
export RUN_TIME_SECONDS=900
export RAND_TYPE=uniform

export INNODB_CACHE=8GB
export TOKUDB_CACHE=8GB

export MYSQL_STORAGE_ENGINE=tokudb
#export TOKUDB_COMPRESSION=zlib
#export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
#export BENCH_ID=main.54495.normal-updates.${TOKUDB_COMPRESSION}
export TOKUDB_READ_BLOCK_SIZE=64K
export BENCHMARK_NUMBER=999
export SYSBENCH_NON_INDEX_UPDATES_PER_TXN=1
#export BENCH_ID=main.54495.innodb.${SYSBENCH_NON_INDEX_UPDATES_PER_TXN}-per



# -------------------------------------------------------------------------------------------
# TokuDB Tests : 1 update per transaction, each compression type

for TOKUDB_COMPRESSION in zlib quicklz lzma uncompressed; do
    export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
    export SYSBENCH_NON_INDEX_UPDATES_PER_TXN=1
    export BENCH_ID=main.54495.normal-updates.${TOKUDB_COMPRESSION}.${SYSBENCH_NON_INDEX_UPDATES_PER_TXN}-per

    echo "Creating database from ${TARBALL} in ${DB_DIR}"
    pushd $DB_DIR
    mkdb-quiet $TARBALL
    popd
    
    echo "Configuring my.cnf and starting database"
    pushd $DB_DIR
    if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
        echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
    else
        echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
        echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
        echo "tokudb_cache_size=${TOKUDB_CACHE}" >> my.cnf
        echo "tokudb_directio=1" >> my.cnf
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
done



# -------------------------------------------------------------------------------------------
# InnoDB Test : 1 update per transaction

export MYSQL_STORAGE_ENGINE=innodb
export BENCHMARK_NUMBER=999
export SYSBENCH_NON_INDEX_UPDATES_PER_TXN=1
export BENCH_ID=main.54495.innodb.${SYSBENCH_NON_INDEX_UPDATES_PER_TXN}-per


echo "Creating database from ${TARBALL} in ${DB_DIR}"
pushd $DB_DIR
mkdb-quiet $TARBALL
popd

echo "Configuring my.cnf and starting database"
pushd $DB_DIR
if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
else
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    echo "tokudb_cache_size=${TOKUDB_CACHE}" >> my.cnf
    echo "tokudb_directio=1" >> my.cnf
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


# -------------------------------------------------------------------------------------------
# InnoDB Test : 25 updates per transaction

export MYSQL_STORAGE_ENGINE=innodb
export BENCHMARK_NUMBER=999
export SYSBENCH_NON_INDEX_UPDATES_PER_TXN=25
export BENCH_ID=main.54495.innodb.${SYSBENCH_NON_INDEX_UPDATES_PER_TXN}-per

echo "Creating database from ${TARBALL} in ${DB_DIR}"
pushd $DB_DIR
mkdb-quiet $TARBALL
popd

echo "Configuring my.cnf and starting database"
pushd $DB_DIR
if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
else
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    echo "tokudb_cache_size=${TOKUDB_CACHE}" >> my.cnf
    echo "tokudb_directio=1" >> my.cnf
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



# -------------------------------------------------------------------------------------------
# TokuDB Tests : 25 updates per transaction, just zlib (it is fastest)

for TOKUDB_COMPRESSION in zlib ; do
    export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
    export SYSBENCH_NON_INDEX_UPDATES_PER_TXN=25
    export BENCH_ID=main.54495.normal-updates.${TOKUDB_COMPRESSION}.${SYSBENCH_NON_INDEX_UPDATES_PER_TXN}-per

    echo "Creating database from ${TARBALL} in ${DB_DIR}"
    pushd $DB_DIR
    mkdb-quiet $TARBALL
    popd
    
    echo "Configuring my.cnf and starting database"
    pushd $DB_DIR
    if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
        echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
    else
        echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
        echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
        echo "tokudb_cache_size=${TOKUDB_CACHE}" >> my.cnf
        echo "tokudb_directio=1" >> my.cnf
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
done


# -------------------------------------------------------------------------------------------
# TokuDB Tests : 25 updates per transaction, just zlib (it is fastest)
# *** FAST-UPDATES ***

for TOKUDB_COMPRESSION in zlib ; do
    export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
    export SYSBENCH_NON_INDEX_UPDATES_PER_TXN=25
    export BENCH_ID=main.54495.normal-updates.${TOKUDB_COMPRESSION}.${SYSBENCH_NON_INDEX_UPDATES_PER_TXN}-per

    echo "Creating database from ${TARBALL} in ${DB_DIR}"
    pushd $DB_DIR
    mkdb-quiet $TARBALL
    popd
    
    echo "Configuring my.cnf and starting database"
    pushd $DB_DIR
    if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
        echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
    else
        echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
        echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
        echo "tokudb_cache_size=${TOKUDB_CACHE}" >> my.cnf
        echo "tokudb_directio=1" >> my.cnf
    fi
    echo "max_connections=2048" >> my.cnf
    mstart
    popd
    
    echo "Loading Data"
    pushd fastload
    ./run.load.flatfiles.sh
    popd
    
    echo "Running benchmark"
    ./run.benchmark-noar.sh
    
    echo "Stopping database"
    mstop
done
