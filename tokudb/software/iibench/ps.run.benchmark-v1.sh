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
    export MYSQL_STORAGE_ENGINE=tokudb
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


if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
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
elif [ ${MYSQL_STORAGE_ENGINE} == "deepdb" ]; then
    if [ -z "$DEEPDB_CACHE_SIZE" ]; then
        echo "Need to set DEEPDB_CACHE_SIZE"
        exit 1
    fi
    if [ -z "$TARBALL" ]; then
        echo "Need to set TARBALL"
        exit 1
    fi
elif [ ${MYSQL_STORAGE_ENGINE} == "wiredtiger" ]; then
    echo "Currently no customized settings for WIREDTIGER."
elif [ ${MYSQL_STORAGE_ENGINE} == "rocksdb" ]; then
    if [ -z "$ROCKSDB_CACHE" ]; then
        echo "Need to set ROCKSDB_CACHE"
        exit 1
    fi
else
    # pick your basement node size: 64k=65536, 128K=131072
    if [ -z "$TOKUDB_READ_BLOCK_SIZE" ]; then
        export TOKUDB_READ_BLOCK_SIZE=65536
    fi
    
    if [ -z "$TOKUDB_COMPRESSION" ]; then
        export TOKUDB_COMPRESSION=quicklz
    fi
    
    export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
    
    if [ -z "$TARBALL" ]; then
        export TARBALL=blank-toku665.54176.backup-mysql-5.5.28
    fi
    if [ -z "$BENCH_ID" ]; then
        export BENCH_ID=665.54176.backup
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
        ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} shutdown
    fi

    echo "Creating database from ${TARBALL} in ${DB_DIR}"
    if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
        MYSQL_OPTS="--innodb_buffer_pool_size=${INNODB_CACHE} --innodb_flush_method=${INNODB_FLUSH_METHOD}"
    elif [ ${MYSQL_STORAGE_ENGINE} == "rocksdb" ]; then
        MYSQL_OPTS="--rocksdb-block-cache-size=${ROCKSDB_CACHE} --plugin-load-add=rocksdb=ha_rocksdb.so --init-file=${SCRIPT_DIR}/MyRocks.sql --default-storage-engine=ROCKSDB --rocksdb_block_size=16384"
    elif [ ${MYSQL_STORAGE_ENGINE} == "deepdb" ]; then
        MYSQL_OPTS="deepdb_cache_size=${DEEBDB_CACHE_SIZE}"
        #echo "[mysqld_safe]" >> my.cnf
        #echo "malloc-lib=$PWD/lib/plugin/libtcmalloc_minimal.so" >> my.cnf
    elif [ ${MYSQL_STORAGE_ENGINE} == "wiredtiger" ]; then
        # no customizations for wiredtiger, yet.
        tempWtVar=1
    else
        MYSQL_OPTS="--tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE} --tokudb_row_format=${TOKUDB_ROW_FORMAT} --tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE} --plugin-load=tokudb=ha_tokudb.so --init-file=${SCRIPT_DIR}/TokuDB.sql"
        if [ ${DIRECTIO} == "Y" ]; then
            echo "tokudb_directio=1" >> my.cnf
            MYSQL_OPTS="$MYSQL_OPTS --tokudb_directio=1"
        fi
    fi
    rm -Rf  ${DB_DIR}/data/*
    mkdir -p  ${DB_DIR}/tmp
    BIN=`find ${DB_DIR} -maxdepth 2 -name mysqld -type f -o -name mysqld-debug -type f | head -1`;if [ -z $BIN ]; then echo "Assert! mysqld binary '$BIN' could not be read";exit 1;fi
    MID=`find ${DB_DIR} -maxdepth 2 -name mysql_install_db`;if [ -z $MID ]; then echo "Assert! mysql_install_db '$MID' could not be read";exit 1;fi

    if [ "`$BIN --version | grep -oe '5\.[1567]' | head -n1`" == "5.7" ]; then 
      VERSION_CHK=`$BIN  --version | grep -oe '5\.[1567]\.[0-9]*' | cut -f3 -d'.' | head -n1`
      if [[ $VERSION_CHK -ge 5 ]]; then
        MID_OPTIONS="--initialize-insecure"
      else
        MID_OPTIONS="--insecure"
      fi
    elif [ "`$BIN --version | grep -oe '5\.[1567]' | head -n1`" == "5.6" ]; then 
      MID_OPTIONS='--force'; 
    elif [ "`$BIN --version | grep -oe '5\.[1567]' | head -n1`" == "5.5" ]; then 
      MID_OPTIONS='--force';
    else 
      MID_OPTIONS=''; 
    fi

    if [ "${MID_OPTIONS}" == "--initialize-insecure" ]; then
      MID="${DB_DIR}/bin/mysqld"
    else
      MID="${DB_DIR}/bin/mysql_install_db"
    fi
    
    $MID --no-defaults --basedir=${DB_DIR} --datadir=${DB_DIR}/data $MID_OPTIONS > ${DB_DIR}/mysqld_install.out  2>&1
    mkdir -p  ${DB_DIR}/data/test
    ## Starting mysqld
    if [ "${JEMALLOC}" != "" -a -r "${JEMALLOC}" ]; then export LD_PRELOAD=${JEMALLOC}
    elif [ -r /usr/lib64/libjemalloc.so.1 ]; then export LD_PRELOAD=/usr/lib64/libjemalloc.so.1
    elif [ -r /usr/lib/x86_64-linux-gnu/libjemalloc.so.1 ]; then export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1
    elif [ -r ${DB_DIR}/lib/mysql/libjemalloc.so.1 ]; then export LD_PRELOAD=${DB_DIR}/lib/mysql/libjemalloc.so.1
    else echo 'Warning: jemalloc was not loaded as it was not found (this is fine for MS, but do check ./1430715139_DB_DIR to set correct jemalloc location for PS)'; fi
    $BIN --no-defaults ${MYEXTRA} --basedir=${DB_DIR} --datadir=${DB_DIR}/data ${MYSQL_OPTS}  --port=${MYSQL_PORT} --pid-file=${DB_DIR}/data/pid.pid --core-file --socket=${MYSQL_SOCKET} --log-error=${DB_DIR}/data/error.log.out >  ${DB_DIR}/data/mysqld.out 2>&1 &
    for X in $(seq 0 60); do
      sleep 1
      if ${DB_DIR}/bin/mysqladmin -uroot -S${MYSQL_SOCKET} ping > /dev/null 2>&1; then
        break
      fi
    done

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
    ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} shutdown
fi

sleep 15

DATE=`date +"%Y%m%d%H%M%S"`
tarFileName="iibench_${BENCH_ID}_perf_result_set_${DATE}.tar.gz"
tar czvf ${tarFileName} ${MACHINE_NAME}* ${DB_DIR}/data/*.err
cp ${tarFileName} ${SCP_TARGET}
cp ${LOG_NAME} ${WORKSPACE_LOC}/iibench_${BENCH_ID}_perf_result_set_${DATE}.txt
if [ ! -z ${IIBENCH_MODE} ];then
  result_set=($(grep '^[0-9][0-9]' ${LOG_NAME} |  awk '{print $8"," }' | head -5))
  for i in {0..4}; do if [ -z ${result_set[i]} ]; then  result_set[i]='0,' ; fi; done
else
  result_set=($(grep '^[0-9][0-9]' ${LOG_NAME} |  awk '{print $6"," }' | head -5))
  for i in {0..4}; do if [ -z ${result_set[i]} ]; then  result_set[i]='0,' ; fi; done
fi
echo "[ '${BUILD_NUMBER}', ${result_set[*]} $avg_result ]," >> ${WORKSPACE_LOC}/iibench_${BENCH_ID}_perf_result_set.txt
 
rm -f ${MACHINE_NAME}*

