#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi

if [ -z "$MYSQL_NAME" ]; then
    export MYSQL_NAME=mysql
fi
if [ -z "$MYSQL_VERSION" ]; then
    export MYSQL_VERSION=5.5.30
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    export MYSQL_STORAGE_ENGINE=tokudb
fi
if [ -z "$TARBALL" ]; then
    export TARBALL=blank-toku701-mysql-5.5.30
fi
if [ -z "$TOKUDB_COMPRESSION" ]; then
    export TOKUDB_COMPRESSION=lzma
fi
if [ -z "$BENCH_ID" ]; then
    export BENCH_ID=${MYSQL_STORAGE_ENGINE}.dataload
fi
if [ -z "$NUM_ROWS" ]; then
    export NUM_ROWS=1000000
fi
if [ -z "$NUM_DATABASES" ]; then
    export NUM_DATABASES=1
fi
if [ -z "$RUN_TIME_SECONDS" ]; then
    export RUN_TIME_SECONDS=900
fi
if [ -z "$RAND_TYPE" ]; then
    export RAND_TYPE=uniform
fi
if [ -z "$TOKUDB_READ_BLOCK_SIZE" ]; then
    export TOKUDB_READ_BLOCK_SIZE=64K
fi
if [ -z "$SKIP_DB_CREATE" ]; then
    export SKIP_DB_CREATE=N
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    export BENCHMARK_NUMBER=008
fi
if [ -z "$DIRECTIO" ]; then
    export DIRECTIO=Y
fi
if [ -z "$READONLY" ]; then
    export READONLY=off
fi

export BENCHMARK_LOGGING=Y
export LOADER_LOGGING=Y

export MYSQL_DATABASE=test
export MYSQL_USER=root

export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}

if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
  if [ -z "$INNODB_CACHE" ]; then
    echo "Need to set INNODB_CACHE"
    exit 1
  fi
  if [ ${DIRECTIO} == "N" ]; then
    MYSQL_OPTS="--innodb_flush_method=${INNODB_FLUSH_METHOD}"
  fi
  MYSQL_OPTS="$MYSQL_OPTS --innodb_buffer_pool_size=${INNODB_CACHE}"
elif [ ${MYSQL_STORAGE_ENGINE} == "rocksdb" ]; then
  if [ -z "$ROCKSDB_CACHE" ]; then
    echo "Need to set ROCKSDB_CACHE"
    exit 1
  fi
  MYSQL_OPTS="--rocksdb-block-cache-size=${ROCKSDB_CACHE} --plugin-load-add=rocksdb=ha_rocksdb.so --init-file=${SCRIPT_DIR}/MyRocks.sql --default-storage-engine=ROCKSDB"
elif [ ${MYSQL_STORAGE_ENGINE} == "myisam" ]; then
  MYSQL_OPTS="key_buffer_size=8G"
#    echo "table_open_cache=2048" >> my.cnf
else
  MYSQL_OPTS="--tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE} --tokudb_row_format=${TOKUDB_ROW_FORMAT} --tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE} --plugin-load=tokudb=ha_tokudb.so --tokudb_loader_memory_size=1G"
  if [ ${DIRECTIO} == "Y" ]; then
    MYSQL_OPTS="$MYSQL_OPTS --tokudb_directio=1"
  fi
fi

if [ "`${DB_DIR}/bin/mysqld --version | grep -oe '5\.[1567]' | head -n1`" == "5.7" ]; then 
  VERSION_CHK=`${DB_DIR}/bin/mysqld  --version | grep -oe '5\.[1567]\.[0-9]*' | cut -f3 -d'.' | head -n1`
  if [[ $VERSION_CHK -ge 5 ]]; then
    MID_OPTIONS="--initialize-insecure"
  else
    MID_OPTIONS="--insecure"
  fi
elif [ "`${DB_DIR}/bin/mysqld --version | grep -oe '5\.[1567]' | head -n1`" == "5.6" ]; then 
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
	
timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${MYSQL_SOCKET} shutdown > /dev/null 2>&1
## Starting mysqld
BIN=`find ${DB_DIR} -maxdepth 2 -name mysqld -type f -o -name mysqld-debug -type f | head -1`;if [ -z $BIN ]; then echo "Assert! mysqld binary '$BIN' could not be read";exit 1;fi
if [ "${JEMALLOC}" != "" -a -r "${JEMALLOC}" ]; then export LD_PRELOAD=${JEMALLOC}
elif [ -r /usr/lib64/libjemalloc.so.1 ]; then export LD_PRELOAD=/usr/lib64/libjemalloc.so.1
elif [ -r /usr/lib/x86_64-linux-gnu/libjemalloc.so.1 ]; then export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1
elif [ -r ${DB_DIR}/lib/mysql/libjemalloc.so.1 ]; then export LD_PRELOAD=${DB_DIR}/lib/mysql/libjemalloc.so.1
else echo 'Warning: jemalloc was not loaded as it was not found (this is fine for MS, but do check ./1430715139_DB_DIR to set correct jemalloc location for PS)'; fi
$BIN ${MYEXTRA} --user=$STARTUP_USER --basedir=${DB_DIR} --datadir=${DB_DIR}/data ${MYSQL_OPTS} --port=${MYSQL_PORT} --pid-file=${DB_DIR}/data/pid.pid --core-file --socket=${MYSQL_SOCKET} --log-error=${DB_DIR}/data/error.log.out >  ${DB_DIR}/data/mysqld.out 2>&1 &
MPID="$!"
for X in $(seq 0 60); do
  sleep 1
  if ${DB_DIR}/bin/mysqladmin -uroot -S${MYSQL_SOCKET} ping > /dev/null 2>&1; then
    break
  fi
done

if [ ${MYSQL_STORAGE_ENGINE} == "rocksdb" ]; then
  ECHO=$(which echo)
  sudo service cgconfig restart
  sudo cgcreate -g memory:DBLimitedGroup
  sudo sh -c "$ECHO $CGROUP_MEM > /cgroup/memory/DBLimitedGroup/memory.limit_in_bytes"
  sudo sync;sudo sh -c "$ECHO 3 > /proc/sys/vm/drop_caches"
  sudo cgclassify -g memory:DBLimitedGroup `pidof mysqld`
fi

echo "Running bulk dataload benchmark"
for i in `seq 1 1000`; do
  STR1=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  STR2=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  STR3=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  yes "$RANDOM,$STR1,$STR2,$STR3" | head -n 100000 >> ${DB_DIR}/big_data.csv
done

${DB_DIR}/bin/mysql -uroot -S${MYSQL_SOCKET} -e"CREATE TABLE IF NOT EXISTS test.random_text ( random_id int NOT NULL, random_str1 varchar(33) NOT NULL, random_str2 varchar(33) NOT NULL, random_str3 varchar(33) NOT NULL ) engine=${MYSQL_STORAGE_ENGINE};" > /dev/null 2>&1;
bulk_load_time=$( { time -p  ${DB_DIR}/bin/mysql -uroot -S${MYSQL_SOCKET} -e"LOAD DATA LOCAL INFILE '${DB_DIR}/big_data.csv' INTO TABLE test.random_text FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'; " > /dev/null 2>&1; } 2>&1 )
bulk_load_time=(`echo $bulk_load_time | grep -o "real.*" | awk '{print $2}'`)
echo "[ '${BUILD_NUMBER}' ${bulk_load_time} ]," >> ${WORKSPACE_LOC}/${BENCH_ID}_load_data_perf_result_set.txt

echo "Running mysqldump benchmark"
mysqlump_time=$( { time -p  ${DB_DIR}/bin/mysqldump -uroot -S${MYSQL_SOCKET} test > ${DB_DIR}/backup.sql 2>&1; } 2>&1 )
mysqlump_time=(`echo $mysqlump_time | grep -o "real.*" | awk '{print $2}'`)
echo "[ '${BUILD_NUMBER}' ${mysqlump_time} ]," >> ${WORKSPACE_LOC}/${BENCH_ID}_mysqldump_perf_result_set.txt

echo "Running sysbench dataload benchmark"
# run for real
for num_threads in ${threadCountList}; do
    if [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "0.5" ]; then
      real_time=$( { time -p sysbench --test=/usr/share/doc/sysbench/tests/db/parallel_prepare.lua --mysql-table-engine=${MYSQL_STORAGE_ENGINE} --rand-type=$RAND_TYPE --num-threads=${num_threads} --oltp-tables-count=${num_threads}  --oltp-table-size=${NUM_ROWS} --mysql-db=test --mysql-user=root  --db-driver=mysql --mysql-socket=$MYSQL_SOCKET  run > /dev/null ; } 2>&1 )
      
      sysbench --test=/usr/share/doc/sysbench/tests/db/parallel_prepare.lua --mysql-table-engine=${MYSQL_STORAGE_ENGINE} --rand-type=$RAND_TYPE --num-threads=${num_threads} --oltp-tables-count=${num_threads}  --oltp-table-size=${NUM_ROWS} --mysql-db=test --mysql-user=root  --db-driver=mysql --mysql-socket=$MYSQL_SOCKET  cleanup > ${DB_DIR}/sysbench_cleanup 2>&1;
    elif [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "1.0" ]; then
      real_time=$( { time -p sysbench /usr/share/sysbench/oltp_insert.lua --mysql-storage-engine=${MYSQL_STORAGE_ENGINE} --rand-type=$RAND_TYPE  --threads=${num_threads} --tables=${num_threads}  --table-size=${NUM_ROWS} --mysql-db=test --mysql-user=root    --db-driver=mysql --mysql-socket=$MYSQL_SOCKET prepare > /dev/null; } 2>&1 )
      
      sysbench /usr/share/sysbench/oltp_insert.lua --mysql-storage-engine=${MYSQL_STORAGE_ENGINE} --rand-type=$RAND_TYPE  --threads=${num_threads} --tables=${num_threads}  --table-size=${NUM_ROWS} --mysql-db=test --mysql-user=root    --db-driver=mysql --mysql-socket=$MYSQL_SOCKET cleanup > ${DB_DIR}/sysbench_cleanup 2>&1
    fi
    sleep 6
	result_set+=(`echo $real_time | grep -o "real.*" | awk '{print $2}'`)
done

for i in {0..7}; do if [ -z ${result_set[i]} ]; then  result_set[i]=',0' ; fi; done
echo "[ '${BUILD_NUMBER}' ${result_set[*]} ]," >> ${WORKSPACE_LOC}/${BENCH_ID}_sysbench_perf_result_set.txt

DATE=`date +"%Y%m%d%H%M%S"`
tarFileName="${BENCH_ID}_perf_result_set_${DATE}.tar.gz"
tar czvf ${tarFileName} ${DB_DIR}/data/error.log.out ${WORKSPACE_LOC}/${BENCH_ID}_*.txt
cp ${tarFileName} ${SCP_TARGET}

echo "Stopping database"
timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${MYSQL_SOCKET} shutdown > /dev/null 2>&1
(sleep 0.2; kill -9 ${MPID} >/dev/null 2>&1; wait ${MPID} >/dev/null 2>&1) &  # Terminate mysqld
wait ${MPID} >/dev/null 2>&1
kill -9 ${MPID} >/dev/null 2>&1;
sleep 2

rm -f ${tarFileName}
