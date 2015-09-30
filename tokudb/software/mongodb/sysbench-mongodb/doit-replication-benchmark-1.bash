#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536
export TOKUMON_CACHE_SIZE=12G

export NUM_COLLECTIONS=16
export NUM_DOCUMENTS_PER_COLLECTION=10000000
export NUM_DOCUMENTS_PER_INSERT=1000
export NUM_LOADER_THREADS=8
export DB_NAME=sbtest
export BENCHMARK_NUMBER=999
export WRITE_CONCERN=SAFE

export MONGO_REPLICATION=N
unset MONGO_REPL
unset MONGO_OPLOGSIZE



#export MONGO_TYPE=tokumx
export MONGO_TYPE=mongo

if [ ${MONGO_TYPE} == "tokumx" ]; then
    # TOKUMX
    export TARBALL=tokumx-1.3.1-linux-x86_64
    export BENCH_ID=tokumx-1.3.1-${MONGO_COMPRESSION}-${WRITE_CONCERN}
    export BENCHMARK_SUFFIX=".${TOKUMON_CACHE_SIZE}"
else
    # MONGODB 2.4 - lower readahead
    export TARBALL=mongodb-linux-x86_64-2.4.8
    export BENCH_ID=mongo-2.4.8-${WRITE_CONCERN}
    export BENCHMARK_SUFFIX=".NOlock"

    # reduce readahead
    #ra-set 32
fi    

echo "Cleaning out directories"
mongo-clean

echo "Creating mongo from ${TARBALL} in ${MONGO_DIR}"
pushd $MONGO_DIR
mkmon $TARBALL
popd

echo "Running loader"
./run.load.bash


# bounce the server and add replication support
export MONGO_REPL="tmcRepl"
export MONGO_OPLOGSIZE="4096"
echo "`date` | restarting the ${MONGO_TYPE} server at ${MONGO_DIR}" | tee -a $LOG_NAME
if [ ${MONGO_TYPE} == "tokumx" ]; then
    mongo-start-tokumx-fork
else
    mongo-start-pure-numa-fork
fi
mongo-is-up
echo "`date` | server is available" | tee -a $LOG_NAME
mongo-start-replication
echo "`date` | shutting down the server" | tee -a $LOG_NAME
mongo-stop
mongo-is-down


# put readahead back
#ra-set 256
