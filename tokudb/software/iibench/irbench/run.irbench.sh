#!/bin/bash

MAX_ROWS=100000000
NUM_REPLACERS=1
ROWS_PER_REPORT=100000
RUN_MINUTES=180
RUN_SECONDS=$[RUN_MINUTES*60]
SHOW_ENGINE_STATUS_INTERVAL=60
SHOW_SYSINFO_INTERVAL=60
IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[RUN_SECONDS/IOSTAT_INTERVAL+1]
DSTAT_INTERVAL=10
DSTAT_ROUNDS=$[RUN_SECONDS/DSTAT_INTERVAL+1]

#GRAB PARAMETERS LIKE "PARM1=$1"

### CHECK/SET FOR YOUR BENCHMARK ###
### DIR NAMES = drno-<build>-blank, toku505-both-blank, toku513-both-blank

IIBENCH_DIR=/home/tcallaghan/mystuff/personal/tokutek/software/irbench

VERSION_DIR=
LOG_SERVER_TYPE=mm
LOG_DB_NAME=mysql
LOG_DB_VERSION=5.1.52
LOG_ENGINE_NAME=tokudb
LOG_ENGINE_VERSION=527.38674
LOG_BENCHMARK_NAME=irbench
COMMIT_SYNC=0
UNIQUE_CHECKS=1
MYSQL_SOCKET=/tmp/mysql.sock
MYSQL_USER=root

### CHECK/SET FOR YOUR BENCHMARK ###
MYSQL_CONFIG_FILE=my.cnf
PATH_FROM=$BACKUP_DIR/$VERSION_DIR
PATH_TO=$DB_DIR

LOG_NAME=$LOG_SERVER_TYPE-$LOG_DB_NAME-$LOG_DB_VERSION-$LOG_ENGINE_NAME-$LOG_ENGINE_VERSION-$LOG_BENCHMARK_NAME-$COMMIT_SYNC-$MAX_ROWS-$NUM_REPLACERS-UNIQUE_CHECKS=${UNIQUE_CHECKS}.PREFETCH=ON.READBUF=20K.txt
LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
LOG_NAME_SYSINFO=${LOG_NAME}.sysinfo
LOG_NAME_IOSTAT=${LOG_NAME}.iostat
LOG_NAME_DSTAT=${LOG_NAME}.dstat
LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv

rm -f $LOG_NAME

# ---------------------------------------------------------------------------
# stop mysql if it is currently running (in case someone was sloppy)
# ---------------------------------------------------------------------------

#mysqladmin --user=root --socket=/tmp/mysql.sock shutdown
#sleep 5

# ---------------------------------------------------------------------------
# create the database
# ---------------------------------------------------------------------------

#before="$(date +%s)"
#rm -rf $PATH_TO
#mkdir $PATH_TO
#cp -r $PATH_FROM/* $PATH_TO
#after="$(date +%s)"
#elapsed_seconds="$(expr $after - $before)"
#echo Elapsed seconds: $elapsed_seconds

# ---------------------------------------------------------------------------
# start the database with the preferred configuration file
# ---------------------------------------------------------------------------

#pushd .
#cd $PATH_TO
#mysql-start $MYSQL_CONFIG_FILE &
#popd

# ---------------------------------------------------------------------------
# wait for mysql to start
# ---------------------------------------------------------------------------

#echo "waiting for mysql to start..."
#while ! [ -S "/tmp/mysql.sock" ]; do
#    sleep 5
#done

# ---------------------------------------------------------------------------
# run the benchmark
# ---------------------------------------------------------------------------



capture-engine-status.bash $RUN_SECONDS $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS $LOG_ENGINE_NAME &
capture-sysinfo.bash $RUN_SECONDS $SHOW_SYSINFO_INTERVAL $LOG_NAME_SYSINFO &
iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &

# replace into only (no queries)
#python26 $IIBENCH_DIR/irbench.py --max_rows=$MAX_ROWS --rows_per_report=$ROWS_PER_REPORT --engine=$LOG_ENGINE_NAME --insert_only --unique_checks=$UNIQUE_CHECKS --run_minutes=$RUN_MINUTES --tokudb_commit_sync=$COMMIT_SYNC | tee $LOG_NAME

# replace into AND queries
python26 $IIBENCH_DIR/irbench.py --max_rows=$MAX_ROWS --rows_per_report=$ROWS_PER_REPORT --engine=$LOG_ENGINE_NAME --unique_checks=$UNIQUE_CHECKS --run_minutes=$RUN_MINUTES --tokudb_commit_sync=$COMMIT_SYNC | tee $LOG_NAME

# ---------------------------------------------------------------------------
# stop mysql (just being polite)
# ---------------------------------------------------------------------------

#mysqladmin --user=root --socket=/tmp/mysql.sock shutdown
