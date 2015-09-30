#!/bin/bash

#MYSQL_HOST=lex1
#MYSQL_PORT=33305
DATABASE_NAME=downloads
USER_NAME=root
USER_PASSWORD=""
FULL_FILE_PATH=/home/tcallaghan/data.tsv

echo $FULL_FILE_PATH

echo "`date` | drop database : ${DATABASE_NAME}"
$DB_DIR/bin/mysqladmin --user=${USER_NAME} --socket=${MYSQL_SOCKET} -f drop ${DATABASE_NAME}

date
echo "`date` | create database : ${DATABASE_NAME}"
$DB_DIR/bin/mysqladmin --user=${USER_NAME} --socket=${MYSQL_SOCKET} create ${DATABASE_NAME}

echo "`date` | create tables : downloads_raw"
$DB_DIR/bin/mysql --user=${USER_NAME} --socket=${MYSQL_SOCKET} ${DATABASE_NAME} < schema.sql

echo "`date` | load table : downloads_tsv"
$DB_DIR/bin/mysql --user=${USER_NAME} --socket=${MYSQL_SOCKET} ${DATABASE_NAME} -e "load data infile '$FULL_FILE_PATH' into table downloads_tsv fields terminated by '\t' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';"

FULL_FILE_PATH=/home/tcallaghan/users.tsv

echo "`date` | load table : registrations"
$DB_DIR/bin/mysql --user=${USER_NAME} --socket=${MYSQL_SOCKET} ${DATABASE_NAME} -e "load data infile '$FULL_FILE_PATH' into table registrations fields terminated by '\t' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';"

echo "`date` | done" | tee -a $LOG_NAME
