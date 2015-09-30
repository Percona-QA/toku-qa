#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536
#export MAX_ROWS=50000000
export MAX_ROWS=1000000000
export RUN_MINUTES=60
#export NUM_SECONDARY_INDEXES=0
#export NUM_DOCUMENTS_PER_INSERT=1000
export NUM_DOCUMENTS_PER_INSERT=250
export MAX_INSERTS_PER_SECOND=999999
export NUM_INSERTS_PER_FEEDBACK=-1
export NUM_SECONDS_PER_FEEDBACK=10
export NUM_LOADER_THREADS=4
export DB_NAME=iibench
export BENCHMARK_NUMBER=999
#export MONGO_SERVER=mork
#export MONGO_PORT=30000
export MONGO_SERVER=localhost
export MONGO_PORT=27017

export NUM_CHAR_FIELDS=1
export LENGTH_CHAR_FIELDS=1000
export PERCENT_COMPRESSIBLE=50

export MONGO_REPLICATION=Y
if [ ${MONGO_REPLICATION} == "Y" ]; then
    export OPLOG_STRING="OpLogON"
else
    export OPLOG_STRING="OpLogOFF"
fi

# FSYNC_SAFE, NONE, NORMAL, REPLICAS_SAFE, SAFE
export WRITE_CONCERN=SAFE

# set these if you want inserts plus queries
export QUERIES_PER_INTERVAL=0
export QUERY_INTERVAL_SECONDS=15
export QUERY_LIMIT=10
export QUERY_NUM_DOCS_BEGIN=1000000

export TOKUMON_CACHE_SIZE=8G


# 4G oplog
#export MONGOD_EXTRA="--oplogSize 4096"


export SCP_TARGET=tcallaghan@192.168.1.242

# if LOCK_MEMORY=Y, then all but 12G of RAM on the server is locked
export LOCK_MEMORY=N

# lock out all but 12G
if [ ${LOCK_MEMORY} == "Y" ]; then
    if [ -z "$LOCK_MEM_SIZE_12" ]; then
        echo "Need to set LOCK_MEM_SIZE_12"
        exit 1
    fi

    echo "Removing RAM locker, 5 second sleep"
    sudo pkill -9 lockmem
    sleep 5
    echo "Locking all but 12G of RAM, 10 second sleep"
    sudo ~/bin/lockmem $LOCK_MEM_SIZE_12 &
    sleep 10
    export BENCHMARK_SUFFIX=".${LOCK_MEM_SIZE_12}-lock"
else
    unset BENCHMARK_SUFFIX
fi

mongo-clean

# DISK

# TOKUMX
#export TARBALL=tokumx-2.0.0-linux-x86_64-main
#export MONGO_TYPE=tokumx
#export MONGO_COMPRESSION=zlib
#export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${MONGO_COMPRESSION}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}
#./doit.bash
#mongo-clean

# MONGODB
#export TARBALL=mongodb-linux-x86_64-2.6.5
#export MONGO_TYPE=mongo
#export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}-RA16K
#ra-set 32
#./doit.bash
#ra-set 256
#mongo-clean

# MONGODB 2.8 : mmapv1
#export TARBALL=mongodb-linux-x86_64-2.8.0-rc5
#export MONGO_TYPE=mongo
#export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}-RA16K
#ra-set 32
#./doit.bash
#ra-set 256
#mongo-clean

# MONGODB 2.8 : wiredtiger
#export TARBALL=mongodb-linux-x86_64-2.8.0-rc5
#export MONGO_TYPE=wt
#export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}
#./doit.bash
#mongo-clean

# MONGODB 2.8 : mxse
#export TARBALL=mongodb-linux-x86_64-tokumxse-1.0.0-rc.0
#export TARBALL=mongodb-linux-x86_64-tokumxse-20150120
export TARBALL=mongodb-linux-x86_64-tokumxse-20150122b
export MONGO_TYPE=mxse
export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}
./doit.bash
mongo-clean



# SSD
source ~/machine.config.ssd
export TOKUMON_CACHE_SIZE=8G

# MONGODB 2.8 : mmapv1
#export TARBALL=mongodb-linux-x86_64-2.8.0-rc5
#export MONGO_TYPE=mongo
#export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}-RA16K
#ra-set 32
#./doit.bash
#ra-set 256
#mongo-clean

# MONGODB 2.8 : wiredtiger
#export TARBALL=mongodb-linux-x86_64-2.8.0-rc5
#export MONGO_TYPE=wt
#export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}
#./doit.bash
#mongo-clean

# MONGODB 2.8 : mxse
#export TARBALL=mongodb-linux-x86_64-tokumxse-1.0.0-rc.0
#export TARBALL=mongodb-linux-x86_64-tokumxse-20150120
#export TARBALL=mongodb-linux-x86_64-tokumxse-20150122b
#export MONGO_TYPE=mxse
#export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}
#./doit.bash
#mongo-clean




# ALWAYS unlock memory
echo "Removing RAM locker!"
sudo pkill -9 lockmem


unset MONGOD_EXTRA
