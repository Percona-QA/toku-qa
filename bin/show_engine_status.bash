#! /bin/bash

$DB_DIR/bin/mysql --user=root --socket=${MYSQL_SOCKET} -e "show engine tokudb status;" > show_engine_status.txt

