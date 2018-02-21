#!/bin/bash
echo "$DB_DIR ........"

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi
if [ -z "$MACHINE_NAME" ]; then
    echo "Need to set MACHINE_NAME"
    exit 1
fi
if [ -z "$MYSQL_SOCKET" ]; then
    echo "Need to set MYSQL_SOCKET"
    exit 1
fi
if [ -z "$MYSQL_PORT" ]; then
    echo "Need to set MYSQL_PORT"
    exit 1
fi
if [ -z "$SCP_TARGET" ]; then
    echo "Need to set SCP_TARGET"
    exit 1
fi
if [ -z "$MYSQL_NAME" ]; then
    export MYSQL_NAME=mysql
fi
if [ -z "$MYSQL_VERSION" ]; then
    export MYSQL_VERSION=5.5.28
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    export MYSQL_STORAGE_ENGINE=innodb
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    export BENCHMARK_NUMBER=001
fi

if [ -z "$RUN_ARBITRARY_SQL" ]; then
    export RUN_ARBITRARY_SQL=N
fi

if [ -z "$NUM_SECONDARY_INDEXES" ]; then
    export NUM_SECONDARY_INDEXES=3
fi

if [ -z "$DIRECTIO" ]; then
    export DIRECTIO=N
fi
if [ -z "$SINGLE_FLUSH" ]; then
    export SINGLE_FLUSH=Y
fi
if [ -z "$END_ITERATION_NUMBER" ]; then
    export END_ITERATION_NUMBER=96
fi
if [ -z "$END_ITERATION_SLEEP_SECONDS" ]; then
    export END_ITERATION_SLEEP_SECONDS=300
fi
if [ -z "$PMPROF_ENABLED" ]; then
    export PMPROF_ENABLED=N
fi
if [ -z "$SKIP_DB_CREATE" ]; then
    export SKIP_DB_CREATE=N
fi
if [ -z "$SHUTDOWN_MYSQL" ]; then
    export SHUTDOWN_MYSQL=Y
fi
if [ -z "$IIBENCH_CREATE_TABLE" ]; then
    export IIBENCH_CREATE_TABLE=Y
fi


if [ -z "$INNODB_CACHE" ]; then
  echo "Need to set INNODB_CACHE"
  exit 1
fi
export INNODB_COMPRESSION=N
export INNODB_KEY_BLOCK_SIZE=8
export INNODB_BUFFER_POOL_SIZE=${INNODB_CACHE}
# O_DIRECT, O_DSYNC, **default is special case and not yet supported by this script**
export INNODB_FLUSH_METHOD=O_DIRECT
if [ -z "$TARBALL" ]; then
  export TARBALL=blank-mysql5529
fi
if [ ${INNODB_COMPRESSION} == "Y" ]; then
  if [ -z "$BENCH_ID" ]; then
    export BENCH_ID=118.compressed.${INNODB_KEY_BLOCK_SIZE}
  fi
  IIBENCH_EXTRA_ARGS="--innodb_compression --innodb_key_block_size=${INNODB_KEY_BLOCK_SIZE}"
else
  if [ -z "$BENCH_ID" ]; then
    export BENCH_ID=118
  fi
fi

export MYSQL_USER=root
export MYSQL_DATABASE=test
export BENCHMARK_LOGGING=Y

export MAX_IPS=-1

if [ -z "$MAX_ROWS" ]; then
    export MAX_ROWS=1000000
fi
if [ -z "$MAX_TABLE_ROWS" ]; then
    export MAX_TABLE_ROWS=${MAX_ROWS}
fi

# only spawn additional writers if environment variables says so
if [ -z "$ADDITIONAL_WRITERS" ]; then
    export ADDITIONAL_WRITERS=0
fi

# reduce MAX_ROWS and MAX_TABLE_ROWS if we are using > 1 writer
if [ ${ADDITIONAL_WRITERS} -gt 0 ]; then
    let TOTAL_WRITERS=ADDITIONAL_WRITERS+1
    let MAX_ROWS=MAX_ROWS/TOTAL_WRITERS
    MAX_TABLE_ROWS=${MAX_ROWS}
fi

if [ -z "$ROWS_PER_REPORT" ]; then
    export ROWS_PER_REPORT=100000
fi
if [ -z "$RUN_MINUTES" ]; then
    export RUN_MINUTES=20
fi

export RUN_SECONDS=$[RUN_MINUTES*60]

POST_BENCHMARK_SECONDS=900
if [ ${SINGLE_FLUSH} == "N" ]; then
    POST_BENCHMARK_SECONDS=$[END_ITERATION_NUMBER*END_ITERATION_SLEEP_SECONDS]
fi
LOG_SECONDS=$[RUN_SECONDS+POST_BENCHMARK_SECONDS]

export SHOW_ENGINE_STATUS_INTERVAL=60
export SHOW_GLOBAL_STATUS_INTERVAL=10
export SHOW_SYSINFO_INTERVAL=10
export IOSTAT_INTERVAL=10
export IOSTAT_ROUNDS=$[LOG_SECONDS/IOSTAT_INTERVAL+1]
export DSTAT_INTERVAL=10
export DSTAT_ROUNDS=$[LOG_SECONDS/DSTAT_INTERVAL+1]
export WRITE_CAPTURE_INTERVAL=10
export WRITE_CAPTURE_ROUNDS=$[LOG_SECONDS/WRITE_CAPTURE_INTERVAL-1]

export COMMIT_SYNC=0
if [ -z "$UNIQUE_CHECKS" ]; then
    export UNIQUE_CHECKS=1
fi

if [ -z "$INSERT_ONLY" ]; then
    export INSERT_ONLY=1
fi
if [ ${INSERT_ONLY} -eq 1 ]; then
    BENCHMARK_NAME=iibench
    IIBENCH_QUERY_PARM="--insert_only"
else
    BENCHMARK_NAME=iibench.queries
    IIBENCH_QUERY_PARM=""
fi

LOG_NAME=${MACHINE_NAME}-${MYSQL_NAME}-${MYSQL_VERSION}-${MYSQL_STORAGE_ENGINE}-${BENCH_ID}-${BENCHMARK_NAME}-$COMMIT_SYNC-UNIQUE_CHECKS=${UNIQUE_CHECKS}.txt

rm -f $LOG_NAME

# ---------------------------------------------------------------------------
# create the database, start it, update global defaults
# ---------------------------------------------------------------------------

if [ ${SKIP_DB_CREATE} == "N" ]; then
    # ---------------------------------------------------------------------------
    # stop mysql if it is currently running (in case someone was sloppy)
    # ---------------------------------------------------------------------------
    
    if [ -e "${DB_DIR}/bin/mysqladmin" ]; then
       ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${DB_DIR}/node1/pxc-mysql.sock shutdown >/dev/null 2>&1
       ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${DB_DIR}/node2/pxc-mysql.sock shutdown >/dev/null 2>&1
       ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${DB_DIR}/node3/pxc-mysql.sock shutdown >/dev/null 2>&1
       ps -ef | grep 'pxc-mysql.sock' | grep ${BUILD_NUMBER} | grep -v grep | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1 || true
    fi

    echo "Creating database from ${TARBALL} in ${DB_DIR}"
    MYSQL_OPTS="--innodb_buffer_pool_size=${INNODB_CACHE}"
    BIN=`find ${DB_DIR} -maxdepth 2 -name mysqld -type f -o -name mysqld-debug -type f | head -1`;if [ -z $BIN ]; then echo "Assert! mysqld binary '$BIN' could not be read";exit 1;fi
    ## Starting mysqld
    export MYEXTRA="${MYEXTRA} ${MYSQL_OPTS}"
    ${SCRIPT_DIR}/pxc-startup.sh startup
    #$BIN --no-defaults ${MYEXTRA} --basedir=${DB_DIR} --datadir=${DB_DIR}/data ${MYSQL_OPTS}  --port=${MYSQL_PORT} --pid-file=${DB_DIR}/data/pid.pid --core-file --socket=${MYSQL_SOCKET} --log-error=${DB_DIR}/data/error.log.out >  ${DB_DIR}/data/mysqld.out 2>&1 &

fi


if [ ${RUN_ARBITRARY_SQL} == "Y" ]; then
    LOG_NAME_SQL=${MACHINE_NAME}.txt.arbitrary-sql
    if [ -z "$arbitrarySqlWaitSeconds" ]; then
        export arbitrarySqlWaitSeconds=300
    fi
    mysql-run-arbitrary-sql ${arbitrarySqlWaitSeconds} "create index idx_hot_test on purchases_index (productid,customerid,cashregisterid);" ${LOG_NAME_SQL} &
fi


# ---------------------------------------------------------------------------
# run the benchmark
# ---------------------------------------------------------------------------

# Get time as a UNIX timestamp (seconds elapsed since Jan 1, 1970 0:00 UTC)
T="$(date +%s)"


# additional iibench inserters
  # param 1 = number of seconds to sleep before starting
  # param 2 = number of additional iibench clients to run
if [ ${ADDITIONAL_WRITERS} -gt 0 ]; then
    ./run.benchmark.concurrent.sh 10 ${ADDITIONAL_WRITERS} &
fi

# insert only, create the table
#   remove --insert_only to do reads and inserts
CREATE_TABLE_STRING=""
if [ ${IIBENCH_CREATE_TABLE} == "Y" ]; then
    CREATE_TABLE_STRING="--setup"
fi

python iibench.py ${CREATE_TABLE_STRING} --db_socket=${MYSQL_SOCKET} --db_name=${MYSQL_DATABASE} --max_rows=${MAX_ROWS} --max_table_rows=${MAX_TABLE_ROWS} --rows_per_report=${ROWS_PER_REPORT} --engine=${MYSQL_STORAGE_ENGINE} ${IIBENCH_QUERY_PARM} --unique_checks=${UNIQUE_CHECKS} --run_minutes=${RUN_MINUTES} --tokudb_commit_sync=${COMMIT_SYNC} --max_ips=${MAX_IPS} --num_secondary_indexes=${NUM_SECONDARY_INDEXES} ${IIBENCH_EXTRA_ARGS} | tee ${LOG_NAME}


if [ ${SHUTDOWN_MYSQL} == "Y" ]; then
    # ---------------------------------------------------------------------------
    # stop mysql (leave things as you found them)
    # ---------------------------------------------------------------------------
    ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${DB_DIR}/node1/pxc-mysql.sock shutdown >/dev/null 2>&1
    ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${DB_DIR}/node2/pxc-mysql.sock shutdown >/dev/null 2>&1
    ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${DB_DIR}/node3/pxc-mysql.sock shutdown >/dev/null 2>&1
    ps -ef | grep 'pxc-mysql.sock' | grep ${BUILD_NUMBER} | grep -v grep | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1 || true
    sleep 2;sync
fi

sleep 15

DATE=`date +"%Y%m%d%H%M%S"`
tarFileName="iibench_${BENCH_ID}_perf_result_set_${DATE}.tar.gz"
tar czvf ${tarFileName} ${MACHINE_NAME}* ${DB_DIR}/data/*.err
cp ${tarFileName} ${SCP_TARGET}
if [ ! -z ${IIBENCH_MODE} ];then
  result_set=($(grep '^[0-9][0-9]' ${LOG_NAME} |  awk '{print $8"," }' | head -5))
  for i in {0..4}; do if [ -z ${result_set[i]} ]; then  result_set[i]='0,' ; fi; done
else
  result_set=($(grep '^[0-9][0-9]' ${LOG_NAME} |  awk '{print $6"," }' | head -5))
  for i in {0..4}; do if [ -z ${result_set[i]} ]; then  result_set[i]='0,' ; fi; done
fi
echo "[ '${BUILD_NUMBER}', ${result_set[*]} $avg_result ]," >> ${WORKSPACE_LOC}/iibench_${BENCH_ID}_perf_result_set.txt
 
rm -f ${MACHINE_NAME}* ${tarFileName}

