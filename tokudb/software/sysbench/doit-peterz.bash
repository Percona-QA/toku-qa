#! /bin/bash

export NUM_TABLES=256
export RUN_TIME_SECONDS=7200
export NUM_ROWS=100000
export BENCHMARK_NUMBER=999
export threadCountList="0064"
export RAND_TYPE=pareto

export TARBALL=blank-percona-5_6_21.688-tokubackup-0.0.7

export MYSQL_STORAGE_ENGINE=tokudb
export TOKUDB_DIRECTIO_CACHE=4G
export TOKUDB_COMPRESSION=zlib
export TOKUDB_READ_BLOCK_SIZE=64K
export BENCH_ID=tokudb.${TOKUDB_COMPRESSION}.${NUM_TABLES}x${NUM_ROWS}.4G.${RAND_TYPE}
./doit-trickle.bash

#export MYSQL_STORAGE_ENGINE=innodb
#export INNODB_CACHE=4G
#export BENCH_ID=innodb.${TOKUDB_COMPRESSION}.1x50mm.4G.${RAND_TYPE}
#./doit-trickle.bash







