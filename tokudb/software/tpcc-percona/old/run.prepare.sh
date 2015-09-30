#!/bin/bash

SERVER_NAME=l
SOCKET_OPTION=--socket=/tmp/mysql.sock
DATABASE_NAME=tpcc
USER_NAME=root
USER_PASSWORD=
NUM_WAREHOUSES=500

LOG_NAME=log-run-loader55-10w.txt


rm $LOG_NAME

echo "`date` : drop database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=$USER_NAME $SOCKET_OPTION -f drop $DATABASE_NAME

echo "`date` : create database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=$USER_NAME $SOCKET_OPTION create $DATABASE_NAME

echo "`date` : create tables" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME < tpcc-mysql/create_table_innodb_compressed.sql

echo "`date` : load tables" | tee -a $LOG_NAME
tpcc-mysql/tpcc_load $SERVER_NAME $DATABASE_NAME $USER_NAME "$USER_PASSWORD" $NUM_WAREHOUSES 

echo "`date` : add secondary indexes" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME < tpcc-mysql/add_idx.sql

echo "`date` : add foreign keys" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME < tpcc-mysql/add_fkey.sql

echo "`date` : done" | tee -a $LOG_NAME
