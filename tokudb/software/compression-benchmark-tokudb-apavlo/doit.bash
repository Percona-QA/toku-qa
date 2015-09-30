#!/bin/bash

export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.37
export MYSQL_DATABASE=compression
export MYSQL_USER=root


# sorted vs. random
#export INFILE_NAME=peersnapshots-01-random.csv
#export INFILE_NAME=peersnapshots-01.csv

# TokuDB: bulk vs. trickle
export TOKUDB_BULK_LOAD=Y


# tokudb
export MYSQL_STORAGE_ENGINE=tokudb
export TARBALL=blank-toku716-mysql-5.5.37

export INFILE_NAME=peersnapshots-01.csv
export TOKUDB_BULK_LOAD=Y
export LOG_NAME=${PWD}/${MACHINE_NAME}-${MYSQL_STORAGE_ENGINE}-compression-sorted-bulk.log
for compressionType in lzma zlib quicklz uncompressed; do
    for basementSize in 16K 32K 64K 128K 256K 512K 1024K; do
        export TOKUDB_COMPRESSION=${compressionType}
        export TOKUDB_READ_BLOCK_SIZE=${basementSize}
        export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
        ./run.load.bash

        # rest for a minute
        sleep 60
    done
done
scp ${LOG_NAME} ${SCP_TARGET}:~

export INFILE_NAME=peersnapshots-01.csv
export TOKUDB_BULK_LOAD=N
export LOG_NAME=${PWD}/${MACHINE_NAME}-${MYSQL_STORAGE_ENGINE}-compression-sorted-trickle.log
for compressionType in lzma zlib quicklz uncompressed; do
    for basementSize in 16K 32K 64K 128K 256K 512K 1024K; do
        export TOKUDB_COMPRESSION=${compressionType}
        export TOKUDB_READ_BLOCK_SIZE=${basementSize}
        export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
        ./run.load.bash

        # rest for a minute
        sleep 60
    done
done
scp ${LOG_NAME} ${SCP_TARGET}:~

export INFILE_NAME=peersnapshots-01-random.csv
export TOKUDB_BULK_LOAD=Y
export LOG_NAME=${PWD}/${MACHINE_NAME}-${MYSQL_STORAGE_ENGINE}-compression-random-bulk.log
for compressionType in lzma zlib quicklz uncompressed; do
    for basementSize in 16K 32K 64K 128K 256K 512K 1024K; do
        export TOKUDB_COMPRESSION=${compressionType}
        export TOKUDB_READ_BLOCK_SIZE=${basementSize}
        export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
        ./run.load.bash

        # rest for a minute
        sleep 60
    done
done
scp ${LOG_NAME} ${SCP_TARGET}:~

export INFILE_NAME=peersnapshots-01-random.csv
export TOKUDB_BULK_LOAD=N
export LOG_NAME=${PWD}/${MACHINE_NAME}-${MYSQL_STORAGE_ENGINE}-compression-random-trickle.log
for compressionType in lzma zlib quicklz uncompressed; do
    for basementSize in 16K 32K 64K 128K 256K 512K 1024K; do
        export TOKUDB_COMPRESSION=${compressionType}
        export TOKUDB_READ_BLOCK_SIZE=${basementSize}
        export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
        ./run.load.bash

        # rest for a minute
        sleep 60
    done
done
scp ${LOG_NAME} ${SCP_TARGET}:~


# innodb 5.5
export MYSQL_STORAGE_ENGINE=innodb
export TARBALL=blank-mysql5537

export INFILE_NAME=peersnapshots-01.csv
export LOG_NAME=${PWD}/${MACHINE_NAME}-${MYSQL_STORAGE_ENGINE}-55-compression-sorted.log
for compressionType in none 8 4 2 1 ; do
    export MYSQL_STORAGE_ENGINE=innodb_${compressionType}
    ./run.load.bash

    # rest for a minute
    sleep 60
done
scp ${LOG_NAME} ${SCP_TARGET}:~

export MYSQL_STORAGE_ENGINE=innodb

export INFILE_NAME=peersnapshots-01-random.csv
export LOG_NAME=${PWD}/${MACHINE_NAME}-${MYSQL_STORAGE_ENGINE}-55-compression-random.log
for compressionType in none 8 4 2 1 ; do
    export MYSQL_STORAGE_ENGINE=innodb_${compressionType}
    ./run.load.bash

    # rest for a minute
    sleep 60
done
scp ${LOG_NAME} ${SCP_TARGET}:~


# innodb 5.6
export MYSQL_STORAGE_ENGINE=innodb
export TARBALL=blank-mysql5617

export INFILE_NAME=peersnapshots-01.csv
export LOG_NAME=${PWD}/${MACHINE_NAME}-${MYSQL_STORAGE_ENGINE}-56-compression-sorted.log
for compressionType in none 8 4 2 1 ; do
    export MYSQL_STORAGE_ENGINE=innodb_${compressionType}
    ./run.load.bash

    # rest for a minute
    sleep 60
done
scp ${LOG_NAME} ${SCP_TARGET}:~

export MYSQL_STORAGE_ENGINE=innodb

export INFILE_NAME=peersnapshots-01-random.csv
export LOG_NAME=${PWD}/${MACHINE_NAME}-${MYSQL_STORAGE_ENGINE}-56-compression-random.log
for compressionType in none 8 4 2 1 ; do
    export MYSQL_STORAGE_ENGINE=innodb_${compressionType}
    ./run.load.bash

    # rest for a minute
    sleep 60
done
scp ${LOG_NAME} ${SCP_TARGET}:~
