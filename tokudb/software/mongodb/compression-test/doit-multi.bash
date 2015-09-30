#!/bin/bash

export MONGO_BASEMENT=65536
export MAX_ROWS=100000000
export RUN_MINUTES=200000
export NUM_DOCUMENTS_PER_INSERT=1000
export MAX_INSERTS_PER_SECOND=999999
export NUM_INSERTS_PER_FEEDBACK=100000
export NUM_LOADER_THREADS=1
export DB_NAME=iibench
export BENCHMARK_NUMBER=999
export MONGO_REPLICATION=N

# FSYNC_SAFE, NONE, NORMAL, REPLICAS_SAFE, SAFE
export WRITE_CONCERN=SAFE

# set these if you want inserts plus queries
export QUERIES_PER_INTERVAL=0
export QUERY_INTERVAL_SECONDS=15
export QUERY_LIMIT=10
export QUERY_NUM_DOCS_BEGIN=1000000

export TOKUMON_CACHE_SIZE=12884901888


# **********************************************************************************
# LONG FIELD NAMES
export LONG_FIELD_NAMES=Y

# TOKUMX - SAFE - ZLIB
export TARBALL=tokumx-1.0.3-linux-x86_64
export MONGO_TYPE=tokumx
export MONGO_COMPRESSION=zlib
export BENCH_ID=tokumx-1.0.3-${MONGO_COMPRESSION}-${WRITE_CONCERN}
./doit.bash
mongo-clean


# TOKUMX - SAFE - UNCOMPRESSED
export TARBALL=tokumx-1.0.3-linux-x86_64
export MONGO_TYPE=tokumx
export MONGO_COMPRESSION=none
export BENCH_ID=tokumx-1.0.3-${MONGO_COMPRESSION}-${WRITE_CONCERN}
./doit.bash
mongo-clean


# MONGODB - SAFE
export TARBALL=mongodb-linux-x86_64-2.2.5
export MONGO_TYPE=mongo
export BENCH_ID=mongo-2.2.5-${WRITE_CONCERN}
#./doit.bash
mongo-clean



# **********************************************************************************
# SHORT FIELD NAMES
export LONG_FIELD_NAMES=N


# TOKUMX - SAFE - ZLIB
export TARBALL=tokumx-1.0.3-linux-x86_64
export MONGO_TYPE=tokumx
export MONGO_COMPRESSION=zlib
export BENCH_ID=tokumx-1.0.3-${MONGO_COMPRESSION}-${WRITE_CONCERN}
#./doit.bash
mongo-clean


# TOKUMX - SAFE - UNCOMPRESSED
export TARBALL=tokumx-1.0.3-linux-x86_64
export MONGO_TYPE=tokumx
export MONGO_COMPRESSION=none
export BENCH_ID=tokumx-1.0.3-${MONGO_COMPRESSION}-${WRITE_CONCERN}
#./doit.bash
mongo-clean


# MONGODB - SAFE
export TARBALL=mongodb-linux-x86_64-2.2.5
export MONGO_TYPE=mongo
export BENCH_ID=mongo-2.2.5-${WRITE_CONCERN}
#./doit.bash
mongo-clean

