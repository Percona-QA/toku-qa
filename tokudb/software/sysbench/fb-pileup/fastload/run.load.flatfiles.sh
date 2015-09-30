#!/bin/bash

# pick your storage engine (tokudb or innodb or innodb_compressed)
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    echo "Need to set MYSQL_STORAGE_ENGINE"
    exit 1
fi
if [ -z "$MYSQL_SOCKET" ]; then
    echo "Need to set MYSQL_SOCKET"
    exit 1
fi
if [ -z "$LOADER_LOGGING" ]; then
    echo "Need to set LOADER_LOGGING"
    exit 1
fi
if [ -z "$MYSQL_DATABASE" ]; then
    echo "Need to set MYSQL_DATABASE"
    exit 1
fi
if [ -z "$MYSQL_USER" ]; then
    echo "Need to set MYSQL_USER"
    exit 1
fi

echo "mysql_storage_engine = $MYSQL_STORAGE_ENGINE"
echo "mysql_socket = $MYSQL_SOCKET"

LOG_NAME=log-load-sysbench-flat-files.txt

rm -f ./loader1.log.done 
rm -f ./loader2.log.done


echo "`date` | drop database"
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} -f drop ${MYSQL_DATABASE}

echo "`date` | create database"
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} create ${MYSQL_DATABASE}

echo "`date` | create tables"
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < create_schema_$MYSQL_STORAGE_ENGINE.sql

echo "`date` | starting loader1"
./run.load.flatfiles.loader1.sh &

echo "`date` | starting loader2"
./run.load.flatfiles.loader2.sh &

echo "waiting for loaders to complete..."

while ( [ ! -e "./loader1.log.done" ] || [ ! -e "./loader2.log.done" ] ); do
    sleep 60
    echo "waiting for loaders to complete..."
done

bkill
