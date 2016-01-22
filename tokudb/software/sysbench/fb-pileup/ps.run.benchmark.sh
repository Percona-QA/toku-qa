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


if [ -z "$SCP_FILES" ]; then
    export SCP_FILES=Y
fi

REPORT_INTERVAL=10
SHOW_ENGINE_STATUS_INTERVAL=10
SHOW_MEMORY_INTERVAL=10
IOSTAT_INTERVAL=10
DSTAT_INTERVAL=10

# number of queries to perform per "transaction" (loop controller)
#   pass --oltp-point-selects=$POINT_SELECTS_PER_XACT to point and range test
POINT_SELECTS_PER_XACT=1

# size of range (number of potential rows per select)
#   pass --oltp-range-size=$RANGE_SIZE to range test
RANGE_SIZE=20000

# value of limit if range querying
#   pass --oltp-simple-ranges=$RANGE_LIMIT to range test
RANGE_LIMIT=1000

MYSQL_SOCKET=$MYSQL_SOCKET
MYSQL_USER=root
MYSQL_PASSWORD=""
SYSBENCH_DIR=../sysbench-0.5/sysbench
DBNAME=test

LOG_BENCHMARK_NAME=sysbench.fbpileup.${RAND_TYPE}.${NUM_TABLES}
COMMIT_SYNC=1

SLEEP_SECONDS=10

if [ -z "$threadCountList" ]; then
    export threadCountList="0001 0004 0016 0064 0128 0256 0512 1024"
fi

# point query test - PRIMARY KEY
for num_threads in ${threadCountList}; do
    IOSTAT_ROUNDS=$[RUN_TIME_SECONDS/IOSTAT_INTERVAL+1]
    DSTAT_ROUNDS=$[RUN_TIME_SECONDS/DSTAT_INTERVAL+1]
    LOG_NAME=$MACHINE_NAME-$MYSQL_NAME-$MYSQL_VERSION-$MYSQL_STORAGE_ENGINE-$BENCH_ID-${LOG_BENCHMARK_NAME}-$NUM_ROWS-$num_threads-$COMMIT_SYNC-DEFAULTS.POINT.PRIMARY.txt
    LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
    LOG_NAME_MEMORY=${LOG_NAME}.memory
    LOG_NAME_IOSTAT=${LOG_NAME}.iostat
    LOG_NAME_DSTAT=${LOG_NAME}.dstat
    LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv
    LOG_NAME_PMPROF=${LOG_NAME}.pmprof
    
    if [ ${BENCHMARK_LOGGING} == "Y" ]; then
        # verbose logging
        echo "*** verbose benchmark logging enabled ***"

        capture-tokustat.bash $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS &
        capture-memory.bash $RUN_TIME_SECONDS ${SHOW_MEMORY_INTERVAL} ${LOG_NAME_MEMORY} mysqld &
        iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
        dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &
        #pmprof.bash 200 2 1 mysqld ${LOG_NAME_PMPROF} 0 &
    fi

    sysbench --test=${SYSBENCH_DIR}/tests/db/tokudb_select_point_primary.lua --oltp_tables_count=$NUM_TABLES --oltp-table-size=$NUM_ROWS --rand-init=on --num-threads=$num_threads --report-interval=$REPORT_INTERVAL --rand-type=$RAND_TYPE --mysql-socket=$MYSQL_SOCKET --mysql-table-engine=$MYSQL_STORAGE_ENGINE --max-time=$RUN_TIME_SECONDS --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWORD --mysql-db=$DBNAME --max-requests=0 --oltp-point-selects=$POINT_SELECTS_PER_XACT --percentile=99 run | tee $LOG_NAME

    echo "BEGIN-SHOW-VARIABLES" >> $LOG_NAME
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show variables" >> $LOG_NAME
    echo "END-SHOW-VARIABLES" >> $LOG_NAME
    echo "BEGIN-SHOW-ENGINE-STATUS" >> $LOG_NAME
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show engine $MYSQL_STORAGE_ENGINE status" >> $LOG_NAME
    echo "END-SHOW-ENGINE-STATUS" >> $LOG_NAME
    
    sleep ${SLEEP_SECONDS}
    
    bkill
done


sleep ${SLEEP_SECONDS}


# range/limit query test - PRIMARY KEY
for num_threads in ${threadCountList}; do
    IOSTAT_ROUNDS=$[RUN_TIME_SECONDS/IOSTAT_INTERVAL+1]
    DSTAT_ROUNDS=$[RUN_TIME_SECONDS/DSTAT_INTERVAL+1]
    LOG_NAME=$MACHINE_NAME-$MYSQL_NAME-$MYSQL_VERSION-$MYSQL_STORAGE_ENGINE-$BENCH_ID-${LOG_BENCHMARK_NAME}-$NUM_ROWS-$num_threads-$COMMIT_SYNC-DEFAULTS.RANGE.PRIMARY.txt
    LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
    LOG_NAME_MEMORY=${LOG_NAME}.memory
    LOG_NAME_IOSTAT=${LOG_NAME}.iostat
    LOG_NAME_DSTAT=${LOG_NAME}.dstat
    LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv
    LOG_NAME_PMPROF=${LOG_NAME}.pmprof
    
    if [ ${BENCHMARK_LOGGING} == "Y" ]; then
        # verbose logging
        echo "*** verbose benchmark logging enabled ***"

        capture-engine-status.bash $RUN_TIME_SECONDS $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS ${MYSQL_STORAGE_ENGINE} &
        capture-memory.bash $RUN_TIME_SECONDS ${SHOW_MEMORY_INTERVAL} ${LOG_NAME_MEMORY} mysqld &
        iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
        dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &
        #pmprof.bash 200 2 1 mysqld ${LOG_NAME_PMPROF} 0 &
    fi

    sysbench --test=${SYSBENCH_DIR}/tests/db/tokudb_select_range_limit_primary.lua --oltp_tables_count=$NUM_TABLES --oltp-table-size=$NUM_ROWS --rand-init=on --num-threads=$num_threads --report-interval=$REPORT_INTERVAL --rand-type=$RAND_TYPE --mysql-socket=$MYSQL_SOCKET --mysql-table-engine=$MYSQL_STORAGE_ENGINE --max-time=$RUN_TIME_SECONDS --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWORD --mysql-db=$DBNAME --max-requests=0 --oltp-point-selects=$POINT_SELECTS_PER_XACT --oltp-range-size=$RANGE_SIZE --oltp-simple-ranges=$RANGE_LIMIT --percentile=99 run | tee $LOG_NAME
    
    echo "BEGIN-SHOW-VARIABLES" >> $LOG_NAME
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show variables" >> $LOG_NAME
    echo "END-SHOW-VARIABLES" >> $LOG_NAME
    echo "BEGIN-SHOW-ENGINE-STATUS" >> $LOG_NAME
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show engine $MYSQL_STORAGE_ENGINE status" >> $LOG_NAME
    echo "END-SHOW-ENGINE-STATUS" >> $LOG_NAME
    
    sleep ${SLEEP_SECONDS}
    
    bkill
done


sleep ${SLEEP_SECONDS}


# point query test - SECONDARY KEY
for num_threads in ${threadCountList}; do
    IOSTAT_ROUNDS=$[RUN_TIME_SECONDS/IOSTAT_INTERVAL+1]
    DSTAT_ROUNDS=$[RUN_TIME_SECONDS/DSTAT_INTERVAL+1]
    LOG_NAME=$MACHINE_NAME-$MYSQL_NAME-$MYSQL_VERSION-$MYSQL_STORAGE_ENGINE-$BENCH_ID-${LOG_BENCHMARK_NAME}-$NUM_ROWS-$num_threads-$COMMIT_SYNC-DEFAULTS.POINT.SECONDARY.txt
    LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
    LOG_NAME_MEMORY=${LOG_NAME}.memory
    LOG_NAME_IOSTAT=${LOG_NAME}.iostat
    LOG_NAME_DSTAT=${LOG_NAME}.dstat
    LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv
    LOG_NAME_PMPROF=${LOG_NAME}.pmprof
    
    if [ ${BENCHMARK_LOGGING} == "Y" ]; then
        # verbose logging
        echo "*** verbose benchmark logging enabled ***"

        capture-engine-status.bash $RUN_TIME_SECONDS $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS ${MYSQL_STORAGE_ENGINE} &
        capture-memory.bash $RUN_TIME_SECONDS ${SHOW_MEMORY_INTERVAL} ${LOG_NAME_MEMORY} mysqld &
        iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
        dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &
        #pmprof.bash 200 2 1 mysqld ${LOG_NAME_PMPROF} 0 &
    fi

    sysbench --test=${SYSBENCH_DIR}/tests/db/tokudb_select_point_secondary.lua --oltp_tables_count=$NUM_TABLES --oltp-table-size=$NUM_ROWS --rand-init=on --num-threads=$num_threads --report-interval=$REPORT_INTERVAL --rand-type=$RAND_TYPE --mysql-socket=$MYSQL_SOCKET --mysql-table-engine=$MYSQL_STORAGE_ENGINE --max-time=$RUN_TIME_SECONDS --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWORD --mysql-db=$DBNAME --max-requests=0 --oltp-point-selects=$POINT_SELECTS_PER_XACT --percentile=99 run | tee $LOG_NAME

    echo "BEGIN-SHOW-VARIABLES" >> $LOG_NAME
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show variables" >> $LOG_NAME
    echo "END-SHOW-VARIABLES" >> $LOG_NAME
    echo "BEGIN-SHOW-ENGINE-STATUS" >> $LOG_NAME
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show engine $MYSQL_STORAGE_ENGINE status" >> $LOG_NAME
    echo "END-SHOW-ENGINE-STATUS" >> $LOG_NAME
    
    sleep ${SLEEP_SECONDS}
    
    bkill
done


sleep ${SLEEP_SECONDS}


# range/limit query test - SECONDARY KEY
for num_threads in ${threadCountList}; do
    IOSTAT_ROUNDS=$[RUN_TIME_SECONDS/IOSTAT_INTERVAL+1]
    DSTAT_ROUNDS=$[RUN_TIME_SECONDS/DSTAT_INTERVAL+1]
    LOG_NAME=$MACHINE_NAME-$MYSQL_NAME-$MYSQL_VERSION-$MYSQL_STORAGE_ENGINE-$BENCH_ID-${LOG_BENCHMARK_NAME}-$NUM_ROWS-$num_threads-$COMMIT_SYNC-DEFAULTS.RANGE.SECONDARY.txt
    LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
    LOG_NAME_MEMORY=${LOG_NAME}.memory
    LOG_NAME_IOSTAT=${LOG_NAME}.iostat
    LOG_NAME_DSTAT=${LOG_NAME}.dstat
    LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv
    LOG_NAME_PMPROF=${LOG_NAME}.pmprof
    
    if [ ${BENCHMARK_LOGGING} == "Y" ]; then
        # verbose logging
        echo "*** verbose benchmark logging enabled ***"

        capture-engine-status.bash $RUN_TIME_SECONDS $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS ${MYSQL_STORAGE_ENGINE} &
        capture-memory.bash $RUN_TIME_SECONDS ${SHOW_MEMORY_INTERVAL} ${LOG_NAME_MEMORY} mysqld &
        iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
        dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &
        #pmprof.bash 200 2 1 mysqld ${LOG_NAME_PMPROF} 0 &
    fi

    sysbench --test=${SYSBENCH_DIR}/tests/db/tokudb_select_range_limit_secondary.lua --oltp_tables_count=$NUM_TABLES --oltp-table-size=$NUM_ROWS --rand-init=on --num-threads=$num_threads --report-interval=$REPORT_INTERVAL --rand-type=$RAND_TYPE --mysql-socket=$MYSQL_SOCKET --mysql-table-engine=$MYSQL_STORAGE_ENGINE --max-time=$RUN_TIME_SECONDS --mysql-user=$MYSQL_USER --mysql-password=$MYSQL_PASSWORD --mysql-db=$DBNAME --max-requests=0 --oltp-point-selects=$POINT_SELECTS_PER_XACT --oltp-range-size=$RANGE_SIZE --oltp-simple-ranges=$RANGE_LIMIT --percentile=99 run | tee $LOG_NAME
    
    echo "BEGIN-SHOW-VARIABLES" >> $LOG_NAME
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show variables" >> $LOG_NAME
    echo "END-SHOW-VARIABLES" >> $LOG_NAME
    echo "BEGIN-SHOW-ENGINE-STATUS" >> $LOG_NAME
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show engine $MYSQL_STORAGE_ENGINE status" >> $LOG_NAME
    echo "END-SHOW-ENGINE-STATUS" >> $LOG_NAME
    
    sleep ${SLEEP_SECONDS}
    
    bkill
done

bkill

parse_fbpileup.pl summary . > ${MACHINE_NAME}.summary

DATE=`date +"%Y%m%d%H%M%S"`
tarFileName="fbpileup_${BENCH_ID}_perf_result_set_${DATE}.tar.gz"
tar czvf ${tarFileName} ${MACHINE_NAME}* ${DB_DIR}/data/*.err
cp ${tarFileName} ${SCP_TARGET}
cp ${MACHINE_NAME}.summary ${WORKSPACE_LOC}/fbpileup_${BENCH_ID}_perf_result_set_${DATE}.txt
sed -n '/POINT.PRIMARY/,+8p' ${MACHINE_NAME}.summary > ${WORKSPACE_LOC}/fbpileup_POINT.PRIMARY_${BENCH_ID}_perf_result_set_${DATE}.txt
sed -n '/POINT.SECONDARY/,+8p' ${MACHINE_NAME}.summary > ${WORKSPACE_LOC}/fbpileup_POINT.SECONDARY_${BENCH_ID}_perf_result_set_${DATE}.txt
sed -n '/RANGE.PRIMARY/,+8p' ${MACHINE_NAME}.summary > ${WORKSPACE_LOC}/fbpileup_RANGE.PRIMARY_${BENCH_ID}_perf_result_set_${DATE}.txt
sed -n '/RANGE.SECONDARY/,+8p' ${MACHINE_NAME}.summary > ${WORKSPACE_LOC}/fbpileup_RANGE.SECONDARY_${BENCH_ID}_perf_result_set_${DATE}.txt

result_set1=($(grep threads ${WORKSPACE_LOC}/fbpileup_POINT.PRIMARY_${BENCH_ID}_perf_result_set_${DATE}.txt |  awk '{print ","$5 }'))
for i in {0..7}; do if [ -z ${result_set1[i]} ]; then  result_set1[i]=',0' ; fi; done
result_set2=($(grep threads ${WORKSPACE_LOC}/fbpileup_POINT.SECONDARY_${BENCH_ID}_perf_result_set_${DATE}.txt |  awk '{print ","$5 }'))
for i in {0..7}; do if [ -z ${result_set2[i]} ]; then  result_set2[i]=',0' ; fi; done
result_set3=($(grep threads ${WORKSPACE_LOC}/fbpileup_RANGE.PRIMARY_${BENCH_ID}_perf_result_set_${DATE}.txt |  awk '{print ","$5 }'))
for i in {0..7}; do if [ -z ${result_set3[i]} ]; then  result_set3[i]=',0' ; fi; done
result_set4=($(grep threads ${WORKSPACE_LOC}/fbpileup_RANGE.SECONDARY_${BENCH_ID}_perf_result_set_${DATE}.txt |  awk '{print ","$5 }'))
for i in {0..7}; do if [ -z ${result_set4[i]} ]; then  result_set4[i]=',0' ; fi; done

echo "[ '${BUILD_NUMBER}' ${result_set1[*]} ]," >> ${WORKSPACE_LOC}/fbpileup_POINT.PRIMARY_${BENCH_ID}_perf_result_set.txt
echo "[ '${BUILD_NUMBER}' ${result_set2[*]} ]," >> ${WORKSPACE_LOC}/fbpileup_POINT.SECONDARY_${BENCH_ID}_perf_result_set.txt
echo "[ '${BUILD_NUMBER}' ${result_set3[*]} ]," >> ${WORKSPACE_LOC}/fbpileup_RANGE.PRIMARY_${BENCH_ID}_perf_result_set.txt
echo "[ '${BUILD_NUMBER}' ${result_set4[*]} ]," >> ${WORKSPACE_LOC}/fbpileup_RANGE.SECONDARY_${BENCH_ID}_perf_result_set.txt

rm -f ${MACHINE_NAME}*


