#!/bin/sh

SOCKET_OPTION=--socket=/tmp/mysql.sock
USER_NAME=root
USER_PASSWORD=""
DATABASE_NAME=linkdb

echo "`date` | drop/create database, create tables"
mysql --user=$USER_NAME $SOCKET_OPTION < ddl_innodb.sql

echo "`date` | dropping key id2_vis on linktable"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "alter table linktable drop index id2_vis;"

echo "`date` | dropping key id1_type on linktable"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "alter table linktable drop index id1_type;"

echo "`date` | starting loader2"
./run.load.flatfiles.loader2.sh &

echo "`date` | starting loader1"
./run.load.flatfiles.loader1.sh

echo "`date` | creating key id2_vis on linktable"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "create index id2_vis on linktable (id2,visibility);"

echo "`date` | creating key id1_type on linktable"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "create index id1_type on linktable (id1,link_type,visibility,time,version,data);"

echo "`date` | done with index recreation on linktable"
