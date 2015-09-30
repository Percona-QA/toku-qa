#!/bin/bash

# this is the main "pre-execution" script for the benchmark
#   can be called from a higher level script

if [ -z "$BENCHMARK_SUFFIX" ]; then
    #export BENCHMARK_SUFFIX=".anything-you-want"
    export BENCHMARK_SUFFIX=""
fi
if [ -z "$TARBALL" ]; then
    export TARBALL=tokumx-1.4.2-linux-x86_64-main
    #export TARBALL=mongodb-linux-x86_64-2.2.7
    #export TARBALL=mongodb-linux-x86_64-2.4.10
    #export TARBALL=mongodb-linux-x86_64-2.6.1
fi
if [ -z "$MONGO_TYPE" ]; then
    export MONGO_TYPE=tokumx
    #export MONGO_TYPE=mongo
    #export MONGO_TYPE=wt
fi
if [ -z "$MONGO_DIR" ]; then
    echo "Need to set MONGO_DIR"
    exit 1
fi
if [ ! -d "$MONGO_DIR" ]; then
    echo "Need to create directory MONGO_DIR"
    exit 1
fi

if [ -z "$MONGO_COMPRESSION" ]; then
    # lzma, quicklz, zlib, none
    export MONGO_COMPRESSION=zlib
fi
if [ -z "$MONGO_BASEMENT" ]; then
    # 131072, 65536
    export MONGO_BASEMENT=65536
fi

if [ -z "$MAX_ROWS" ]; then
    export MAX_ROWS=1000000000
fi
if [ -z "$RUN_MINUTES" ]; then
    export RUN_MINUTES=200000
fi
if [ -z "$NUM_DOCUMENTS_PER_INSERT" ]; then
    export NUM_DOCUMENTS_PER_INSERT=1000
fi
if [ -z "$MAX_INSERTS_PER_SECOND" ]; then
    export MAX_INSERTS_PER_SECOND=9999999
fi
if [ -z "$NUM_SECONDARY_INDEXES" ]; then
    export NUM_SECONDARY_INDEXES=3
fi

if [ -z "$WRITE_CONCERN" ]; then
    # FSYNC_SAFE, NONE, NORMAL, REPLICAS_SAFE, SAFE
    export WRITE_CONCERN=SAFE
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
if [ -z "$DB_NAME" ]; then
    export DB_NAME=iibench
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    export BENCHMARK_NUMBER=101
fi
if [ -z "$MONGO_REPLICATION" ]; then
    export MONGO_REPLICATION=N
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
if [ -z "$QUERY_NUM_DOCS_BEGIN" ]; then
    export QUERY_NUM_DOCS_BEGIN=500000
fi
if [ -z "$MONGO_SERVER" ]; then
    export MONGO_SERVER=localhost
fi
if [ -z "$MONGO_PORT" ]; then
    export MONGO_PORT=27017
fi
if [ -z "$STARTUP_MONGO" ]; then
    export STARTUP_MONGO=Y
fi
if [ -z "$SHUTDOWN_MONGO" ]; then
    export SHUTDOWN_MONGO=Y
fi
if [ -z "$CREATE_COLLECTION" ]; then
    export CREATE_COLLECTION=Y
fi
if [ -z "$LOCK_TIMEOUT" ]; then
    export LOCK_TIMEOUT=4000
fi

if [ ${STARTUP_MONGO} == "Y" ] ; then
    # check for existing files
    if [ "$(ls -A $MONGO_DIR)" ]; then
        echo "$MONGO_DIR contains files, cannot run script"
        exit 1
    fi

    # unpack mongo files
    echo "Creating mongo from ${TARBALL} in ${MONGO_DIR}"
    pushd $MONGO_DIR
    mkmon $TARBALL
    popd
fi

echo "Running loader"
./run.load.bash
