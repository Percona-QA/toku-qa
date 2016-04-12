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
LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
LOG_NAME_GLOBAL_STATUS=${LOG_NAME}.global_status
LOG_NAME_SYSINFO=${LOG_NAME}.sysinfo
LOG_NAME_IOSTAT=${LOG_NAME}.iostat
LOG_NAME_DSTAT=${LOG_NAME}.dstat
LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv
LOG_NAME_WRITE_CAPTURE=${LOG_NAME}.writecap
LOG_NAME_PMPROF=${LOG_NAME}.pmprof

rm -f $LOG_NAME

# ---------------------------------------------------------------------------
# create the database, start it, update global defaults
# ---------------------------------------------------------------------------

if [ ${SKIP_DB_CREATE} == "N" ]; then
    # ---------------------------------------------------------------------------
    # stop mysql if it is currently running (in case someone was sloppy)
    # ---------------------------------------------------------------------------
    
    if [ -e "${DB_DIR}/bin/mysqladmin" ]; then
       ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} shutdown >/dev/null 2>&1
       ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${DB_DIR}/node2/pxc-mysql.sock shutdown >/dev/null 2>&1
       ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${DB_DIR}/node3/pxc-mysql.sock shutdown >/dev/null 2>&1
    fi

    echo "Creating database from ${TARBALL} in ${DB_DIR}"
    MYSQL_OPTS="--innodb_buffer_pool_size=${INNODB_CACHE} --innodb_flush_method=${INNODB_FLUSH_METHOD}"
    BIN=`find ${DB_DIR} -maxdepth 2 -name mysqld -type f -o -name mysqld-debug -type f | head -1`;if [ -z $BIN ]; then echo "Assert! mysqld binary '$BIN' could not be read";exit 1;fi
    ## Starting mysqld
    MYEXTRA="${MYEXTRA} ${MYSQL_OPTS}"
    ${SCRIPT_DIR}/pxc-startup.sh startup
    #$BIN --no-defaults ${MYEXTRA} --basedir=${DB_DIR} --datadir=${DB_DIR}/data ${MYSQL_OPTS}  --port=${MYSQL_PORT} --pid-file=${DB_DIR}/data/pid.pid --core-file --socket=${MYSQL_SOCKET} --log-error=${DB_DIR}/data/error.log.out >  ${DB_DIR}/data/mysqld.out 2>&1 &

fi
# ---------------------------------------------------------------------------
# verbose logging?
# ---------------------------------------------------------------------------

if [ ${BENCHMARK_LOGGING} == "Y" ]; then
    # verbose logging
    echo "*** verbose benchmark logging enabled ***"

    capture-engine-status.bash $LOG_SECONDS $SHOW_ENGINE_STATUS_INTERVAL ${MYSQL_USER} ${MYSQL_SOCKET} $LOG_NAME_ENGINE_STATUS ${MYSQL_STORAGE_ENGINE} &
    #capture-global-status.bash $LOG_SECONDS $SHOW_GLOBAL_STATUS_INTERVAL ${MYSQL_USER} ${MYSQL_SOCKET} $LOG_NAME_GLOBAL_STATUS &
    capture-memory.bash ${LOG_SECONDS} ${SHOW_SYSINFO_INTERVAL} ${LOG_NAME_SYSINFO} mysqld &
    
    iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
    dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &
    mysql-show-what $WRITE_CAPTURE_INTERVAL $WRITE_CAPTURE_ROUNDS Handler_write > $LOG_NAME_WRITE_CAPTURE &
fi

if [ ${PMPROF_ENABLED} == "Y" ]; then
    # pmprof parameters = <num-seconds> <seconds-between-samples> <number-of-iterations> <process-name> <output-file-name> <seconds-delay-before-start>
    if [ -z "$PMPROF_TOTAL_SECONDS" ]; then
        export PMPROF_TOTAL_SECONDS=600
    fi
    if [ -z "$PMPROF_PAUSE_SECONDS" ]; then
        export PMPROF_PAUSE_SECONDS=5
    fi
    if [ -z "$PMPROF_ITERATIONS" ]; then
        export PMPROF_ITERATIONS=1
    fi
    if [ -z "$PMPROF_PROCESS_NAME" ]; then
        export PMPROF_PROCESS_NAME=mysqld
    fi
    if [ -z "$PMPROF_DELAY_SECONDS" ]; then
        export PMPROF_DELAY_SECONDS=300
    fi

    pmprof.bash ${PMPROF_TOTAL_SECONDS} ${PMPROF_PAUSE_SECONDS} ${PMPROF_ITERATIONS} ${PMPROF_PROCESS_NAME} ${LOG_NAME_PMPROF} ${PMPROF_DELAY_SECONDS} &
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
    # only do the these measurements if we are shutting down
    if [ ${SINGLE_FLUSH} == "N" ]; then
        for loop_num in $(eval echo "{1..$END_ITERATION_NUMBER}"); do
            echo "" | tee -a $LOG_NAME
            echo "" | tee -a $LOG_NAME
            echo "" | tee -a $LOG_NAME
            echo "----------------------------------------------------------" | tee -a $LOG_NAME
            echo "Post Benchmark Delay : Loop Number ${loop_num}" | tee -a $LOG_NAME
            echo "----------------------------------------------------------" | tee -a $LOG_NAME
            echo "" | tee -a $LOG_NAME
            echo "-------------------------------" | tee -a $LOG_NAME
            echo "Sizing Information" | tee -a $LOG_NAME
            echo "-------------------------------" | tee -a $LOG_NAME
            
            currentDate=`date`
            
            if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
                INNODB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/node1/${MYSQL_DATABASE} | tail -n 1 | cut -f1`
                INNODB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/node1/${MYSQL_DATABASE} | tail -n 1 | cut -f1`
                INNODB_SIZE_MB=`echo "scale=2; ${INNODB_SIZE_BYTES}/(1024*1024)" | bc `
                INNODB_SIZE_APPARENT_MB=`echo "scale=2; ${INNODB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
                echo "${currentDate} | post-benchmark InnoDB sizing (SizeMB / ASizeMB) = ${INNODB_SIZE_MB} / ${INNODB_SIZE_APPARENT_MB}" | tee -a $LOG_NAME
            elif [ ${MYSQL_STORAGE_ENGINE} == "deepdb" ]; then
                # nothing here yet
                tmpDeepVar=1
            elif [ ${MYSQL_STORAGE_ENGINE} == "wiredtiger" ]; then
                WIREDTIGER_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.wt ${DB_DIR}/node1/*.lsm ${DB_DIR}/node1/*.bf ${DB_DIR}/node1/WiredTiger* | tail -n 1 | cut -f1`
                WIREDTIGER_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/node1/*.wt ${DB_DIR}/node1/*.lsm ${DB_DIR}/node1/*.bf ${DB_DIR}/node1/WiredTiger* | tail -n 1 | cut -f1`
                WIREDTIGER_SIZE_MB=`echo "scale=2; ${WIREDTIGER_SIZE_BYTES}/(1024*1024)" | bc `
                WIREDTIGER_SIZE_APPARENT_MB=`echo "scale=2; ${WIREDTIGER_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
                echo "${currentDate} | post-benchmark WiredTiger sizing (SizeMB / ASizeMB) = ${WIREDTIGER_SIZE_MB} / ${WIREDTIGER_SIZE_APPARENT_MB}" | tee -a $LOG_NAME
            else
                TOKUDB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/node1/*.tokudb | tail -n 1 | cut -f1`
                TOKUDB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/node1/*.tokudb | tail -n 1 | cut -f1`
                TOKUDB_SIZE_MB=`echo "scale=2; ${TOKUDB_SIZE_BYTES}/(1024*1024)" | bc `
                TOKUDB_SIZE_APPARENT_MB=`echo "scale=2; ${TOKUDB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
                echo "${currentDate} | post-benchmark TokuDB sizing (SizeMB / ASizeMB) = ${TOKUDB_SIZE_MB} / ${TOKUDB_SIZE_APPARENT_MB}" | tee -a $LOG_NAME
                mysql-show-frag ${MYSQL_USER} ${MYSQL_SOCKET} | tee -a $LOG_NAME
            fi
            
            echo "`date` | sleeping for ${END_ITERATION_SLEEP_SECONDS} seconds" | tee -a $LOG_NAME
            sleep ${END_ITERATION_SLEEP_SECONDS}
        done
    fi
fi


if [ ${SHUTDOWN_MYSQL} == "Y" ]; then
    # only do the these measurements if we are shutting down
    T="$(date +%s)"
    echo "`date` | flushing logs and tables" | tee -a ${LOG_NAME}
    $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} -e "flush logs; flush tables;" | tee -a ${LOG_NAME}
    T="$(($(date +%s)-T))"
    printf "`date` | flush logs and tables duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a ${LOG_NAME}
fi

echo "" | tee -a $LOG_NAME
echo "" | tee -a $LOG_NAME
echo "" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
echo "Final Sizing Information" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME

currentDate=`date`

if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    INNODB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/node1/${MYSQL_DATABASE} | tail -n 1 | cut -f1`
    INNODB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/node1/${MYSQL_DATABASE} | tail -n 1 | cut -f1`
    INNODB_SIZE_MB=`echo "scale=2; ${INNODB_SIZE_BYTES}/(1024*1024)" | bc `
    INNODB_SIZE_APPARENT_MB=`echo "scale=2; ${INNODB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
    echo "${currentDate} | post-benchmark InnoDB sizing (SizeMB / ASizeMB) = ${INNODB_SIZE_MB} / ${INNODB_SIZE_APPARENT_MB}" | tee -a $LOG_NAME
elif [ ${MYSQL_STORAGE_ENGINE} == "deepdb" ]; then
    # nothing here yet
    tmpDeepVar=1
elif [ ${MYSQL_STORAGE_ENGINE} == "wiredtiger" ]; then
    WIREDTIGER_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.wt ${DB_DIR}/data/*.lsm ${DB_DIR}/data/*.bf ${DB_DIR}/data/WiredTiger* | tail -n 1 | cut -f1`
    WIREDTIGER_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/*.wt ${DB_DIR}/data/*.lsm ${DB_DIR}/data/*.bf ${DB_DIR}/data/WiredTiger* | tail -n 1 | cut -f1`
    WIREDTIGER_SIZE_MB=`echo "scale=2; ${WIREDTIGER_SIZE_BYTES}/(1024*1024)" | bc `
    WIREDTIGER_SIZE_APPARENT_MB=`echo "scale=2; ${WIREDTIGER_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
    echo "${currentDate} | post-benchmark WiredTiger sizing (SizeMB / ASizeMB) = ${WIREDTIGER_SIZE_MB} / ${WIREDTIGER_SIZE_APPARENT_MB}" | tee -a $LOG_NAME
else
    TOKUDB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
    TOKUDB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
    TOKUDB_SIZE_MB=`echo "scale=2; ${TOKUDB_SIZE_BYTES}/(1024*1024)" | bc `
    TOKUDB_SIZE_APPARENT_MB=`echo "scale=2; ${TOKUDB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
    echo "${currentDate} | post-benchmark TokuDB sizing (SizeMB / ASizeMB) = ${TOKUDB_SIZE_MB} / ${TOKUDB_SIZE_APPARENT_MB}" | tee -a $LOG_NAME
    mysql-show-frag ${MYSQL_USER} ${MYSQL_SOCKET} | tee -a $LOG_NAME
fi


if [ ${SHUTDOWN_MYSQL} == "Y" ]; then
    # ---------------------------------------------------------------------------
    # stop mysql (leave things as you found them)
    # ---------------------------------------------------------------------------
    ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} shutdown  >/dev/null 2>&1
    ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${DB_DIR}/node2/pxc-mysql.sock shutdown >/dev/null 2>&1
    ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${DB_DIR}/node3/pxc-mysql.sock shutdown >/dev/null 2>&1

fi

sleep 15

bkill

parse_iibench.pl summary . > ${MACHINE_NAME}.summary

#result_set=($(grep '^[0-9][0-9]' ${LOG_NAME} | awk '{print $6","}'))
#avg_result=($(cat ${MACHINE_NAME}.summary | awk '{print $3}'))
#echo "[ '${BUILD_NUMBER}', ${result_set[*]} $avg_result ]," >> ${WORKSPACE_LOC}/perf_result_set.txt

#cat ${SCRIPT_DIR}/../../graph_template/combo_chart_header.html >  ${WORKSPACE_LOC}/perf_result.html
#echo "['Build', '20M' , '40M' , '60M ' , '80M' , '100M' , 'avg_ips']," >> ${WORKSPACE_LOC}/perf_result.html
#tail -20 ${WORKSPACE_LOC}/perf_result_set.txt >> ${WORKSPACE}/perf_result.html
#cat ${SCRIPT_DIR}/../../graph_template/combo_chart_footer.html >> ${WORKSPACE_LOC}/perf_result.html

DATE=`date +"%Y%m%d%H%M%S"`
tarFileName="iibench_${BENCH_ID}_perf_result_set_${DATE}.tar.gz"
tar czvf ${tarFileName} ${MACHINE_NAME}* ${DB_DIR}/node1/*.err
cp ${tarFileName} ${SCP_TARGET}
cp ${MACHINE_NAME}.summary ${WORKSPACE_LOC}/iibench_${BENCH_ID}_perf_result_set_${DATE}_summ.txt
cp ${LOG_NAME} ${WORKSPACE_LOC}/iibench_${BENCH_ID}_perf_result_set_${DATE}.txt
if [ ! -z ${IIBENCH_MODE} ];then
  result_set=($(grep '^[0-9][0-9]' ${LOG_NAME} |  awk '{print $8"," }' | head -5))
  for i in {0..4}; do if [ -z ${result_set[i]} ]; then  result_set[i]='0,' ; fi; done
  avg_result=($(cat ${MACHINE_NAME}.summary | awk '{print $7}'))
else
  result_set=($(grep '^[0-9][0-9]' ${LOG_NAME} |  awk '{print $6"," }' | head -5))
  for i in {0..4}; do if [ -z ${result_set[i]} ]; then  result_set[i]='0,' ; fi; done
  avg_result=($(cat ${MACHINE_NAME}.summary | awk '{print $3}'))
fi
echo "[ '${BUILD_NUMBER}', ${result_set[*]} $avg_result ]," >> ${WORKSPACE_LOC}/iibench_${BENCH_ID}_perf_result_set.txt
 
rm -f ${MACHINE_NAME}*

