#!/bin/sh

SOCKET_OPTION=--socket=/tmp/mysql.sock
USER_NAME=root
USER_PASSWORD=""
DATABASE_NAME=linkdb

echo "`date` | drop/create database, create tables"
mysql --user=$USER_NAME $SOCKET_OPTION < ddl_tokudb.sql

echo "`date` | starting loader2"
./run.load.flatfiles.loader2.sh &

echo "`date` | starting loader1"
./run.load.flatfiles.loader1.sh &
