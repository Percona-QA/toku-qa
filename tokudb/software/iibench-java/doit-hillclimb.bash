#!/bin/bash

export MAX_ROWS=200000000
export RUN_MINUTES=2
export NUM_ROWS_PER_INSERT=1000
export MAX_INSERTS_PER_SECOND=9999999

export NUM_INSERTS_PER_FEEDBACK=-1
export NUM_SECONDS_PER_FEEDBACK=10

export MYSQL_DATABASE=iibench
export BENCHMARK_NUMBER=999

export NUM_LOADER_THREADS=4
export NUM_CHAR_FIELDS=0
export LENGTH_CHAR_FIELDS=512
export PERCENT_COMPRESSIBLE=25

export QUERIES_PER_INTERVAL=0
export QUERY_INTERVAL_SECONDS=30
export QUERY_LIMIT=1000
export QUERY_NUM_ROWS_BEGIN=100000000

export NUM_SECONDARY_INDEXES=3

export TOKUDB_DIRECTIO_CACHE=2G
export INNODB_CACHE=2G
export INNODB_KEY_BLOCK_SIZE=0


mysql-clean


# TokuDB - MySQL 5.5
export TARBALL=blank-toku753-mysql-5.5.40
export MYSQL_STORAGE_ENGINE=tokudb
export TOKUDB_DIRECTIO_CACHE=2G
export DIRECTIO=Y
export TOKUDB_COMPRESSION=quicklz
export NUM_ROWS_PER_INSERT=250
export RUN_MINUTES=30
export MAX_INSERTS_PER_SECOND=20000

export BENCH_ID=${TARBALL}-${TOKUDB_COMPRESSION}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}-${NUM_ROWS_PER_INSERT}-${MAX_INSERTS_PER_SECOND}
./doit.bash

export SKIP_DB_CREATE=Y
export CREATE_TABLE=N
export RUN_MINUTES=10

for maxInsertsPerSecond in 21000 22000 23000 24000 25000 26000 27000 28000 29000 30000 31000 32000 33000 34000 35000 36000 37000 38000 39000 40000 41000 42000 43000 44000 45000 46000 47000 48000 49000 50000; do
    export MAX_INSERTS_PER_SECOND=${maxInsertsPerSecond}
    export BENCH_ID=${TARBALL}-${TOKUDB_COMPRESSION}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}-${NUM_ROWS_PER_INSERT}-${MAX_INSERTS_PER_SECOND}
    ./doit.bash
done
