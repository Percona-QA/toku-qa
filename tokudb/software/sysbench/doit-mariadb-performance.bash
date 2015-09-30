#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi


export TOKUDB_COMPRESSION=lzma
export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
export NUM_TABLES=16
export NUM_DATABASES=1
export RUN_TIME_SECONDS=300
export RAND_TYPE=uniform
export NUM_ROWS=10000000
export TOKUDB_READ_BLOCK_SIZE=64K
export BENCHMARK_NUMBER=004
export MYSQL_STORAGE_ENGINE=tokudb
export TOKUDB_CACHE=8GB
export INNODB_CACHE=8GB
export LOADER_LOGGING=Y
export BENCHMARK_LOGGING=Y
export READONLY=off
export MYSQL_DATABASE=sbtest
export MYSQL_USER=root
export threadCountList="0064 0128"

        
# *******************************************************************************************
# MARIADB 10.0.8
# *******************************************************************************************

export MYSQL_NAME=mariadb
export MYSQL_VERSION=10.0.8
export TARBALL=blank-mariadb-1008
export BENCH_ID=mariadb1008theirs.${TOKUDB_COMPRESSION}.10mm.${RAND_TYPE}

echo "Creating database from ${TARBALL} in ${DB_DIR}"
pushd $DB_DIR
mkdb-quiet $TARBALL
popd

echo "Configuring my.cnf and starting database"
pushd $DB_DIR
if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
else
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    echo "tokudb_cache_size=${TOKUDB_CACHE}" >> my.cnf
    echo "tokudb_directio=1" >> my.cnf
fi
echo "max_connections=2048" >> my.cnf
echo "performance_schema=OFF" >> my.cnf
mstart
popd

echo "Loading Data"
pushd fastload
./run.load.flatfiles.sh
popd
    
echo "Running benchmark"
./run.benchmark.sh

echo "Stopping database"
mstop



# *******************************************************************************************
# MARIADB 5.5.36 - Theirs
# *******************************************************************************************

export MYSQL_NAME=mariadb
export MYSQL_VERSION=5.5.36
export TARBALL=blank-mariadb-5536
export BENCH_ID=mariadb5536theirs.${TOKUDB_COMPRESSION}.10mm.${RAND_TYPE}

echo "Creating database from ${TARBALL} in ${DB_DIR}"
pushd $DB_DIR
mkdb-quiet $TARBALL
popd

echo "Configuring my.cnf and starting database"
pushd $DB_DIR
if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
else
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    echo "tokudb_cache_size=${TOKUDB_CACHE}" >> my.cnf
    echo "tokudb_directio=1" >> my.cnf
fi
echo "max_connections=2048" >> my.cnf
echo "performance_schema=OFF" >> my.cnf
mstart
popd

echo "Loading Data"
pushd fastload
./run.load.flatfiles.sh
popd
    
echo "Running benchmark"
./run.benchmark.sh

echo "Stopping database"
mstop



# *******************************************************************************************
# MARIADB 5.5.30 - Ours (v7.1.0)
# *******************************************************************************************

export MYSQL_NAME=mariadb
export MYSQL_VERSION=5.5.30
export TARBALL=blank-toku710-mariadb-5.5.30
export BENCH_ID=toku710maria5530.${TOKUDB_COMPRESSION}.10mm.${RAND_TYPE}

echo "Creating database from ${TARBALL} in ${DB_DIR}"
pushd $DB_DIR
mkdb-quiet $TARBALL
popd

echo "Configuring my.cnf and starting database"
pushd $DB_DIR
if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
else
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    echo "tokudb_cache_size=${TOKUDB_CACHE}" >> my.cnf
    echo "tokudb_directio=1" >> my.cnf
fi
echo "max_connections=2048" >> my.cnf
echo "performance_schema=OFF" >> my.cnf
mstart
popd

echo "Loading Data"
pushd fastload
./run.load.flatfiles.sh
popd
    
echo "Running benchmark"
./run.benchmark.sh

echo "Stopping database"
mstop



# *******************************************************************************************
# MYSQL 5.5.30 - Ours (v7.1.0)
# *******************************************************************************************

export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.30
export TARBALL=blank-toku710-mysql-5.5.30
export BENCH_ID=toku710mysql5530.${TOKUDB_COMPRESSION}.10mm.${RAND_TYPE}

echo "Creating database from ${TARBALL} in ${DB_DIR}"
pushd $DB_DIR
mkdb-quiet $TARBALL
popd

echo "Configuring my.cnf and starting database"
pushd $DB_DIR
if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
else
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    echo "tokudb_cache_size=${TOKUDB_CACHE}" >> my.cnf
    echo "tokudb_directio=1" >> my.cnf
fi
echo "max_connections=2048" >> my.cnf
echo "performance_schema=OFF" >> my.cnf
mstart
popd

echo "Loading Data"
pushd fastload
./run.load.flatfiles.sh
popd
    
echo "Running benchmark"
./run.benchmark.sh

echo "Stopping database"
mstop



# *******************************************************************************************
# MYSQL 5.5.36 - Ours (v7.1.5.rc4)
# *******************************************************************************************

export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.36
export TARBALL=blank-toku715rc4-mysql-5.5.36
export BENCH_ID=toku715rc4mysql5536.${TOKUDB_COMPRESSION}.10mm.${RAND_TYPE}

echo "Creating database from ${TARBALL} in ${DB_DIR}"
pushd $DB_DIR
mkdb-quiet $TARBALL
popd

echo "Configuring my.cnf and starting database"
pushd $DB_DIR
if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
else
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    echo "tokudb_cache_size=${TOKUDB_CACHE}" >> my.cnf
    echo "tokudb_directio=1" >> my.cnf
fi
echo "max_connections=2048" >> my.cnf
echo "performance_schema=OFF" >> my.cnf
mstart
popd

echo "Loading Data"
pushd fastload
./run.load.flatfiles.sh
popd
    
echo "Running benchmark"
./run.benchmark.sh

echo "Stopping database"
mstop


