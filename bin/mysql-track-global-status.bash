#!/bin/bash

# wait between checks
WAIT_TIME_SECONDS=$2

while true ; do
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "select * from information_schema.global_status where variable_name like '%${1}%' order by variable_name"
    sleep $WAIT_TIME_SECONDS
done
