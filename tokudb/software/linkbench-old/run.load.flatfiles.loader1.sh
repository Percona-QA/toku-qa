#!/bin/sh

SOCKET_OPTION=--socket=/tmp/mysql.sock
DATABASE_NAME=linkdb
USER_NAME=root
USER_PASSWORD=""
FILE_PATH=$BACKUP_DIR/linkbench-mysqldump-150mm

echo "`date` | load linktable"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/linktable.txt' into table linktable fields terminated by ',' enclosed by '\"';"

echo "`date` | done - load linktable"
