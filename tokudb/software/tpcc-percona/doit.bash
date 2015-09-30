#/bin/bash

# vars
# MYSQL_NAME=mysql, mariadb
# MYSQL_VERSION=5.5.28, 5.5.28a
# MYSQL_STORAGE_ENGINE=tokudb, innodb
# NUM_WAREHOUSES=100
# RUN_TIME_SECONDS=300
# SCP_FILES=Y
# NEW_ORDERS_PER_TEN_SECONDS=200000 (rate limiting)
# TARBALL=blank-toku650.48167-mysql-5.5.24
# BENCH_ID=650.48167.quicklz.64k
# TOKUDB_READ_BLOCK_SIZE=65536
# TOKUDB_COMPRESSION=quicklz, lzma, zlib, uncompressed


if [ -z "$MYSQL_NAME" ]; then
    export MYSQL_NAME=mysql
fi
if [ -z "$MYSQL_VERSION" ]; then
    export MYSQL_VERSION=5.5.28
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    export MYSQL_STORAGE_ENGINE=tokudb
fi
if [ -z "$NUM_WAREHOUSES" ]; then
    export NUM_WAREHOUSES=500
fi
if [ -z "$RUN_TIME_SECONDS" ]; then
    export RUN_TIME_SECONDS=300
fi
if [ -z "$SCP_FILES" ]; then
    export SCP_FILES=Y
fi
if [ -z "$NEW_ORDERS_PER_TEN_SECONDS" ]; then
    export NEW_ORDERS_PER_TEN_SECONDS=200000
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    export BENCHMARK_NUMBER=008
fi
if [ -z "$DIRECTIO" ]; then
    export DIRECTIO=N
fi
if [ -z "$WARMUP" ]; then
    export WARMUP=N
fi

if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    if [ -z "$INNODB_CACHE" ]; then
        echo "Need to set INNODB_CACHE"
        exit 1
    fi
    export INNODB_COMPRESSION=N
    export INNODB_KEY_BLOCK_SIZE=8
    export INNODB_FK=Y
    export INNODB_BUFFER_POOL_SIZE=${INNODB_CACHE}
    # O_DIRECT, O_DSYNC, **default is special case and not yet supported by this script**
    export INNODB_FLUSH_METHOD=O_DIRECT
    if [ -z "$TARBALL" ]; then
        export TARBALL=blank-mysql5529
    fi
    if [ ${INNODB_COMPRESSION} == "Y" ]; then
        if [ -z "$BENCH_ID" ]; then
            export BENCH_ID=1.1.8.compressed.${INNODB_KEY_BLOCK_SIZE}
        fi 
    else
        if [ -z "$BENCH_ID" ]; then
            export BENCH_ID=1.1.8
        fi
    fi
    if [ ${INNODB_FK} == "Y" ]; then
        export BENCH_ID=${BENCH_ID}.fk
    else
        export BENCH_ID=${BENCH_ID}.nofk
    fi
else
    if [ -z "$TOKUDB_COMPRESSION" ]; then
        export TOKUDB_COMPRESSION=quicklz
    fi
    if [ -z "$TOKUDB_READ_BLOCK_SIZE" ]; then
        export TOKUDB_READ_BLOCK_SIZE=65536
    fi
    export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
    if [ -z "$TARBALL" ]; then
        export TARBALL=blank-673.nopunch.52935-mysql-5.5.28
    fi
    if [ -z "$BENCH_ID" ]; then
        export BENCH_ID=673.nopunch.52935.${TOKUDB_COMPRESSION}.${TOKUDB_READ_BLOCK_SIZE}
    fi
fi


export BENCHMARK_LOGGING=Y
export LOADER_LOGGING=Y

export MYSQL_DATABASE=tpcc
export MYSQL_USER=root

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi

echo "Creating database from ${TARBALL} in ${DB_DIR}"
pushd $DB_DIR
mkdb-quiet $TARBALL
popd

echo "Configuring my.cnf and starting database"
pushd $DB_DIR
if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "innodb_buffer_pool_size=${INNODB_BUFFER_POOL_SIZE}" >> my.cnf
    echo "innodb_flush_method=${INNODB_FLUSH_METHOD}" >> my.cnf
    if [ -n "$INNODB_ONLINE_ALTER_LOG_MAX_SIZE" ]; then
        echo "innodb_online_alter_log_max_size=${INNODB_ONLINE_ALTER_LOG_MAX_SIZE}" >> my.cnf
    fi
else
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    echo "tokudb_lock_timeout=60000" >> my.cnf
    echo "tokudb_loader_memory_size=1G" >> my.cnf
    if [ ${DIRECTIO} == "Y" ]; then
        echo "tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE}" >> my.cnf
        echo "tokudb_directio=1" >> my.cnf
    fi
fi
echo "max_prepared_stmt_count=65536" >> my.cnf
echo "max_connections=2048" >> my.cnf
mstart
popd

echo "Loading Data"
pushd fastload
./run.load.flatfiles.sh
popd

#export threadCountList="0064 0128 0256 0512 1024"
#export threadCountList="0064"
#export DO_WARMUP=N

echo "Running benchmark"
./run.benchmark.sh

echo "Stopping database"
mstop
