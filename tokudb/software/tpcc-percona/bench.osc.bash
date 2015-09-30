#/bin/bash

# generic settings
export MYSQL_NAME=mysql
export NUM_WAREHOUSES=100
export RUN_TIME_SECONDS=7200
export RUN_ARBITRARY_SQL=Y
export arbitrarySqlWaitSeconds=300
export SCP_FILES=Y
export NEW_ORDERS_PER_TEN_SECONDS=200000
export BENCHMARK_NUMBER=999
export DIRECTIO=N
export threadCountList="0064"
export DO_WARMUP=N
export BENCHMARK_NUMBER=999


# tokudb
#export MYSQL_VERSION=5.5.28
#export MYSQL_STORAGE_ENGINE=tokudb
#export TOKUDB_COMPRESSION=quicklz
#export TOKUDB_READ_BLOCK_SIZE=64K
#export TARBALL=blank-toku664.52174-mysql-5.5.28
#export BENCH_ID=664.52174.${TOKUDB_COMPRESSION}.${TOKUDB_READ_BLOCK_SIZE}.OSC
#./doit.bash

# mysql5.5
#unset INNODB_ONLINE_ALTER_LOG_MAX_SIZE
#export MYSQL_VERSION=5.5.29
#export MYSQL_STORAGE_ENGINE=innodb
#export TARBALL=blank-mysql5529
#export BENCH_ID=mysql.55.OSC
#./doit.bash

# mysql5.6
export INNODB_ONLINE_ALTER_LOG_MAX_SIZE=50G
export MYSQL_VERSION=5.6.10
export MYSQL_STORAGE_ENGINE=innodb
export TARBALL=blank-mysql5610
export BENCH_ID=mysql.56.OSC
./doit.bash
