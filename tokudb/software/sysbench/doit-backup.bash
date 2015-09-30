#!/bin/bash

# vars
# MYSQL_NAME=mysql, mariadb
# MYSQL_VERSION=5.5.24, 5.5.25
# MYSQL_STORAGE_ENGINE=tokudb, innodb
# TARBALL=blank-toku650.48167-mysql-5.5.24
# BENCH_ID=650.48167.lzma
# TOKUDB_COMPRESSION=quicklz, lzma, zlib, uncompressed
# NUM_ROWS=50000000
# NUM_TABLES=16
# RUN_TIME_SECONDS=900
# RAND_TYPE=uniform, special
# TOKUDB_READ_BLOCK_SIZE=64K (basement node size)


if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi

export threadCountList="0064"

if [ -z "$MYSQL_NAME" ]; then
    export MYSQL_NAME=mysql
fi
if [ -z "$MYSQL_VERSION" ]; then
    export MYSQL_VERSION=5.5.30
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    export MYSQL_STORAGE_ENGINE=tokudb
fi
if [ -z "$TARBALL" ]; then
    export TARBALL=blank-main.55322.e-mysql-5.5.30
fi
if [ -z "$TOKUDB_COMPRESSION" ]; then
    export TOKUDB_COMPRESSION=lzma
fi
if [ -z "$BENCH_ID" ]; then
    export BENCH_ID=main.55322.backup.${TOKUDB_COMPRESSION}.${TARBALL}
fi
if [ -z "$NUM_ROWS" ]; then
    #export NUM_ROWS=50000000
    export NUM_ROWS=5000000
fi
if [ -z "$NUM_TABLES" ]; then
    export NUM_TABLES=32
fi
if [ -z "$RUN_TIME_SECONDS" ]; then
    export RUN_TIME_SECONDS=1800
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
if [ -z "$DIRECTIO" ]; then
    export DIRECTIO=Y
fi
if [ -z "$TOKUDB_BACKUP_THROTTLE" ]; then
    # bytes/second for the copier
    # <unlimited> MB/s
    #export TOKUDB_BACKUP_THROTTLE=18446744073709551615
    # 20 MB/s
    export TOKUDB_BACKUP_THROTTLE=20971520
fi

export BENCHMARK_LOGGING=Y
export LOADER_LOGGING=Y

export MYSQL_DATABASE=sbtest
export MYSQL_USER=root

export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}

export RUN_ARBITRARY_SQL=Y
export arbitrarySqlWaitSeconds=100

echo "Creating database from ${TARBALL} in ${DB_DIR}"
pushd $DB_DIR
mkdb-quiet $TARBALL
popd

echo "Configuring my.cnf and starting database"
pushd $DB_DIR

echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
echo "tokudb_backup_throttle=${TOKUDB_BACKUP_THROTTLE}" >> my.cnf
if [ ${DIRECTIO} == "Y" ]; then
    echo "tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE}" >> my.cnf
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
