#!/bin/bash

if [ -z "$RUN_TIME_SECONDS" ]; then
    echo "Need to set RUN_TIME_SECONDS"
    exit 1
fi
if [ -z "$BENCHMARK_LOGGING" ]; then
    echo "Need to set BENCHMARK_LOGGING"
    exit 1
fi
if [ -z "$NUM_ROWS" ]; then
    echo "Need to set NUM_ROWS"
    exit 1
fi
if [ -z "$RAND_TYPE" ]; then
    echo "Need to set RAND_TYPE"
    exit 1
fi
if [ -z "$MYSQL_SOCKET" ]; then
    echo "Need to set MYSQL_SOCKET"
    exit 1
fi
if [ -z "$MYSQL_DATABASE" ]; then
    echo "Need to set MYSQL_DATABASE"
    exit 1
fi
if [ -z "$MYSQL_USER" ]; then
    echo "Need to set MYSQL_USER"
    exit 1
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    echo "Need to set MYSQL_STORAGE_ENGINE"
    exit 1
fi
if [ -z "$MACHINE_NAME" ]; then
    echo "Need to set MACHINE_NAME"
    exit 1
fi
if [ -z "$MYSQL_NAME" ]; then
    echo "Need to set MYSQL_NAME"
    exit 1
fi
if [ -z "$MYSQL_VERSION" ]; then
    echo "Need to set MYSQL_VERSION"
    exit 1
fi
if [ -z "$BENCH_ID" ]; then
    echo "Need to set BENCH_ID"
    exit 1
fi
if [ -z "$NUM_TABLES" ]; then
    echo "Need to set NUM_TABLES"
    exit 1
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    echo "Need to set BENCHMARK_NUMBER"
    exit 1
fi

if [ -z "$SCP_FILES" ]; then
    export SCP_FILES=Y
fi
if [ -z "$RUN_HOT_BACKUPS" ]; then
    export RUN_HOT_BACKUPS=N
fi
if [ -z "$RUN_HOT_BACKUPS_START_SECONDS" ]; then
    export RUN_HOT_BACKUPS_START_SECONDS=20
fi
if [ -z "$RUN_HOT_BACKUPS_MBPS" ]; then
    export RUN_HOT_BACKUPS_MBPS=50
fi
if [ -z "$SYSBENCH_NON_INDEX_UPDATES_PER_TXN" ]; then
    export SYSBENCH_NON_INDEX_UPDATES_PER_TXN=1
fi
if [ -z "$READONLY" ]; then
    export READONLY=off
fi

REPORT_INTERVAL=10
LUA_DIR=${PWD}/lua

LOG_BENCHMARK_NAME=sysbench.oltp.${RAND_TYPE}.${NUM_TABLES}
COMMIT_SYNC=1

TABLE_NUM=1
while [ ${TABLE_NUM} -le ${NUM_TABLES} ]; do
    thisTable=sbtest${TABLE_NUM}
    echo "`date` | adding column c1 to table ${thisTable}" | tee -a $LOG_NAME
    $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "alter table ${thisTable} add column c1 bigint default 0 not null;"
    let TABLE_NUM=TABLE_NUM+1
done

#echo "compiling custom sysbench"
#pushd ../sysbench-0.5
#./autogen.sh
#./configure
#make
#popd

if [ -z "$threadCountList" ]; then
    export threadCountList="0001 0002 0004 0008 0016 0032 0064 0128 0256 0512 1024"
fi

if [ ${RUN_HOT_BACKUPS} == "Y" ]; then
    if [ -z "$HOT_BACKUP_DIR" ]; then
        echo "Need to set HOT_BACKUP_DIR"
        exit 1
    fi

    echo "*** Continuous hot backups enabled, starting in ${RUN_HOT_BACKUPS_START_SECONDS} second(s)..."

    LOG_NAME_SQL=${MACHINE_NAME}-${MYSQL_NAME}-${MYSQL_VERSION}-${MYSQL_STORAGE_ENGINE}-${BENCH_ID}-$LOG_BENCHMARK_NAME-$NUM_ROWS-$COMMIT_SYNC-DEFAULTS.txt.backup
    mysql-run-backup-continuous ${RUN_HOT_BACKUPS_MBPS} ${RUN_HOT_BACKUPS_START_SECONDS} > ${LOG_NAME_SQL} &
else
    echo "*** Continuous hot backups disabled, YOU SHOULD NEVER GET HERE!"
fi

# run for real
for num_threads in ${threadCountList}; do
    LOG_NAME=${MACHINE_NAME}-${MYSQL_NAME}-${MYSQL_VERSION}-${MYSQL_STORAGE_ENGINE}-${BENCH_ID}-$LOG_BENCHMARK_NAME-$NUM_ROWS-$num_threads-$COMMIT_SYNC-DEFAULTS.txt

    sysbench --test=${LUA_DIR}/tokudb_oltp_valid.lua --oltp-non-index-updates=$SYSBENCH_NON_INDEX_UPDATES_PER_TXN --oltp_tables_count=$NUM_TABLES --oltp-table-size=$NUM_ROWS --rand-init=on --num-threads=$num_threads --oltp-read-only=$READONLY --report-interval=$REPORT_INTERVAL --rand-type=$RAND_TYPE --mysql-socket=$MYSQL_SOCKET --mysql-table-engine=${MYSQL_STORAGE_ENGINE} --max-time=$RUN_TIME_SECONDS --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWORD --mysql-db=${MYSQL_DATABASE} --max-requests=0 --percentile=99 run | tee $LOG_NAME

    sleep 5
done

bkill

# kill the continuous hot backup runner
pkill -9 -f 'mysql-run-backup-continuous'

