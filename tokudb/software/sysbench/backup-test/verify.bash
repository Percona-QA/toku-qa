#!/bin/bash

if [ -z "$MYSQL_SOCKET" ]; then
    echo "Need to set MYSQL_SOCKET"
    exit 1
fi
if [ -z "$VERIFY_LOG_NAME" ]; then
    echo "Need to set VERIFY_LOG_NAME"
    exit 1
fi

MYSQL_SOCKET=$MYSQL_SOCKET

MYSQL_DATABASE=sbtest
MYSQL_USER=root
NUM_TABLES=$1

echo "recreating sbcheck1 and sbcheck2"
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "drop table if exists sbcheck1; drop table if exists sbcheck2;"
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "create table sbcheck1 (table_name varchar(30) not null, check1 bigint default 0 not null) engine=tokudb;"
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "create table sbcheck2 (table_name varchar(30) not null, check2 bigint default 0 not null) engine=tokudb;"

TABLE_NUM=1
while [ ${TABLE_NUM} -le ${NUM_TABLES} ]; do
    thisTable=sbtest${TABLE_NUM}
    echo "calculating checksum for ${thisTable}"
    $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "insert into sbcheck1 (table_name, check1) select '${thisTable}', sum(c1) from ${thisTable};"
    let TABLE_NUM=TABLE_NUM+1
done

echo "calculating checksums for sbvalid"
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "insert into sbcheck2 (table_name, check2) select table_name, sum(c1) from sbvalid group by table_name;"

echo "displaying results"
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "select sbcheck1.table_name, sbcheck1.check1 - sbcheck2.check2 from sbcheck1, sbcheck2 where sbcheck1.table_name = sbcheck2.table_name order by 1;" >> ${VERIFY_LOG_NAME}

echo "checking tables"
TABLE_NUM=1
while [ ${TABLE_NUM} -le ${NUM_TABLES} ]; do
    thisTable=sbtest${TABLE_NUM}
    echo "checking ${thisTable}"
    echo "checking ${thisTable}" >> ${VERIFY_LOG_NAME}
    $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "check table ${thisTable};" >> ${VERIFY_LOG_NAME}
    let TABLE_NUM=TABLE_NUM+1
done
