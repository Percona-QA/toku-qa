#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi
if [ -z "$SCP_TARGET" ]; then
    echo "Need to set SCP_TARGET"
    exit 1
fi

#export TARBALL=blank-toku703-mysql-5.5.30
#export TARBALL_ID=703

#export TARBALL=blank-loadermem2-mysql-5.5.30
#export TARBALL_ID=loadermem

export TARBALL=blank-loadermemcache-mysql-5.5.30
export TARBALL_ID=loadermemcache

export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.30
export MYSQL_STORAGE_ENGINE=tokudb
export TOKUDB_COMPRESSION=lzma
export TOKUDB_READ_BLOCK_SIZE=64K
export NUM_ROWS=50000000
export NUM_TABLES=3
export NUM_DATABASES=1

export LOADER_LOGGING=Y

export MYSQL_DATABASE=sbtest
export MYSQL_USER=root

export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}

export TOKUDB_DIRECTIO_CACHE=24G

#for runMegaBytes in 0000 0100 0250 0500 1000 2000; do 
for runMegaBytes in 0000 0100; do 

    export loaderMegaBytes=${runMegaBytes}
    export loaderBytes=$[loaderMegaBytes*1024*1024]

    echo "Creating database from ${TARBALL} in ${DB_DIR}"
    pushd $DB_DIR
    mkdb-quiet $TARBALL
    popd
    
    echo "Configuring my.cnf and starting database"
    pushd $DB_DIR
    
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    echo "tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE}" >> my.cnf
    echo "tokudb_directio=1" >> my.cnf
    echo "max_connections=2048" >> my.cnf
    echo "tokudb_loader_memory=${loaderBytes}" >> my.cnf
    
    mstart
    popd
    
    echo "Loading Data"
    ./run.load.flatfiles.sh
    
    echo "Stopping database"
    mstop

done


for i in *.txt; do
    echo ${i}
    grep "complete loader duration" ${i}
    grep "MAX DISK MB" ${i}
    grep "MAX MEMORY MB" ${i}
done


resultsTarball=${MACHINE_NAME}-loader-memory-${NUM_TABLES}-${NUM_ROWS}.tar.gz

tar czvf ${resultsTarball} ${TARBALL_ID}*
scp ${resultsTarball} ${SCP_TARGET}:~