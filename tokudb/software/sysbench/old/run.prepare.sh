#!/bin/bash

NUM_ROWS=500000000
NUM_TABLES=1
MYSQL_SOCKET=${MYSQL_SOCKET}
MYSQL_USER=root
MYSQL_PASSWORD=""
ENGINE=tokudb
SYSBENCH_DIR=sysbench-0.5/sysbench
DBNAME=sbtest

$DB_DIR/bin/mysql -S ${MYSQL_SOCKET} -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} -e "drop database if exists ${DBNAME}"
$DB_DIR/bin/mysql -S ${MYSQL_SOCKET} -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} -e "create database ${DBNAME}"

sysbench --test=${SYSBENCH_DIR}/tests/db/oltp.lua --mysql-table-engine=${ENGINE} --oltp_tables_count=${NUM_TABLES} --oltp-table-size=${NUM_ROWS} --mysql-socket=${MYSQL_SOCKET} --mysql-user=${MYSQL_USER} --mysql-password=${MYSQL_PASSWORD} prepare
