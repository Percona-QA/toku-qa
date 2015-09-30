#!/bin/sh

STORAGE_ENGINE=innodb

SOCKET_NAME=/tmp/mysql.sock
DATABASE_NAME=test
USER_NAME=root
USER_PASSWORD=""

date
echo "create tables"
mysql --user=$USER_NAME --socket=$SOCKET_NAME $DATABASE_NAME < schema_$STORAGE_ENGINE.sql

ant clean default run
