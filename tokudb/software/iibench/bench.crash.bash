#/bin/bash

#if [ -z "$TOKUDB_DIRECTIO_CACHE" ]; then
#    echo "Need to set $TOKUDB_DIRECTIO_CACHE"
#    exit 1
#fi

export TOKUDB_DIRECTIO_CACHE=8GB
export RUN_MINUTES=60
export DIRECTIO=Y

export INSERT_ONLY=0

export TOKUDB_CACHE_SIZE=${TOKUDB_DIRECTIO_CACHE}
export TOKUDB_COMPRESSION=zlib
export TOKUDB_READ_BLOCK_SIZE=65536

export SINGLE_FLUSH=Y
export END_ITERATION_NUMBER=5
export END_ITERATION_SLEEP_SECONDS=120

export BENCHMARK_NUMBER=999

export TARBALL=blank-toku671.52604-mysql-5.5.28
export BENCH_ID=671.52604.zlib.64k

echo "Running benchmark"
./run.benchmark.sh
