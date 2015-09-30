#!/bin/sh

#RUN_TIME is measured in seconds
#RUN_TIME=3600
#NUM_ROWS=50000000
#NUM_TABLES=16
#REPORT_INTERVAL=10
#SHOW_ENGINE_STATUS_INTERVAL=60
#SHOW_SYSINFO_INTERVAL=60
#IOSTAT_INTERVAL=10
#IOSTAT_ROUNDS=$[RUN_TIME/IOSTAT_INTERVAL+1]
#DSTAT_INTERVAL=10
#DSTAT_ROUNDS=$[RUN_TIME/DSTAT_INTERVAL+1]

MYSQL_SOCKET=/tmp/mysql.sock
MYSQL_USER=root
MYSQL_PASSWORD=""
ENGINE=tokudb
DBNAME=linkdb

LOG_SERVER_TYPE=mm
LOG_DB_NAME=mysql
LOG_DB_VERSION=5.1.52
LOG_ENGINE_VERSION=main.4610.64k.lzma
LOG_BENCHMARK_NAME=linkbench
COMMIT_SYNC=1

javac com/facebook/LinkBench/*.java

# create database and tables
$DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET < ddl_${ENGINE}.sql

# optional load optimizations
#alter table linktable drop key `id2_vis`, drop key `id1_type`;
#set global innodb_flush_log_at_trx_commit = 2;
#set global sync_binlog = 0;

# LOAD DATA . takes about ????? seconds.
java com.facebook.LinkBench.LinkBenchDriver ./LinkConfigMysql-load-10mm.properties 1 | tee $LOG_NAME

# You will see last line of output like this
#LOAD PHASE COMPLETED. Expected to load 49999998 links. 49990000 loaded in 5057 seconds.Links/second = 9884

# Check size of ibd files (total should be close to 10G approx for InnoDB)
#du -cb data/mysql/linkdb | tail -n 1
#du -cb data/*.tokudb | tail -n 1

# REVERT THE OPTIMIZATIONS DONE FOR LOAD
#set global innodb_flush_log_at_trx_commit = 1;
#set global sync_binlog = 1;
# this takes about 48 minutes
#alter table linktable add key `id2_vis` (`id2`,`visibility`), add key `id1_type`(`id1`,`link_type`,`visibility`,`time`,`version`,`data`);

# Check size of ibd file (total should be close to 20G approx)
#du -cb data/mysql/linkdb | tail -n 1
#du -cb data/*.tokudb | tail -n 1

