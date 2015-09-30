#!/bin/bash

export NUM_ROWS=20000000
export RUN_TIME_SECONDS=600
#export NUM_ROWS=1000000
#export RUN_TIME_SECONDS=200

export WARMUP_TIME=30

export BENCHMARK_NUMBER=999
export SKIP_DB_CREATE=N
export MYSQL_HOST=localhost
export NUM_LOADERS=10
export INSERT_BATCH_SIZE=1000
export SCP_FILES=Y


# tokudb
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.38
export IS_MYSQL56=N
export MYSQL_STORAGE_ENGINE=tokudb
export TARBALL=blank-toku717-mysql-5.5.38
export DIRECTIO=Y
export TOKUDB_DIRECTIO_CACHE=1G
export TOKUDB_COMPRESSION=zlib
export TOKUDB_READ_BLOCK_SIZE=64K
export BENCH_ID=717.${TOKUDB_COMPRESSION}.${TOKUDB_READ_BLOCK_SIZE}
#./doit.bash


# innodb 5.6 uncompressed / compressed
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.6.17
export IS_MYSQL56=Y
export MYSQL_STORAGE_ENGINE=innodb
export TARBALL=blank-mysql5617
export BENCH_ID=5.6.17.innodb
export DIRECTIO=Y
export INNODB_CACHE=1G
export INNODB_COMPRESSION=N
./doit.bash
export INNODB_COMPRESSION=Y
./doit.bash


# innodb 5.5 uncompressed / compressed
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.37
export IS_MYSQL56=N
export MYSQL_STORAGE_ENGINE=innodb
export TARBALL=blank-mysql5537
export BENCH_ID=5.5.37.innodb
export DIRECTIO=N
export INNODB_CACHE=1G
export INNODB_COMPRESSION=N
#./doit.bash
export INNODB_COMPRESSION=Y
#./doit.bash


# big test - new ssd
for compressionType in quicklz zlib ; do
  for basementNodeSize in 8K 16K 32K 64K ; do
    export MYSQL_NAME=mysql
    export MYSQL_VERSION=5.5.38
    export IS_MYSQL56=N
    export MYSQL_STORAGE_ENGINE=tokudb
    export TARBALL=blank-toku717-mysql-5.5.38
    export TOKUDB_COMPRESSION=${compressionType}
    export TOKUDB_READ_BLOCK_SIZE=${basementNodeSize}
    export BENCH_ID=717.${TOKUDB_COMPRESSION}.${TOKUDB_READ_BLOCK_SIZE}.SSD
    export DIRECTIO=Y
    export TOKUDB_DIRECTIO_CACHE=1G
    ./doit.bash
  done
done


# big test - in RAM
#for compressionType in uncompressed quicklz zlib lzma ; do
#for compressionType in quicklz zlib lzma ; do
#  for basementNodeSize in 8K 16K 32K 64K 128K ; do
#    export MYSQL_NAME=mysql
#    export MYSQL_VERSION=5.5.37
#    export IS_MYSQL56=N
#    export MYSQL_STORAGE_ENGINE=tokudb
#    export TARBALL=blank-toku716-mysql-5.5.37
#    export TOKUDB_COMPRESSION=${compressionType}
#    export TOKUDB_READ_BLOCK_SIZE=${basementNodeSize}
#    export BENCH_ID=716.${TOKUDB_COMPRESSION}.${TOKUDB_READ_BLOCK_SIZE}.RAM
#    export DIRECTIO=N
#    export TOKUDB_DIRECTIO_CACHE=1G
#    ./doit.bash
#  done
#done

# tokudb - custom build - all 8K basement nodes
#for compressionType in uncompressed quicklz zlib lzma ; do
#  for basementNodeSize in 8K ; do
#    export MYSQL_NAME=mysql
#    export MYSQL_VERSION=5.5.38
#    export IS_MYSQL56=N
#    export MYSQL_STORAGE_ENGINE=tokudb
#    export TARBALL=blank-tokudb.current.20140609-mysql-5.5.38
#    export TOKUDB_COMPRESSION=${compressionType}
#    export TOKUDB_READ_BLOCK_SIZE=${basementNodeSize}
#    export BENCH_ID=current_20140609.${TOKUDB_COMPRESSION}.${TOKUDB_READ_BLOCK_SIZE}.RAM
#    export DIRECTIO=N
#    export TOKUDB_DIRECTIO_CACHE=1G
#    ./doit.bash
#  done
#done

