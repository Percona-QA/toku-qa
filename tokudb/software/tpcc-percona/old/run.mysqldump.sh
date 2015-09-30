#drop table if exists warehouse;
#drop table if exists district;
#drop table if exists customer;
#drop table if exists history;
#drop table if exists new_orders;
#drop table if exists orders;
#drop table if exists order_line;
#drop table if exists item;
#drop table if exists stock;

#mysqldump -u root --socket=/tmp/mysql.sock tpcc --fields-terminated-by=, --fields-enclosed-by=\" --tab ./  --tables item
$DB_DIR/bin/mysqldump -u root --socket=/tmp/mysql.sock tpcc --fields-terminated-by=, --fields-enclosed-by=\" --tab ./
