#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi
if [ -z "$MYSQL_HOST" ]; then
    echo "Need to set MYSQL_HOST"
    exit 1
fi
if [ -z "$MYSQL_PORT" ]; then
    echo "Need to set MYSQL_PORT"
    exit 1
fi
if [ -z "$IS_MYSQL56" ]; then
    echo "Need to set IS_MYSQL56"
    exit 1
fi
if [ -z "$SCP_TARGET" ]; then
    echo "Need to set SCP_TARGET"
    exit 1
fi

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
    export TARBALL=blank-toku716-mysql-5.5.37
fi
if [ -z "$TOKUDB_COMPRESSION" ]; then
    export TOKUDB_COMPRESSION=zlib
fi
if [ -z "$BENCH_ID" ]; then
    export BENCH_ID=716.${TOKUDB_COMPRESSION}
fi
if [ -z "$NUM_ROWS" ]; then
    export NUM_ROWS=10000000
fi
if [ -z "$NUM_LOADERS" ]; then
    export NUM_LOADERS=10
fi
if [ -z "$NUM_REQUESTERS" ]; then
    export NUM_REQUESTERS=64
fi
if [ -z "$NUM_REQUESTS" ]; then
    export NUM_REQUESTS=2000000000
fi
if [ -z "$RUN_TIME_SECONDS" ]; then
    export RUN_TIME_SECONDS=600
fi
if [ -z "$TOKUDB_READ_BLOCK_SIZE" ]; then
    export TOKUDB_READ_BLOCK_SIZE=64K
fi
if [ -z "$SKIP_DB_CREATE" ]; then
    export SKIP_DB_CREATE=N
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    export BENCHMARK_NUMBER=999
fi
if [ -z "$INSERT_BATCH_SIZE" ]; then
    export INSERT_BATCH_SIZE=1000
fi
if [ -z "$WARMUP_TIME" ]; then
    export WARMUP_TIME=30
fi
if [ -z "$DIRECTIO" ]; then
    export SCP_FILES=Y
fi
if [ -z "$DIRECTIO" ]; then
    export SCP_FILES=Y
fi
if [ -z "$INNODB_COMPRESSION" ]; then
    export INNODB_COMPRESSION=N
fi

EXTRA_INFO=${NUM_ROWS}-${NUM_LOADERS}-${NUM_REQUESTERS}-${NUM_REQUESTS}-${RUN_TIME_SECONDS}

export BENCHMARK_LOGGING=Y
export LOADER_LOGGING=Y

export MYSQL_DATABASE=linkdb
export MYSQL_USER=root

export startid1=1
export maxid1=$[NUM_ROWS+1]

export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}

#mvn clean package -P fast-test
mvn clean package -DskipTests


if [ ${SKIP_DB_CREATE} == "N" ]; then
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
        if [ ${DIRECTIO} == "N" ]; then
            echo "innodb_flush_method=O_DSYNC" >> my.cnf
        fi
        echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
        
        if [ ${INNODB_COMPRESSION} == "Y" ]; then
            EXTRA_INFO=${EXTRA_INFO}-COMPRESSED
        else
            EXTRA_INFO=${EXTRA_INFO}-UNCOMPRESSED
        fi
    elif [ ${MYSQL_STORAGE_ENGINE} == "myisam" ]; then
        echo "key_buffer_size=8G" >> my.cnf
    #    echo "table_open_cache=2048" >> my.cnf
    else
        echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
        echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
        echo "tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE}" >> my.cnf
        echo "tokudb_prelock_empty=0" >> my.cnf
        if [ ${DIRECTIO} == "Y" ]; then
            echo "tokudb_directio=1" >> my.cnf
        fi
    fi
    echo "max_connections=2048" >> my.cnf
    echo "table_definition_cache=1000" >> my.cnf
    echo "table_open_cache=2000" >> my.cnf
    echo "query_cache_size=0" >> my.cnf
    echo "query_cache_type=0" >> my.cnf
    
    if [ ${IS_MYSQL56} == "Y" ]; then
        # only in MySQL 5.6
        echo "table_open_cache_instances=1" >> my.cnf
        echo "metadata_locks_hash_instances=256" >> my.cnf
    fi
    
    mstart
    popd

    echo "Loading Data"
    ./run.load.sh
fi

echo "Starting database"
pushd $DB_DIR
mstart
popd

echo "Executing benchmark"
./run.execute.sh

if [ ${SCP_FILES} == "Y" ]; then
    DATE=`date +"%Y%m%d%H%M%S"`
    tarFileName="${MACHINE_NAME}-${BENCHMARK_NUMBER}-${DATE}-linkbench-${BENCH_ID}-${EXTRA_INFO}.tar.gz"

    tar czvf ${tarFileName} ${MACHINE_NAME}* ${DB_DIR}/data/*.err
    scp ${tarFileName} ${SCP_TARGET}:~
    
    rm -f ${tarFileName}
    rm -f ${MACHINE_NAME}*

    movecores
fi
