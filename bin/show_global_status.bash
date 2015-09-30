#! /bin/bash

$DB_DIR/bin/mysql --user=root --socket=${MYSQL_SOCKET} -e "select * from information_schema.global_status where (variable_name like '%TOKUDB%') order by 1;" > show_global_status.txt

