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
if [ -z "$SCP_TARGET" ]; then
    echo "Need to set SCP_TARGET"
    exit 1
fi

if [ -z "$WARMUP" ]; then
    export WARMUP=Y
fi
if [ -z "$SCP_FILES" ]; then
    export SCP_FILES=Y
fi
if [ -z "$RUN_ARBITRARY_SQL" ]; then
    export RUN_ARBITRARY_SQL=N
fi
if [ -z "$READONLY" ]; then
    export READONLY=off
fi


REPORT_INTERVAL=10
SHOW_EXTENDED_STATUS_INTERVAL=60
SHOW_ENGINE_STATUS_INTERVAL=60
SHOW_PROCESSLIST_INTERVAL=10
SHOW_MEMORY_INTERVAL=10
IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[RUN_TIME_SECONDS/IOSTAT_INTERVAL+1]
DSTAT_INTERVAL=10
DSTAT_ROUNDS=$[RUN_TIME_SECONDS/DSTAT_INTERVAL+1]
SYSBENCH_DIR=sysbench-0.5/sysbench

LOG_BENCHMARK_NAME=sysbench.oltp.${RAND_TYPE}.${NUM_TABLES}
COMMIT_SYNC=1


if [ ${WARMUP} == "Y" ]; then
    # warmup the cache, 64 threads for 10 minutes, don't bother logging
    # *** REMEMBER *** warmmup is READ ONLY!
    num_threads=64
    WARMUP_TIME_SECONDS=600
    if [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "0.5" ]; then
      sysbench --test=${SYSBENCH_DIR}/tests/db/oltp.lua --oltp_tables_count=$NUM_TABLES --oltp-table-size=$NUM_ROWS --rand-init=on --num-threads=$num_threads --oltp-read-only=on --report-interval=$REPORT_INTERVAL --rand-type=$RAND_TYPE --mysql-socket=$MYSQL_SOCKET --mysql-table-engine=${MYSQL_STORAGE_ENGINE} --max-time=$WARMUP_TIME_SECONDS --mysql-user=$MYSQL_USER  --db-driver=mysql --mysql-password=$MYSQL_PASSWORD --mysql-db=${MYSQL_DATABASE} --max-requests=0 --percentile=99 run
    elif [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "1.0" ]; then
      sysbench /usr/share/sysbench/oltp_read_only.lua --tables=$NUM_TABLES --table-size=$NUM_ROWS --threads=$num_threads --report-interval=$REPORT_INTERVAL --rand-type=$RAND_TYPE --mysql-socket=$MYSQL_SOCKET --mysql-storage-engine=${MYSQL_STORAGE_ENGINE} --time=$WARMUP_TIME_SECONDS --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWORD --mysql-db=${MYSQL_DATABASE}  --db-driver=mysql --events=0 --percentile=99 run
    fi
    sleep 60
fi


if [ -z "$threadCountList" ]; then
    export threadCountList="0001 0002"
# 0004 0008 0016 0032 0064 0128 0256 0512 1024"
fi

if [ ${RUN_ARBITRARY_SQL} == "Y" ]; then
    if [ -z "$arbitrarySqlWaitSeconds" ]; then
        export arbitrarySqlWaitSeconds=300
    fi
fi

# run for real
for num_threads in ${threadCountList}; do
    LOG_NAME=${MACHINE_NAME}-${MYSQL_NAME}-${MYSQL_VERSION}-${MYSQL_STORAGE_ENGINE}-${BENCH_ID}-$LOG_BENCHMARK_NAME-$NUM_ROWS-$num_threads-$COMMIT_SYNC-DEFAULTS.txt

    if [ ${MYSQL_STORAGE_ENGINE} == "myisam" ]; then
        # myisam version has special table lock command in oltp_myisam.lua and passes one additional parameter
      if [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "0.5" ]; then
        sysbench --test=${SYSBENCH_DIR}/tests/db/oltp_myisam.lua --oltp_tables_count=$NUM_TABLES --oltp-table-size=$NUM_ROWS --rand-init=on --num-threads=$num_threads --oltp-read-only=$READONLY --report-interval=$REPORT_INTERVAL --rand-type=$RAND_TYPE --mysql-socket=$MYSQL_SOCKET --mysql-table-engine=${MYSQL_STORAGE_ENGINE} --max-time=$RUN_TIME_SECONDS --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWORD --mysql-db=${MYSQL_DATABASE}  --db-driver=mysql --max-requests=0 --percentile=99 --myisam-max-rows=${NUM_ROWS} run | tee $LOG_NAME
      elif [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "1.0" ]; then
        sysbench /usr/share/sysbench/oltp_read_write.lua --tables=$NUM_TABLES --table-size=$NUM_ROWS --threads=$num_threads --report-interval=$REPORT_INTERVAL --rand-type=$RAND_TYPE --mysql-socket=$MYSQL_SOCKET --mysql-storage-engine=${MYSQL_STORAGE_ENGINE} --time=$RUN_TIME_SECONDS --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWORD --mysql-db=${MYSQL_DATABASE}  --db-driver=mysql --events=0 --percentile=99 run | tee $LOG_NAME
      fi
    else
      if [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "0.5" ]; then
        sysbench --test=${SYSBENCH_DIR}/tests/db/oltp.lua --oltp_tables_count=$NUM_TABLES --oltp-table-size=$NUM_ROWS --rand-init=on --num-threads=$num_threads --oltp-read-only=$READONLY --report-interval=$REPORT_INTERVAL --rand-type=$RAND_TYPE --mysql-socket=$MYSQL_SOCKET --mysql-table-engine=${MYSQL_STORAGE_ENGINE} --max-time=$RUN_TIME_SECONDS --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWORD --mysql-db=${MYSQL_DATABASE}  --db-driver=mysql --max-requests=0 --percentile=99 run | tee $LOG_NAME
      elif [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "1.0" ]; then
        sysbench /usr/share/sysbench/oltp_read_write.lua --tables=$NUM_TABLES --table-size=$NUM_ROWS --threads=$num_threads --report-interval=$REPORT_INTERVAL --rand-type=$RAND_TYPE --mysql-socket=$MYSQL_SOCKET --mysql-storage-engine=${MYSQL_STORAGE_ENGINE} --time=$RUN_TIME_SECONDS --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWORD --mysql-db=${MYSQL_DATABASE}  --db-driver=mysql --events=0 --percentile=99 run | tee $LOG_NAME
      fi 
    fi
    sleep 6
	result_set+=(`grep  "queries:" $LOG_NAME | cut -d'(' -f2 | awk '{print $1}'`)
done

DATE=`date +"%Y%m%d%H%M%S"`
tarFileName="sysbench_${BENCH_ID}_perf_result_set_${DATE}.tar.gz"
tar czvf ${tarFileName} ${MACHINE_NAME}* ${DB_DIR}/data/*.err
cp ${tarFileName} ${SCP_TARGET}

for i in {0..7}; do if [ -z ${result_set[i]} ]; then  result_set[i]=',0' ; fi; done
echo "[ '${BUILD_NUMBER}' ${result_set[*]} ]," >> ${WORKSPACE_LOC}/sysbench_${BENCH_ID}_perf_result_set.txt
rm -f ${MACHINE_NAME}* ${tarFileName}

