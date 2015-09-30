#!/bin/bash

if [ -z "$TARBALL" ]; then
    export TARBALL=tokumx-1.3.1-linux-x86_64
    #export TARBALL=mongodb-linux-x86_64-2.4.8
fi
if [ -z "$MONGO_TYPE" ]; then
    export MONGO_TYPE=tokumx
    #export MONGO_TYPE=mongo
fi
if [ -z "$MONGO_DIR" ]; then
    echo "Need to set MONGO_DIR"
    exit 1
fi
if [ ! -d "$MONGO_DIR" ]; then
    echo "Need to create directory MONGO_DIR"
    exit 1
fi
if [ "$(ls -A $MONGO_DIR)" ]; then
    echo "$MONGO_DIR contains files, cannot run script"
    exit 1
fi
if [ -z "$BENCH_ID" ]; then
    echo "Need to set BENCH_ID"
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

if [ -z "$WRITE_CONCERN" ]; then
    # working: none, normal
    # broken : fsync_safe, safe, replicas_safe
    export WRITE_CONCERN=normal
fi

if [ -z "$RECORDCOUNT" ]; then
    #export RECORDCOUNT=15000000
    export RECORDCOUNT=100000
fi
if [ -z "$DB_NAME" ]; then
    export DB_NAME=ycsb
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    export BENCHMARK_NUMBER=110
fi
if [ -z "$MONGO_REPLICATION" ]; then
    export MONGO_REPLICATION=N
fi
if [ -z "$MONGO_URL" ]; then
    export MONGO_URL=mongodb://localhost:27017
fi
if [ -z "$YCSB_DIR" ]; then
    export YCSB_DIR=ycsb-0.1.4
fi
if [ -z "$SCP_FILES" ]; then
    export SCP_FILES=Y
fi

export TOKUMON_CACHE_SIZE=12G

mongo-clean

# unpack mongo files
echo "Creating mongo from ${TARBALL} in ${MONGO_DIR}"
pushd $MONGO_DIR
mkmon $TARBALL
popd

echo "Running loader"
./mongo.2.load.bash

#echo "Running benchmark"
#if [ ${SYSBENCH_TYPE} == "OLTP" ]; then
#    echo "  sysbench type = OLTP"
#    ./run.benchmark.bash
#else
#    echo "  sysbench type = PILEUP"
#    ./run.benchmark.pileup.bash
#fi
