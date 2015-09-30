#!/bin/bash

MYSQL_SOCKET=${MYSQL_SOCKET}
MYSQL_USER=root
MYSQL_PASSWORD=""
DBNAME=sbtest

$DB_DIR/bin/mysqldump -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} -S ${MYSQL_SOCKET} ${DBNAME} --fields-terminated-by=, --fields-enclosed-by=\" --tab ./
