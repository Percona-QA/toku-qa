#/bin/bash

# vars
# MYSQL_NAME=mysql, mariadb
# MYSQL_VERSION=5.5.28, 5.5.28a
# MYSQL_STORAGE_ENGINE=tokudb, innodb
# NUM_WAREHOUSES=100
# RUN_TIME_SECONDS=300
# SCP_FILES=Y
# NEW_ORDERS_PER_TEN_SECONDS=200000 (rate limiting)
# TARBALL=blank-toku650.48167-mysql-5.5.24
# BENCH_ID=650.48167.quicklz.64k
# TOKUDB_READ_BLOCK_SIZE=65536
# TOKUDB_COMPRESSION=quicklz, lzma, zlib, uncompressed


if [ -z "$MYSQL_NAME" ]; then
    export MYSQL_NAME=mysql
fi
if [ -z "$MYSQL_VERSION" ]; then
    export MYSQL_VERSION=5.5.28
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    export MYSQL_STORAGE_ENGINE=tokudb
fi
if [ -z "$NUM_WAREHOUSES" ]; then
    export NUM_WAREHOUSES=500
fi
if [ -z "$RUN_TIME_SECONDS" ]; then
    export RUN_TIME_SECONDS=300
fi
if [ -z "$SCP_FILES" ]; then
    export SCP_FILES=Y
fi
if [ -z "$NEW_ORDERS_PER_TEN_SECONDS" ]; then
    export NEW_ORDERS_PER_TEN_SECONDS=200000
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    export BENCHMARK_NUMBER=008
fi
if [ -z "$DIRECTIO" ]; then
    export DIRECTIO=N
fi
if [ -z "$WARMUP" ]; then
    export WARMUP=N
fi

if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    if [ -z "$INNODB_CACHE" ]; then
        echo "Need to set INNODB_CACHE"
        exit 1
    fi
    export INNODB_COMPRESSION=N
    export INNODB_KEY_BLOCK_SIZE=8
    export INNODB_FK=Y
    export INNODB_BUFFER_POOL_SIZE=${INNODB_CACHE}
    # O_DIRECT, O_DSYNC, **default is special case and not yet supported by this script**
    export INNODB_FLUSH_METHOD=O_DIRECT
    if [ -z "$TARBALL" ]; then
        export TARBALL=blank-mysql5529
    fi
    if [ ${INNODB_COMPRESSION} == "Y" ]; then
        if [ -z "$BENCH_ID" ]; then
            export BENCH_ID=1.1.8.compressed.${INNODB_KEY_BLOCK_SIZE}
        fi 
    else
        if [ -z "$BENCH_ID" ]; then
            export BENCH_ID=1.1.8
        fi
    fi
    if [ ${INNODB_FK} == "Y" ]; then
        export BENCH_ID=${BENCH_ID}.fk
    else
        export BENCH_ID=${BENCH_ID}.nofk
    fi
else
    if [ -z "$TOKUDB_COMPRESSION" ]; then
        export TOKUDB_COMPRESSION=quicklz
    fi
    if [ -z "$TOKUDB_READ_BLOCK_SIZE" ]; then
        export TOKUDB_READ_BLOCK_SIZE=65536
    fi
    export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
    if [ -z "$TARBALL" ]; then
        export TARBALL=blank-673.nopunch.52935-mysql-5.5.28
    fi
    if [ -z "$BENCH_ID" ]; then
        export BENCH_ID=673.nopunch.52935.${TOKUDB_COMPRESSION}.${TOKUDB_READ_BLOCK_SIZE}
    fi
fi


export BENCHMARK_LOGGING=Y
export LOADER_LOGGING=Y

export MYSQL_DATABASE=tpcc
export MYSQL_USER=root

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi

if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
  MYSQL_OPTS="--innodb_buffer_pool_size=${INNODB_BUFFER_POOL_SIZE} --innodb_flush_method=${INNODB_FLUSH_METHOD}"
  if [ -n "$INNODB_ONLINE_ALTER_LOG_MAX_SIZE" ]; then
    MYSQL_OPTS="$MYSQL_OPTS --innodb_online_alter_log_max_size=${INNODB_ONLINE_ALTER_LOG_MAX_SIZE}"
  fi
else
  MYSQL_OPTS="--tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE} --tokudb_row_format=${TOKUDB_ROW_FORMAT} --plugin-load=tokudb=ha_tokudb.so --init-file=${SCRIPT_DIR}/../../TokuDB.sql --tokudb_lock_timeout=60000 --tokudb_loader_memory_size=1G"
  if [ ${DIRECTIO} == "Y" ]; then
     MYSQL_OPTS="$MYSQL_OPTS --tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE} --tokudb_directio=1"
  fi
fi
MYSQL_OPTS="$MYSQL_OPTS --max_prepared_stmt_count=65536 --max_connections=2048" 
# Load jemalloc lib 
if [ "${JEMALLOC}" != "" -a -r "${JEMALLOC}" ]; then export LD_PRELOAD=${JEMALLOC}
elif [ -r /usr/lib64/libjemalloc.so.1 ]; then export LD_PRELOAD=/usr/lib64/libjemalloc.so.1
elif [ -r /usr/lib/x86_64-linux-gnu/libjemalloc.so.1 ]; then export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1
elif [ -r ${DB_DIR}/lib/mysql/libjemalloc.so.1 ]; then export LD_PRELOAD=${DB_DIR}/lib/mysql/libjemalloc.so.1
else echo 'Warning: jemalloc was not loaded as it was not found (this is fine for MS, but do check ./1430715139_DB_DIR to set correct jemalloc location for PS)'; fi
timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${MYSQL_SOCKET} shutdown > /dev/null 2>&1
rm -Rf  ${DB_DIR}/data/*
mkdir -p  ${DB_DIR}/tmp
BIN=`find ${DB_DIR} -maxdepth 2 -name mysqld -type f -o -name mysqld-debug -type f | head -1`;if [ -z $BIN ]; then echo "Assert! mysqld binary '$BIN' could not be read";exit 1;fi
MID=`find ${DB_DIR} -maxdepth 2 -name mysql_install_db`;if [ -z $MID ]; then echo "Assert! mysql_install_db '$MID' could not be read";exit 1;fi
if [ "`$BIN --version | grep -oe '5\.[1567]' | head -n1`" == "5.7" ]; then MID_OPTIONS='--insecure'; elif [ "`$BIN --version | grep -oe '5\.[1567]' | head -n1`" == "5.6" ]; then MID_OPTIONS='--force'; elif [ "`$BIN --version| grep -oe '5\.[1567]' | head -n1`" == "5.5" ]; then MID_OPTIONS='--force';else MID_OPTIONS=''; fi

PS_VERSION=`$BIN --version | grep -oe '5\.[1567]' | sed 's/\.//' | head -n1`
if [ -d ${BIG_DIR}/tpcc_data_dir_${MYSQL_STORAGE_ENGINE}_${NUM_WAREHOUSES}/master-data ]; then
  cp -r ${BIG_DIR}/tpcc_data_dir_${MYSQL_STORAGE_ENGINE}_${NUM_WAREHOUSES}/master-data/*  ${DB_DIR}/data/
  $BIN --no-defaults --basedir=${DB_DIR} --datadir=${DB_DIR}/data ${MYSQL_OPTS}  --port=${MYSQL_PORT} --pid-file=${DB_DIR}/data/pid.pid --core-file --socket=${MYSQL_SOCKET} --log-error=${DB_DIR}/data/error.log.out >  ${DB_DIR}/data/mysqld.out 2>&1 &
  MPID="$!"
else
  bash -x ${SCRIPT_DIR}/../../tpcc_create_db_template.sh ${BIG_DIR} $PS_VERSION ${MYSQL_STORAGE_ENGINE}
  cp -r ${BIG_DIR}/tpcc_data_dir_${MYSQL_STORAGE_ENGINE}_${NUM_WAREHOUSES}/master-data/*  ${DB_DIR}/data/
  $BIN --no-defaults --basedir=${DB_DIR} --datadir=${DB_DIR}/data ${MYSQL_OPTS}  --port=${MYSQL_PORT} --pid-file=${DB_DIR}/data/pid.pid --core-file --socket=${MYSQL_SOCKET} --log-error=${DB_DIR}/data/error.log.out >  ${DB_DIR}/data/mysqld.out 2>&1 &
  MPID="$!" 
fi
for X in $(seq 0 60); do
  sleep 1
  if ${DB_DIR}/bin/mysqladmin -uroot -S${MYSQL_SOCKET} ping > /dev/null 2>&1; then
    break
  fi
done


echo "Running benchmark"
bash -x ./ps.run.benchmark.sh

echo "Stopping database"
timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${MYSQL_SOCKET} shutdown > /dev/null 2>&1

(sleep 0.2; kill -9 ${MPID} >/dev/null 2>&1; wait ${MPID} >/dev/null 2>&1) &  # Terminate mysqld
wait ${MPID} >/dev/null 2>&1
kill -9 ${MPID} >/dev/null 2>&1;
sleep 2
