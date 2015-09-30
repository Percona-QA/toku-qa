#!/bin/bash

if [ -z "$MYSQL_SOCKET" ]; then
    echo "Need to set MYSQL_SOCKET"
    exit 1
fi

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi

if [ -z "$INFILE_NAME" ]; then
    echo "Need to set INFILE_NAME"
    exit 1
fi
#INFILE_NAME=peersnapshots-01.csv
#INFILE_NAME=peersnapshots-01-random.csv

if [ -z "$LOG_NAME" ]; then
    echo "Need to set LOG_NAME"
    exit 1
fi
#LOG_NAME=${PWD}/compression-test-sorted-trickle.log


FILE_DIR=customers/andy-pavlo
TABLE_NAME=apavlo

if [ -e "${LOCAL_BACKUP_DIR}/${FILE_DIR}/${INFILE_NAME}" ]; then
    echo "using local filesystem"
    FULL_FILE_PATH=${LOCAL_BACKUP_DIR}/${FILE_DIR}/${INFILE_NAME}
else
    echo "using nfs"
    FULL_FILE_PATH=${BACKUP_DIR}/${FILE_DIR}/${INFILE_NAME}
fi

echo "Creating database from ${TARBALL} in ${DB_DIR}"
pushd $DB_DIR
mkdb-quiet $TARBALL
popd

echo "Configuring my.cnf and starting database"
pushd $DB_DIR
if [ ${MYSQL_STORAGE_ENGINE} == "tokudb" ]; then
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    if [ ${TOKUDB_BULK_LOAD} == "Y" ]; then
        echo "tokudb_prelock_empty=1" >> my.cnf
    else
        echo "tokudb_prelock_empty=0" >> my.cnf
    fi
    echo "tokudb_cache_size=8G" >> my.cnf
    echo "******************************************************************************************" | tee -a $LOG_NAME
    echo "${MYSQL_STORAGE_ENGINE}-${TOKUDB_READ_BLOCK_SIZE}-${TOKUDB_ROW_FORMAT}" | tee -a $LOG_NAME
else
    echo "innodb_buffer_pool_size=8G" >> my.cnf
    echo "******************************************************************************************" | tee -a $LOG_NAME
    echo "${MYSQL_STORAGE_ENGINE}" | tee -a $LOG_NAME
fi
mstart
popd

echo "`date` | drop database ${MYSQL_DATABASE}"
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} -f drop ${MYSQL_DATABASE}

echo "`date` | create database ${MYSQL_DATABASE}"
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} create ${MYSQL_DATABASE}

echo "`date` | create table ${TABLE_NAME}"
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < create_schema_$MYSQL_STORAGE_ENGINE.sql


# Get time as a UNIX timestamp (seconds elapsed since Jan 1, 1970 0:00 UTC)
T="$(date +%s)"

#echo "`date` | load table ${TABLE_NAME}" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "load data infile '$FULL_FILE_PATH' into table ${TABLE_NAME} fields terminated by ',' enclosed by '\"' lines terminated by '\r\n' ignore 1 lines;"

#echo "`date` | done - loader" | tee -a $LOG_NAME

T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "select count(*) from ${TABLE_NAME};"

echo "Stopping database"
mstop

TOKUDB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
INNODB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/${MYSQL_DATABASE}*/*.ibd | tail -n 1 | cut -f1`
TOKUDB_SIZE_MB=`echo "scale=2; ${TOKUDB_SIZE_BYTES}/(1024*1024)" | bc `
INNODB_SIZE_MB=`echo "scale=2; ${INNODB_SIZE_BYTES}/(1024*1024)" | bc `

if [ ${MYSQL_STORAGE_ENGINE} == "tokudb" ]; then
    echo "`date` | loader TokuDB sizing (MB) = ${TOKUDB_SIZE_MB}" | tee -a $LOG_NAME
else
    echo "`date` | loader InnoDB sizing (MB) = ${INNODB_SIZE_MB}" | tee -a $LOG_NAME
fi
echo "" | tee -a $LOG_NAME
echo "" | tee -a $LOG_NAME

