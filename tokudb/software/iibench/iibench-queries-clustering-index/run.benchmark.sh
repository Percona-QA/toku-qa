#!/bin/bash


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
    export BENCHMARK_NUMBER=999
fi

if [ -z "$SCP_FILES" ]; then
    export SCP_FILES=Y
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
else
    export TOKUDB_COMPRESSION=quicklz
    # pick your basement node size: 64k=65536, 128K=131072
    export TOKUDB_READ_BLOCK_SIZE=65536
    export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
    if [ -z "$TARBALL" ]; then
        #export TARBALL=blank-toku650.48167-${MYSQL_NAME}-${MYSQL_VERSION}
        export TARBALL=blank-5842.51799-mysql-5.5.28
    fi
    if [ -z "$BENCH_ID" ]; then
        #export BENCH_ID=650.48167.${TOKUDB_COMPRESSION}
        export BENCH_ID=yahoo.test
    fi
fi

if [ -z "$CLUSTERING" ]; then
    export CLUSTERING=Y
fi
if [ ${CLUSTERING} == "N" ]; then
    export BENCH_ID=$BENCH_ID.not-clustering
else
    export BENCH_ID=$BENCH_ID.clustering
    IIBENCH_EXTRA_ARGS="$IIBENCH_EXTRA_ARGS --clustering"
fi


export MYSQL_USER=root
export MYSQL_DATABASE=test
export BENCHMARK_LOGGING=Y

export MAX_IPS=-1

if [ -z "$MAX_ROWS" ]; then
    export MAX_ROWS=1000000000
fi
if [ -z "$MAX_TABLE_ROWS" ]; then
    export MAX_TABLE_ROWS=${MAX_ROWS}
fi
if [ -z "$ROWS_PER_QUERY" ]; then
    export ROWS_PER_QUERY=100
fi
if [ -z "$DATA_LENGTH_MAX" ]; then
    export DATA_LENGTH_MAX=350
fi
if [ -z "$DATA_LENGTH_MIN" ]; then
    export DATA_LENGTH_MIN=250
fi
if [ -z "$DATA_RANDOM_PCT" ]; then
    export DATA_RANDOM_PCT=50
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
export SHOW_ENGINE_STATUS_INTERVAL=60
export SHOW_SYSINFO_INTERVAL=10
export IOSTAT_INTERVAL=10
export IOSTAT_ROUNDS=$[RUN_SECONDS/IOSTAT_INTERVAL+1]
export DSTAT_INTERVAL=10
export DSTAT_ROUNDS=$[RUN_SECONDS/DSTAT_INTERVAL+1]
export WRITE_CAPTURE_INTERVAL=10
export WRITE_CAPTURE_ROUNDS=$[RUN_SECONDS/WRITE_CAPTURE_INTERVAL-1]

export COMMIT_SYNC=0
if [ -z "$UNIQUE_CHECKS" ]; then
    export UNIQUE_CHECKS=1
fi

if [ -z "$INSERT_ONLY" ]; then
    export INSERT_ONLY=0
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
LOG_NAME_SYSINFO=${LOG_NAME}.sysinfo
LOG_NAME_IOSTAT=${LOG_NAME}.iostat
LOG_NAME_DSTAT=${LOG_NAME}.dstat
LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv
LOG_NAME_WRITE_CAPTURE=${LOG_NAME}.writecap
LOG_NAME_PMPROF=${LOG_NAME}.pmprof

rm -f $LOG_NAME

# ---------------------------------------------------------------------------
# stop mysql if it is currently running (in case someone was sloppy)
# ---------------------------------------------------------------------------

if [ -e "${DB_DIR}/bin/mysqladmin" ]; then
    ${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} shutdown
fi

# ---------------------------------------------------------------------------
# create the database, start it, update global defaults
# ---------------------------------------------------------------------------

echo "Creating database from ${TARBALL} in ${DB_DIR}"
pushd ${DB_DIR}
mkdb-quiet ${TARBALL}
if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "innodb_buffer_pool_size=${INNODB_BUFFER_POOL_SIZE}" >> my.cnf
    echo "innodb_flush_method=${INNODB_FLUSH_METHOD}" >> my.cnf
else
    echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
    echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
    echo "tokudb_cache_size=2G" >> my.cnf
fi
mstart
popd

# ---------------------------------------------------------------------------
# verbose logging?
# ---------------------------------------------------------------------------

if [ ${BENCHMARK_LOGGING} == "Y" ]; then
    # verbose logging
    echo "*** verbose benchmark logging enabled ***"

    capture-engine-status.bash $RUN_SECONDS $SHOW_ENGINE_STATUS_INTERVAL ${MYSQL_USER} ${MYSQL_SOCKET} $LOG_NAME_ENGINE_STATUS ${MYSQL_STORAGE_ENGINE} &
    capture-sysinfo.bash ${RUN_SECONDS} ${SHOW_SYSINFO_INTERVAL} ${LOG_NAME_SYSINFO} &
    iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
    dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &
    mysql-show-what $WRITE_CAPTURE_INTERVAL $WRITE_CAPTURE_ROUNDS Handler_write > $LOG_NAME_WRITE_CAPTURE &
    #pmprof.bash 200 2 1 mysqld ${LOG_NAME_PMPROF} 0 &
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
python iibench.py --setup --db_socket=${MYSQL_SOCKET} --db_name=${MYSQL_DATABASE} --max_rows=${MAX_ROWS} --max_table_rows=${MAX_TABLE_ROWS} --rows_per_report=${ROWS_PER_REPORT} --engine=${MYSQL_STORAGE_ENGINE} ${IIBENCH_QUERY_PARM} --unique_checks=${UNIQUE_CHECKS} --run_minutes=${RUN_MINUTES} --tokudb_commit_sync=${COMMIT_SYNC} --max_ips=${MAX_IPS} --rows_per_query=${ROWS_PER_QUERY} ${IIBENCH_EXTRA_ARGS} | tee ${LOG_NAME}

T="$(($(date +%s)-T))"
printf "`date` | iibench duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

echo "`date` | checking TokuDB sizing = `du -ch ${DB_DIR}/data/*.tokudb            | tail -n 1`" | tee -a $LOG_NAME
echo "`date` | checking InnoDB sizing = `du -ch ${DB_DIR}/data/${MYSQL_DATABASE}   | tail -n 1`" | tee -a $LOG_NAME

# ---------------------------------------------------------------------------
# stop mysql (leave things as you found them)
# ---------------------------------------------------------------------------

${DB_DIR}/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} shutdown

sleep 15

bkill

# ---------------------------------------------------------------------------
# pack things up in case I want them later
# ---------------------------------------------------------------------------
#COPY_DIR_NAME=$DB_DIR/../`printf "%04d" ${FULL_RUN_NUMBER}`-iibench-test
#mkdir ${COPY_DIR_NAME}
#mv $DB_DIR/* ${COPY_DIR_NAME}
#let FULL_RUN_NUMBER=FULL_RUN_NUMBER+1

parse_iibench.pl summary . > ${MACHINE_NAME}.summary

if [ ${SCP_FILES} == "Y" ]; then
    DATE=`date +"%Y%m%d%H%M%S"`
    tarFileName="${MACHINE_NAME}-${BENCHMARK_NUMBER}-${DATE}-${BENCHMARK_NAME}-${BENCH_ID}.tar.gz"

    tar czvf ${tarFileName} ${MACHINE_NAME}* ${DB_DIR}/data/*.err
    scp ${tarFileName} ${SCP_TARGET}:~
    
    rm -f ${tarFileName}
    rm -f ${MACHINE_NAME}*

    movecores
fi
