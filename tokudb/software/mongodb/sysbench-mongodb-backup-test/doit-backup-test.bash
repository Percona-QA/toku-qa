#!/bin/bash


pkill -9 mongo
bkill
sleep 2
mongo-clean


export TOKUMX_BUFFERED_IO=N


export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536
export NUM_COLLECTIONS=8
export NUM_DOCUMENTS_PER_COLLECTION=1000000
#export NUM_DOCUMENTS_PER_COLLECTION=200000
export NUM_DOCUMENTS_PER_INSERT=1000
export NUM_LOADER_THREADS=8
export threadCountList="0064"
export RUN_TIME_SECONDS=300
export DB_NAME=sbtest
export BENCHMARK_NUMBER=999
export WRITE_CONCERN=SAFE

# HOT BACKUPS!
export RUN_HOT_BACKUPS=Y
export RUN_HOT_BACKUPS_MBPS=75
export RUN_HOT_BACKUPS_PAUSE_SECONDS=30

export USE_TRANSACTIONS=Y

# 4 seconds for lock timeouts
#export MONGO_LOCK_TIMEOUT=4000
export MONGO_LOCK_TIMEOUT=20000

export SCP_FILES=N

# 12G
#export TOKUMON_CACHE_SIZE=12G
# 2G
export TOKUMON_CACHE_SIZE=2G

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

export BENCH_ID=backup-test
export MONGO_REPLICATION=Y

# TOKUMX
export TARBALL=tokumx-e-2.0-SNAPSHOT-20140924b-linux-x86_64-main.tar.gz
export MONGO_TYPE=tokumx

# MONGODB 2.2
#export TARBALL=mongodb-linux-x86_64-2.2.5
#export MONGO_TYPE=mongo



# ************************************************************************
# set to Y for a multi-directory test, N for single directory
# ************************************************************************
export MULTI_DIR=N



# unpack mongo files
echo "Creating mongo from ${TARBALL} in ${MONGO_DIR}"
pushd $MONGO_DIR
mkmon $TARBALL
popd

if [ ${MULTI_DIR} == "Y" ]; then
    export MONGO_LOG_DIR=${MONGO_DATA_DIR}/l
    export MONGO_DATA_DIR=${MONGO_DATA_DIR}/d
    
    # on lex5, use a completely different filesystem (uncomment the following line)
    #export MONGO_DATA_DIR=/data.ssd/tcallaghan/data/mongo-data/d
    
    mkdir ${MONGO_LOG_DIR}; mkdir ${MONGO_DATA_DIR}
fi

echo "Running loader"
./run.load.bash

echo "Running benchmark"
./run.benchmark.bash

export VERIFY_LOG_NAME=${MACHINE_NAME}-test-verification.log

echo "Validating Backups" | tee -a ${VERIFY_LOG_NAME}
./verify-backups.bash

#cat ${VERIFY_LOG_NAME}

echo ""
echo "-------------------------------------------------------------------------"
echo "Test results for ${TARBALL}"

if grep -qi "build failed\|error\|horribly wrong" ${VERIFY_LOG_NAME}
then
    echo "*** FAIL ***"
    echo "*** FAIL ***"
    echo "*** FAIL ***"
    grep -i "build failed\|error\|horribly wrong" ${VERIFY_LOG_NAME}
    echo "*** FAIL ***"
    echo "*** FAIL ***"
    echo "*** FAIL ***"
else
    echo "*** PASS ***"
    echo "*** PASS ***"
    echo "*** PASS ***"
fi
echo "-------------------------------------------------------------------------"

#mongo-clean
