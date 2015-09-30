#! /bin/bash

$DB_DIR/bin/mysql --user=root --password='' --socket=${MYSQL_SOCKET} test -e "SELECT dateandtime, cashregisterid, customerid, productid, price, data FROM purchases_index INTO OUTFILE '/home/tcallaghan/temp/data-small.txt' FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n';"

# load data infile '/home/tcallaghan/temp/data-small.txt' into table purchases_index (dateandtime, cashregisterid, customerid, productid, price, data);
