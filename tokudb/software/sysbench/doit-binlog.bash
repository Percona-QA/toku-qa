#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi

export threadCountList="0016 0032 0064 0128 0256"
export BENCHMARK_LOGGING=Y
export LOADER_LOGGING=Y
export MYSQL_DATABASE=sbtest
export MYSQL_USER=root
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.38
export TARBALL=blank-toku717-mysql-5.5.38
export NUM_ROWS=1000000
export NUM_TABLES=64
export NUM_DATABASES=1
export RUN_TIME_SECONDS=180
export RAND_TYPE=uniform

export INNODB_CACHE=24GB
export TOKUDB_CACHE=24GB

export MYSQL_STORAGE_ENGINE=tokudb
export TOKUDB_READ_BLOCK_SIZE=64K
export TOKUDB_ROW_FORMAT=tokudb_zlib
export BENCHMARK_NUMBER=999


export BENCH_ID=binlog-test-${MYSQL_STORAGE_ENGINE}-binlogOFF

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
    echo "tokudb_commit_sync=0" >> my.cnf
    echo "tokudb_fsync_log_period=1000" >> my.cnf
fi
echo "max_connections=2048" >> my.cnf
mstart
popd
    
echo "Loading Data"
pushd fastload
./run.load.flatfiles.sh
popd
    
echo "Running benchmark - binary logging OFF"
./run.benchmark.sh
    
echo "Stopping database"
mstop


# -----------------------------------------------------------------------------------

echo "Enabling binary logging - fsync off"
pushd $DB_DIR
echo "log-bin" >> my.cnf
echo "sync_binlog=0" >> my.cnf
echo "server_id=1" >> my.cnf
echo "max_binlog_size=100M" >> my.cnf
echo "binlog_format=ROW" >> my.cnf
mstart
popd

export BENCH_ID=binlog-test-${MYSQL_STORAGE_ENGINE}-binlogONsyncOFF

echo "Running benchmark - binary logging ON sync OFF"
./run.benchmark.sh

echo "Stopping database"
mstop


# -----------------------------------------------------------------------------------

echo "Enabling binary logging - fsync on"
pushd $DB_DIR
echo "log-bin" >> my.cnf
echo "sync_binlog=1" >> my.cnf
echo "server_id=1" >> my.cnf
echo "max_binlog_size=100M" >> my.cnf
echo "binlog_format=ROW" >> my.cnf
mstart
popd

export BENCH_ID=binlog-test-${MYSQL_STORAGE_ENGINE}-binlogONsyncON

echo "Running benchmark - binary logging ON sync ON"
./run.benchmark.sh

echo "Stopping database"
mstop

