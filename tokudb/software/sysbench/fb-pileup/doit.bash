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
    export MYSQL_VERSION=5.5.38
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    export MYSQL_STORAGE_ENGINE=tokudb
fi
if [ -z "$TARBALL" ]; then
    export TARBALL=blank-toku717-mysql-5.5.38
fi
if [ -z "$TOKUDB_COMPRESSION" ]; then
    export TOKUDB_COMPRESSION=quicklz
fi
if [ -z "$BENCH_ID" ]; then
    export BENCH_ID=pre46b.${TOKUDB_COMPRESSION}
fi
if [ -z "$NUM_ROWS" ]; then
    export NUM_ROWS=250000
fi
if [ -z "$NUM_TABLES" ]; then
    export NUM_TABLES=16
fi
if [ -z "$RUN_TIME_SECONDS" ]; then
    export RUN_TIME_SECONDS=180
fi
if [ -z "$RAND_TYPE" ]; then
    export RAND_TYPE=uniform
fi
if [ -z "$TOKUDB_READ_BLOCK_SIZE" ]; then
    export TOKUDB_READ_BLOCK_SIZE=64K
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    export BENCHMARK_NUMBER=007
fi
if [ -z "$DISABLE_AHI" ]; then
    export DISABLE_AHI=N
fi
if [ -z "$BENCHMARK_LOGGING" ]; then
    export BENCHMARK_LOGGING=N
fi

export LOADER_LOGGING=N

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
    if [ ${DISABLE_AHI} == "Y" ]; then
        # disable adaptive hash indexing
        echo "innodb_adaptive_hash_index=0" >> my.cnf
    fi
elif [ ${MYSQL_STORAGE_ENGINE} == "myisam" ]; then
    echo "key_buffer_size=8G" >> my.cnf
#    echo "table_open_cache=2048" >> my.cnf
elif [ ${MYSQL_STORAGE_ENGINE} == "wiredtiger" ]; then
    echo "key_buffer_size=8G" >> my.cnf
#    echo "table_open_cache=2048" >> my.cnf
else
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    echo "tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE}" >> my.cnf
    echo "tokudb_loader_memory_size=1G" >> my.cnf
    if [ ${DIRECTIO} == "Y" ]; then
        echo "tokudb_directio=1" >> my.cnf
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
