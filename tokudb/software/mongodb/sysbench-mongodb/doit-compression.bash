#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536

# > RAM test
export NUM_COLLECTIONS=16
export NUM_DOCUMENTS_PER_COLLECTION=5000000

export NUM_DOCUMENTS_PER_INSERT=1000
export NUM_LOADER_THREADS=8
export threadCountList="0064"
export RUN_TIME_SECONDS=600
export DB_NAME=sbtest
export BENCHMARK_NUMBER=999

# FSYNC_SAFE, NONE, NORMAL, REPLICAS_SAFE, SAFE
export WRITE_CONCERN=SAFE

export TOKUMON_CACHE_SIZE=4G
export MONGO_LOCK_TIMEOUT=20000

export MONGO_REPLICATION=N
export LOCK_MEMORY=N

export TARBALL=tokumx-lz4109_snappy111_withhc-linux-x86_64.tgz
export TOKUMX_BUFFERED_IO=Y
export MONGO_TYPE=tokumx
export BENCH_ID=tokumx-1.3.3-${WRITE_CONCERN}

mongo-clean

for compressionType in none quicklz zlib lzma snappy lz4 lz4hc; do
    export MONGO_COMPRESSION=${compressionType}
    export BENCHMARK_SUFFIX="-${compressionType}"

    ./doit.bash
    mongo-clean
done

# ALWAYS unlock memory
sudo pkill -9 lockmem
