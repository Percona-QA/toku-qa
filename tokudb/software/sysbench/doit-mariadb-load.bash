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
export SYSBENCH_DIR=sysbench-0.5/sysbench

export PARALLEL_TRICKLE_LOADERS=8


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
$DB_DIR/bin/mysql -S ${MYSQL_SOCKET} -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} -e "drop database if exists ${MYSQL_DATABASE}"
$DB_DIR/bin/mysql -S ${MYSQL_SOCKET} -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} -e "create database ${MYSQL_DATABASE}"


T="$(date +%s)"

# single trickle loader
#sysbench --test=${SYSBENCH_DIR}/tests/db/oltp.lua --mysql-table-engine=${MYSQL_STORAGE_ENGINE} --oltp_tables_count=${NUM_TABLES} --oltp-table-size=${NUM_ROWS} --mysql-socket=${MYSQL_SOCKET} --mysql-user=${MYSQL_USER} --mysql-password=${MYSQL_PASSWORD} prepare

# parallel trickle loaders
sysbench --test=${SYSBENCH_DIR}/tests/db/parallel_prepare.lua --mysql-table-engine=${MYSQL_STORAGE_ENGINE} --oltp_tables_count=${NUM_TABLES} --oltp-table-size=${NUM_ROWS} --mysql-socket=${MYSQL_SOCKET} --mysql-user=${MYSQL_USER} --mysql-password=${MYSQL_PASSWORD} --num_threads=${PARALLEL_TRICKLE_LOADERS} run

echo "Stopping database"
mstop

T="$(($(date +%s)-T))"
printf "`date` | complete loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))"

echo ""
echo "-------------------------------"
echo "Sizing Information             "
echo "-------------------------------"

currentDate=`date`

if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    INNODB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/${MYSQL_DATABASE}*/*.ibd | tail -n 1 | cut -f1`
    INNODB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/${MYSQL_DATABASE}*/*.ibd | tail -n 1 | cut -f1`
    INNODB_SIZE_MB=`echo "scale=2; ${INNODB_SIZE_BYTES}/(1024*1024)" | bc `
    INNODB_SIZE_APPARENT_MB=`echo "scale=2; ${INNODB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
    echo "${currentDate} | loader InnoDB sizing (SizeMB / ASizeMB) = ${INNODB_SIZE_MB} / ${INNODB_SIZE_APPARENT_MB}"
else
    TOKUDB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
    TOKUDB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
    TOKUDB_SIZE_MB=`echo "scale=2; ${TOKUDB_SIZE_BYTES}/(1024*1024)" | bc `
    TOKUDB_SIZE_APPARENT_MB=`echo "scale=2; ${TOKUDB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
    echo "${currentDate} | loader TokuDB sizing (SizeMB / ASizeMB) = ${TOKUDB_SIZE_MB} / ${TOKUDB_SIZE_APPARENT_MB}"
fi
