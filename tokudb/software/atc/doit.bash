#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
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
    export TARBALL=blank-toku716.e-mysql-5.5.37
    #export TARBALL=blank-percona-server-5.6.17-65.0-601
fi
if [ -z "$TOKUDB_COMPRESSION" ]; then
    export TOKUDB_COMPRESSION=zlib
fi
if [ -z "$TOKUDB_READ_BLOCK_SIZE" ]; then
    export TOKUDB_READ_BLOCK_SIZE=64K
fi
if [ -z "$TOKUDB_LOADER_MEMORY_SIZE" ]; then
    export TOKUDB_LOADER_MEMORY_SIZE=1G
fi
if [ -z "$DIRECTIO" ]; then
    export DIRECTIO=Y
fi

export BENCHMARK_LOGGING=Y
export LOADER_LOGGING=Y

export TOKUDB_DIRECTIO_CACHE=8G
export INNODB_CACHE=8G

export MYSQL_DATABASE=test
export MYSQL_USER=root

#export FILE_NAME=atc-1mm.csv
#export ROW_COUNT=1000000
export FILE_NAME=atc-122mm.csv
export ROW_COUNT=122225386

export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}

export LOAD_DB=Y
export SCP_FILES=Y

LOG_PATH=$PWD

if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    export BENCH_ID=${MACHINE_NAME}.${TARBALL}.${INNODB_CACHE}.${DIRECTIO}
    export LOG_NAME=$LOG_PATH/${BENCH_ID}.log
else
    export BENCH_ID=${MACHINE_NAME}.${TARBALL}.${TOKUDB_COMPRESSION}.${TOKUDB_READ_BLOCK_SIZE}.${TOKUDB_DIRECTIO_CACHE}.${DIRECTIO}
    export LOG_NAME=$LOG_PATH/${BENCH_ID}.log
fi

if [ ${LOAD_DB} == "Y" ]; then
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
    else
        echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
        echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
        echo "tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE}" >> my.cnf
        echo "tokudb_loader_memory_size=${TOKUDB_LOADER_MEMORY_SIZE}" >> my.cnf
        if [ ${DIRECTIO} == "Y" ]; then
            echo "tokudb_directio=1" >> my.cnf
        fi
    fi
    echo "max_connections=2048" >> my.cnf
    echo "sort_buffer_size=2M" >> my.cnf
    mstart
    popd
    
    echo "Loading Data"
    pushd fastload
    ./run.load.flatfiles.sh
    popd
fi

echo "Running benchmark - first run"
./run.benchmark.sh

echo "Running benchmark - second run"
./run.benchmark.sh

echo "Stopping database"
mstop


if [ ${SCP_FILES} == "Y" ]; then
    DATE=`date +"%Y%m%d%H%M%S"`
    tarFileName="${MACHINE_NAME}-${DATE}-ATC-${BENCH_ID}.tar.gz"

    tar czvf ${tarFileName} ${MACHINE_NAME}* fastload/log-load* fastload/*.log ${DB_DIR}/data/*.err
    scp ${tarFileName} ${SCP_TARGET}:~
    
    rm -f ${tarFileName}
    rm -f ${MACHINE_NAME}*
    rm -f fastload/log-load*
    rm -f fastload/*.log
    rm -f fastload/*.done

    movecores
fi

