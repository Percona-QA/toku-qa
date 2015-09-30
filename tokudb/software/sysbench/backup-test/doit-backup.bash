#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi

if [ -z "$HOT_BACKUP_DIR" ]; then
    echo "Need to set HOT_BACKUP_DIR"
    exit 1
fi
if [ ! -d "$HOT_BACKUP_DIR" ]; then
    echo "Need to create directory HOT_BACKUP_DIR"
    exit 1
fi

echo "*** removing all files from $HOT_BACKUP_DIR"
rm -rf $HOT_BACKUP_DIR/*

export threadCountList="0064"

if [ -z "$MYSQL_NAME" ]; then
    export MYSQL_NAME=mysql
fi
if [ -z "$MYSQL_VERSION" ]; then
    export MYSQL_VERSION=5.5.37
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    export MYSQL_STORAGE_ENGINE=tokudb
fi
if [ -z "$TARBALL" ]; then
    export TARBALL=blank-toku716.e-mysql-5.5.37
fi
if [ -z "$TOKUDB_COMPRESSION" ]; then
    export TOKUDB_COMPRESSION=zlib
fi
if [ -z "$BENCH_ID" ]; then
    export BENCH_ID=715.e.${TOKUDB_COMPRESSION}.${TARBALL}
fi
if [ -z "$NUM_ROWS" ]; then
    #export NUM_ROWS=50000000
    #export NUM_ROWS=5000000
    export NUM_ROWS=1000000
fi
if [ -z "$NUM_TABLES" ]; then
    export NUM_TABLES=8
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
if [ -z "$BENCHMARK_NUMBER" ]; then
    export BENCHMARK_NUMBER=999
fi
if [ -z "$TOKUDB_BACKUP_THROTTLE" ]; then
    # 20 MB/s
    export TOKUDB_BACKUP_THROTTLE=20M
fi

export BENCHMARK_LOGGING=N
export LOADER_LOGGING=N

export MYSQL_DATABASE=sbtest
export MYSQL_USER=root

export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}

export RUN_HOT_BACKUPS=Y
export RUN_HOT_BACKUPS_START_SECONDS=20
export RUN_HOT_BACKUPS_MBPS=65

# default is 4000 (4 seconds)
# setting to 2 minutes
export TOKUDB_LOCK_TIMEOUT=120000

export TOKUDB_DIRECTIO_CACHE=2G

export DIRECTIO=Y

###########################################
# size : medium
export NUM_TABLES=8
export NUM_ROWS=1000000
export RUN_TIME_SECONDS=300
export VERIFY_LOG_NAME=${PWD}/test-verification.log
###########################################


echo "Creating database from ${TARBALL} in ${DB_DIR}"
pushd $DB_DIR
mkdb-quiet $TARBALL
popd

echo "Configuring my.cnf and starting database"
pushd $DB_DIR

echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
echo "tokudb_backup_throttle=${TOKUDB_BACKUP_THROTTLE}" >> my.cnf
echo "tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE}" >> my.cnf
if [ ${DIRECTIO} == "Y" ]; then
    echo "tokudb_directio=1" >> my.cnf
else
    echo "tokudb_directio=0" >> my.cnf
fi
echo "tokudb_lock_timeout=${TOKUDB_LOCK_TIMEOUT}" >> my.cnf
echo "max_connections=2048" >> my.cnf
mstart
popd

echo "Loading Data"
pushd fastload
./run.load.flatfiles.sh
popd

echo "Running Benchmark"
./run.benchmark.sh

echo "Validating Internal Checksums"
echo "Validating Internal Checksums" >> ${VERIFY_LOG_NAME}
./verify.bash ${NUM_TABLES} ${VERIFY_LOG_NAME}

echo "Stopping database"
mstop

echo "Validating Backups"
echo "Validating Backups" >> ${VERIFY_LOG_NAME}
./verify-backups.bash ${NUM_TABLES} ${VERIFY_LOG_NAME}
