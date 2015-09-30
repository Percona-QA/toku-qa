#!/bin/bash

export NUM_ROWS=1000000
export NUM_TABLES=8
export SYSBENCH_VERSION='sysbench-0.4.8'
#export SYSBENCH_VERSION='sysbench-0.4.13'
export RUN_TIME_SECONDS=120
export threadCountList="0001 0002 0004 0008 0016 0032 0064 0128"

export TARBALL=blank-toku703-mysql-5.5.30
export BENCH_ID=toku.703
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.30
export MYSQL_STORAGE_ENGINE=tokudb
./doit.bash

export TARBALL=blank-mysql-5.5.34.dimitri
export BENCH_ID=mysql.5.5.34
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.34
export MYSQL_STORAGE_ENGINE=innodb
./doit.bash

export TARBALL=blank-mysql-5.6.14.dimitri
export BENCH_ID=mysql.5.6.14
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.6.14
export MYSQL_STORAGE_ENGINE=innodb
./doit.bash

export TARBALL=blank-mysql-5.7.2.m12.dimitri
export BENCH_ID=mysql.5.7.2.m12
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.7.2.m12
export MYSQL_STORAGE_ENGINE=innodb
./doit.bash

