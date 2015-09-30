#!/bin/bash


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


export MONGO_BASEMENT=65536
export DB_NAME=mydb
export COLLECTION_NAME=apavlo
#export TOKUMON_CACHE_SIZE=12884901888
export BENCHMARK_NUMBER=999
export SCP_FILES=Y



# TOKUMX - ZLIB
export TARBALL=tokumx-1.0.3-linux-x86_64
export MONGO_TYPE=tokumx
export MONGO_COMPRESSION=zlib
export BENCH_ID=tokumx-1.0.3-${MONGO_COMPRESSION}
echo "Creating mongo from ${TARBALL} in ${MONGO_DIR}"; pushd $MONGO_DIR; mkmon $TARBALL; popd
./run.load.bash
mongo-clean


# TOKUMX - QUICKLZ
export TARBALL=tokumx-1.0.3-linux-x86_64
export MONGO_TYPE=tokumx
export MONGO_COMPRESSION=quicklz
export BENCH_ID=tokumx-1.0.3-${MONGO_COMPRESSION}
echo "Creating mongo from ${TARBALL} in ${MONGO_DIR}"; pushd $MONGO_DIR; mkmon $TARBALL; popd
./run.load.bash
mongo-clean


# TOKUMX - LZMA
export TARBALL=tokumx-1.0.3-linux-x86_64
export MONGO_TYPE=tokumx
export MONGO_COMPRESSION=lzma
export BENCH_ID=tokumx-1.0.3-${MONGO_COMPRESSION}
echo "Creating mongo from ${TARBALL} in ${MONGO_DIR}"; pushd $MONGO_DIR; mkmon $TARBALL; popd
./run.load.bash
mongo-clean


# TOKUMX - UNCOMPRESSED
export TARBALL=tokumx-1.0.3-linux-x86_64
export MONGO_TYPE=tokumx
export MONGO_COMPRESSION=none
export BENCH_ID=tokumx-1.0.3-${MONGO_COMPRESSION}
echo "Creating mongo from ${TARBALL} in ${MONGO_DIR}"; pushd $MONGO_DIR; mkmon $TARBALL; popd
./run.load.bash
mongo-clean


# MONGODB
export TARBALL=mongodb-linux-x86_64-2.2.5
export MONGO_TYPE=mongo
export BENCH_ID=mongo-2.2.5
echo "Creating mongo from ${TARBALL} in ${MONGO_DIR}"; pushd $MONGO_DIR; mkmon $TARBALL; popd
./run.load.bash
mongo-clean


