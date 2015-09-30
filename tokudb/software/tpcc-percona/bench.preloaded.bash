#/bin/bash

if [ -z "$TOKUDB_DIRECTIO_CACHE" ]; then
    echo "Need to set $TOKUDB_DIRECTIO_CACHE"
    exit 1
fi


# NOTE : NOT SETTING THE FOLLOWING IN MY.CNF
#   echo "tokudb_directIO=1" >> my.cnf


export threadCountList="0064"
export RUN_TIME_SECONDS=900
export NUM_WAREHOUSES=500
export NEW_ORDERS_PER_TEN_SECONDS=200000
export NEW_ORDERS_PER_TEN_SECONDS_LIST="200000 1000 3000 1000 200000 3000 1000 500"

export SINGLE_FLUSH=N
export END_ITERATION_NUMBER=15
export END_ITERATION_SLEEP_SECONDS=120

# hole-punching + aggressive checkpointing
#export TARBALL=blank-hp2ac.52126-mysql-5.5.28
#export BENCH_ID=hp2ac.52126.zlib.64k

# hole-punching + aggressive checkpointing
#export TARBALL=blank-hp2acfc.52244-mysql-5.5.28
#export BENCH_ID=hp2acfc.52244.zlib-lzma.64k

# compaction + aggressive checkpointing
export TARBALL=blank-cac.52292-mysql-5.5.28
export BENCH_ID=cac.52292.zlib.64k

export DIRECTIO=Y

export TOKUDB_COMPRESSION=zlib
export TOKUDB_READ_BLOCK_SIZE=65536


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
    export NUM_WAREHOUSES=100
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
    export BENCHMARK_NUMBER=999
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
        export TARBALL=blank-mysql5524
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
        export TOKUDB_COMPRESSION=zlib
    fi
    if [ -z "$TOKUDB_READ_BLOCK_SIZE" ]; then
        export TOKUDB_READ_BLOCK_SIZE=65536
    fi
    export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
    if [ -z "$TARBALL" ]; then
        export TARBALL=blank-toku663.51530-mysql-5.5.28
    fi
    if [ -z "$BENCH_ID" ]; then
        export BENCH_ID=663.51530.${TOKUDB_COMPRESSION}.${TOKUDB_READ_BLOCK_SIZE}
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

echo "Copying in existing data files"
pushd $DB_DIR
rm -rf data
mkdir data
cp -r $LOCAL_BACKUP_DIR/dbs/tpcc-${NUM_WAREHOUSES}w-v663-zlib/data/* data
popd

echo "Configuring my.cnf and starting database"
pushd $DB_DIR
if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "innodb_buffer_pool_size=${INNODB_BUFFER_POOL_SIZE}" >> my.cnf
    echo "innodb_flush_method=${INNODB_FLUSH_METHOD}" >> my.cnf
else
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    echo "tokudb_lock_timeout=60000" >> my.cnf
    if [ ${DIRECTIO} == "Y" ]; then
        echo "tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE}" >> my.cnf
    fi
fi
echo "max_prepared_stmt_count=65536" >> my.cnf
echo "max_connections=2048" >> my.cnf
mstart
popd

echo "Running benchmark"
./run.benchmark.sh

echo "Stopping database"
mstop
