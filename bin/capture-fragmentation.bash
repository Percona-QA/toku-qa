#!/bin/bash

# wait between checks
WAIT_TIME_SECONDS=$1

MYSQL_USER=$2
MYSQL_PASSWORD=""
MYSQL_SOCKET=$3
LOG_NAME=$4

# kill existing log file if it exists
rm -f $LOG_NAME

while [ 1 -eq 1 ] ; do
    echo "******************************" >> $LOG_NAME
    date >> $LOG_NAME
    echo "******************************" >> $LOG_NAME
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "select dictionary_name, internal_file_name, bt_size_allocated / (1024 * 1024) as size_files_mb, (1 - (bt_size_in_use / bt_size_allocated)) * 100 as frag_perc,  (bt_size_allocated / (1024 * 1024) * (1 - (bt_size_in_use / bt_size_allocated))) as frag_mb from information_schema.tokudb_fractal_tree_info order by frag_mb desc;" >> $LOG_NAME
    sleep $WAIT_TIME_SECONDS
done
