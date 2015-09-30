#!/bin/bash

if [ -z "$BENCHMARK_SUFFIX" ]; then
    #export BENCHMARK_SUFFIX=".anything-you-want"
    export BENCHMARK_SUFFIX=""
fi
if [ -z "$TARBALL" ]; then
    echo "Need to set TARBALL"
    exit 1
fi
if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi
if [ -z "$MACHINE_NAME" ]; then
    echo "Need to set MACHINE_NAME"
    exit 1
fi
if [ -z "$MYSQL_SOCKET" ]; then
    echo "Need to set MYSQL_SOCKET"
    exit 1
fi
if [ -z "$MYSQL_PORT" ]; then
    echo "Need to set MYSQL_PORT"
    exit 1
fi
if [ -z "$BENCH_ID" ]; then
    echo "Need to set BENCH_ID"
    exit 1
fi
if [ -z "$MYSQL_NAME" ]; then
    export MYSQL_NAME=mysql
fi
if [ -z "$MYSQL_VERSION" ]; then
    export MYSQL_VERSION=5.5.39
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    export MYSQL_STORAGE_ENGINE=tokudb
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    export BENCHMARK_NUMBER=001
fi
if [ -z "$SCP_FILES" ]; then
    export SCP_FILES=Y
fi
if [ -z "$RUN_ARBITRARY_SQL" ]; then
    export RUN_ARBITRARY_SQL=N
fi

if [ -z "$NUM_SECONDARY_INDEXES" ]; then
    export NUM_SECONDARY_INDEXES=3
fi

if [ -z "$DIRECTIO" ]; then
    export DIRECTIO=N
fi
if [ -z "$SKIP_DB_CREATE" ]; then
    export SKIP_DB_CREATE=N
fi
if [ -z "$SHUTDOWN_MYSQL" ]; then
    export SHUTDOWN_MYSQL=Y
fi
if [ -z "$IIBENCH_CREATE_TABLE" ]; then
    export IIBENCH_CREATE_TABLE=Y
fi
if [ -z "$MAX_ROWS" ]; then
    export MAX_ROWS=1000000000
fi
if [ -z "$RUN_MINUTES" ]; then
    export RUN_MINUTES=200000
fi
if [ -z "$NUM_ROWS_PER_INSERT" ]; then
    export NUM_ROWS_PER_INSERT=1000
fi
if [ -z "$MAX_INSERTS_PER_SECOND" ]; then
    export MAX_INSERTS_PER_SECOND=9999999
fi

export RUN_SECONDS=$[RUN_MINUTES*60]

if [ -z "$NUM_INSERTS_PER_FEEDBACK" ]; then
    export NUM_INSERTS_PER_FEEDBACK=100000
fi
if [ -z "$NUM_LOADER_THREADS" ]; then
    export NUM_LOADER_THREADS=1
fi
if [ -z "$NUM_CHAR_FIELDS" ]; then
    export NUM_CHAR_FIELDS=0
fi
if [ -z "$LENGTH_CHAR_FIELDS" ]; then
    export LENGTH_CHAR_FIELDS=0
fi
if [ -z "$PERCENT_COMPRESSIBLE" ]; then
    export PERCENT_COMPRESSIBLE=0
fi
if [ -z "$MYSQL_DATABASE" ]; then
    export MYSQL_DATABASE=iibench
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    export BENCHMARK_NUMBER=101
fi

if [ -z "$QUERIES_PER_INTERVAL" ]; then
    export QUERIES_PER_INTERVAL=0
fi
if [ -z "$QUERY_INTERVAL_SECONDS" ]; then
    export QUERY_INTERVAL_SECONDS=60
fi
if [ -z "$QUERY_LIMIT" ]; then
    export QUERY_LIMIT=1000
    #export QUERY_LIMIT=5
fi
if [ -z "$QUERY_NUM_ROWS_BEGIN" ]; then
    export QUERY_NUM_ROWS_BEGIN=500000
fi
if [ -z "$SHUTDOWN_MYSQL" ]; then
    export SHUTDOWN_MYSQL=Y
fi
if [ -z "$CREATE_TABLE" ]; then
    export CREATE_TABLE=Y
fi

export MYSQL_SERVER=localhost
export MYSQL_ROOT_USER=root
export MYSQL_ROOT_PASSWORD=""
export MYSQL_USER=tmc
export MYSQL_PASSWORD=tmc
export MYSQL_DATABASE=test
export BENCHMARK_LOGGING=Y

if [ ${SKIP_DB_CREATE} == "N" ] ; then
    # check for existing files
    if [ "$(ls -A ${DB_DIR}/data)" ]; then
        echo "${DB_DIR}/data contains files, cannot run script"
        exit 1
    fi

    if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
        if [ -z "$INNODB_CACHE" ]; then
            echo "Need to set INNODB_CACHE"
            exit 1
        fi
        if [ -z "$INNODB_KEY_BLOCK_SIZE" ]; then
            echo "Need to set INNODB_KEY_BLOCK_SIZE"
            exit 1
        fi
        export INNODB_BUFFER_POOL_SIZE=${INNODB_CACHE}
        # O_DIRECT, O_DSYNC, **default is special case and not yet supported by this script**
        export INNODB_FLUSH_METHOD=O_DIRECT
        if [ -z "$TARBALL" ]; then
            export TARBALL=blank-mysql5529
        fi
    elif [ ${MYSQL_STORAGE_ENGINE} == "deepdb" ]; then
        if [ -z "$DEEPDB_CACHE_SIZE" ]; then
            echo "Need to set DEEPDB_CACHE_SIZE"
            exit 1
        fi
        if [ -z "$TARBALL" ]; then
            echo "Need to set TARBALL"
            exit 1
        fi
    elif [ ${MYSQL_STORAGE_ENGINE} == "wiredtiger" ]; then
        echo "Currently no customized settings for WIREDTIGER."
    else
        export INNODB_KEY_BLOCK_SIZE=0
        
        # pick your basement node size: 64k=65536, 128K=131072
        if [ -z "$TOKUDB_READ_BLOCK_SIZE" ]; then
            export TOKUDB_READ_BLOCK_SIZE=65536
        fi
        
        if [ -z "$TOKUDB_COMPRESSION" ]; then
            export TOKUDB_COMPRESSION=quicklz
        fi
        
        export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
        
        if [ -z "$TARBALL" ]; then
            export TARBALL=blank-toku665.54176.backup-mysql-5.5.28
        fi
    fi

    # stop mysql if it is currently running
    if [ -e "${DB_DIR}/bin/mysqladmin" ]; then
        ${DB_DIR}/bin/mysqladmin --user=${MYSQL_ROOT_USER} --socket=${MYSQL_SOCKET} shutdown
    fi

    echo "Creating database from ${TARBALL} in ${DB_DIR}"
    pushd ${DB_DIR}
    mkdb-quiet ${TARBALL}
    if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
        echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
        echo "innodb_flush_method=${INNODB_FLUSH_METHOD}" >> my.cnf
        if [ -n "$INNODB_CHANGE_BUFFERING" ]; then
            echo "innodb_change_buffering=${INNODB_CHANGE_BUFFERING}" >> my.cnf
        fi
    elif [ ${MYSQL_STORAGE_ENGINE} == "deepdb" ]; then
        echo "deepdb_cache_size=${DEEBDB_CACHE_SIZE}" >> my.cnf
        echo "[mysqld_safe]" >> my.cnf
        echo "malloc-lib=$PWD/lib/plugin/libtcmalloc_minimal.so" >> my.cnf
    elif [ ${MYSQL_STORAGE_ENGINE} == "wiredtiger" ]; then
        # no customizations for wiredtiger, yet.
        tempWtVar=1
    else
        echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
        echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
        echo "tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE}" >> my.cnf
        if [ ${DIRECTIO} == "Y" ]; then
            echo "tokudb_directio=1" >> my.cnf
        fi
    fi
    mstart
    popd

    # create database and tables
    echo "`date` | drop database" | tee -a $LOG_NAME
    $DB_DIR/bin/mysqladmin --user=${MYSQL_ROOT_USER} --socket=${MYSQL_SOCKET} -f drop ${MYSQL_DATABASE}
    
    echo "`date` | create database" | tee -a $LOG_NAME
    $DB_DIR/bin/mysqladmin --user=${MYSQL_ROOT_USER} --socket=${MYSQL_SOCKET} create ${MYSQL_DATABASE}
    
    # create user and grant privileges
    mysql-user
fi

echo "Running loader"
./run.load.bash
