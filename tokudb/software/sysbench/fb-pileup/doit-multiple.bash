#!/bin/bash

export SCP_FILES=Y
export INNODB_CACHE=16G
export TOKUDB_DIRECTIO_CACHE=16G
export TOKUDB_COMPRESSION=quicklz
export NUM_ROWS=10000000
#export NUM_TABLES=16
export NUM_TABLES=1
export RUN_TIME_SECONDS=180
export RAND_TYPE=uniform
export TOKUDB_READ_BLOCK_SIZE=64K
export BENCHMARK_NUMBER=999
export threadCountList="0001 0004 0016 0064 0128 0256 0512 1024"
#export threadCountList="0064"
export BENCHMARK_LOGGING=Y

export DIRECTIO=N
if [ ${DIRECTIO} == "Y" ]; then
    directIoString="directIO"
else
    directIoString="bufferedIO"
fi




export threadCountList="0001 0002 0004 0008 0016 0032 0064 0128 0256 0512 1024"

# TokuDB 750
export TARBALL=blank-toku753-mysql-5.5.40.tar.gz
export BENCH_ID=753.${TOKUDB_COMPRESSION}.10mm
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.40
export MYSQL_STORAGE_ENGINE=tokudb
./doit.bash

# TokuDB 753+ (including snappy)
#export TARBALL=blank-custom-tokudb-snappy
#export MYSQL_NAME=mysql
#export MYSQL_VERSION=5.5.40
#export MYSQL_STORAGE_ENGINE=tokudb
#for tokudbCompression in snappy quicklz zlib lzma ; do
#for tokudbCompression in snappy quicklz ; do
#    export TOKUDB_COMPRESSION=${tokudbCompression}
#    export BENCH_ID=753plus.${TOKUDB_COMPRESSION}.80mm.${directIoString}.${TOKUDB_READ_BLOCK_SIZE}
#    ./doit.bash
#done

# InnoDB 5.5.37
#export TARBALL=blank-mysql5537
#export BENCH_ID=5537.4mm
#export MYSQL_NAME=mysql
#export MYSQL_VERSION=5.5.37
#export MYSQL_STORAGE_ENGINE=innodb
#./doit.bash

# WiredTiger
# NOT YET WORKING, DATA LOOKS BAD!
#export TARBALL=wiredtiger-20140825-mysql-5.7.4.m14
#export BENCH_ID=574m14.4mm
#export MYSQL_NAME=mysql
#export MYSQL_VERSION=5.7.4.m14
#export MYSQL_STORAGE_ENGINE=wiredtiger
#./doit.bash
