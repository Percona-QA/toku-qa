#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536
export NUM_COLLECTIONS=4
export NUM_DOCUMENTS_PER_COLLECTION=500000
export NUM_DOCUMENTS_PER_INSERT=1000
export NUM_LOADER_THREADS=8
#export threadCountList="0001 0002 0004 0008 0016 0032 0064 0128 0256 0512 1024"
export threadCountList="0064"
export RUN_TIME_SECONDS=3600
export DB_NAME=sbtest
export BENCHMARK_NUMBER=999

# FSYNC_SAFE, NONE, NORMAL, REPLICAS_SAFE, SAFE
export WRITE_CONCERN=SAFE

#export TOKUMON_CACHE_SIZE=12884901888
export TOKUMON_CACHE_SIZE=24884901888

# lock out all but 16G
#if [ -z "$LOCK_MEM_SIZE_16" ]; then
#    echo "Need to set LOCK_MEM_SIZE_16"
#    exit 1
#fi

#export BENCHMARK_SUFFIX=".${LOCK_MEM_SIZE_16}-lock"


if [ -z "$MONGO_DIR" ]; then
    echo "Need to set MONGO_DIR"
    exit 1
fi
if [ ! -d "$MONGO_DIR" ]; then
    echo "Need to create directory MONGO_DIR"
    exit 1
fi
#if [ "$(ls -A $MONGO_DIR)" ]; then
#    echo "$MONGO_DIR contains files, cannot run script"
#    exit 1
#fi




# need to lockout memory for pure mongo tests
#sudo pkill -9 lockmem
#sudo ~/bin/lockmem $LOCK_MEM_SIZE_16 &


# TOKUMX
export TARBALL=tokumx-1.2.0-e-rc0
export MONGO_TYPE=tokumx
export MONGO_REPLICATION=Y
export BENCH_ID=tokumx-1.2.0-e-rc0-${MONGO_COMPRESSION}-${WRITE_CONCERN}

# MONGODB 2.2
#export TARBALL=mongodb-linux-x86_64-2.2.5
#export MONGO_TYPE=mongo
#export MONGO_REPLICATION=N
#export BENCH_ID=mongo-2.2.5-${WRITE_CONCERN}

# MONGODB 2.4
#export TARBALL=mongodb-linux-x86_64-2.4.5
#export MONGO_TYPE=mongo
#export MONGO_REPLICATION=N
#export BENCH_ID=mongo-2.4.5-${WRITE_CONCERN}


# unpack mongo files
echo "Creating mongo from ${TARBALL} in ${MONGO_DIR}"
pushd $MONGO_DIR
mkmon $TARBALL
popd

echo "Running loader"
./run.load.bash

echo "Running benchmark"
./run.benchmark.bash


# unlock memory
#sudo pkill -9 lockmem

#mongo-clean
