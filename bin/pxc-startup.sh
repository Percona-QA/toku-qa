#!/bin/bash

if [ -z "$DB_DIR" ]; then
  echo "Need to set DB_DIR"
  exit 1
fi

run_mid=0
if [ ! -z $1 ]; then
  if [ "$1" == "startup" ];then
    run_mid=1
  fi
fi

PXC_START_TIMEOUT=200
ADDR="127.0.0.1"
RPORT=$(( RANDOM%21 + 10 ))
RBASE1="$(( RPORT*1000 ))"
RADDR1="$ADDR:$(( RBASE1 + 7 ))"
LADDR1="$ADDR:$(( RBASE1 + 8 ))"

RBASE2="$(( RBASE1 + 100 ))"
RADDR2="$ADDR:$(( RBASE2 + 7 ))"
LADDR2="$ADDR:$(( RBASE2 + 8 ))"

RBASE3="$(( RBASE1 + 200 ))"
RADDR3="$ADDR:$(( RBASE3 + 7 ))"
LADDR3="$ADDR:$(( RBASE3 + 8 ))"

SUSER=root
SPASS=

# PXC startup script.
pxc_startup(){
  PXC_MYEXTRA=$1
  
  if [ "$(${DB_DIR}/bin/mysqld --version | grep -oe '5\.[567]' | head -n1)" == "5.7" ]; then
    MID="${DB_DIR}/bin/mysqld --no-defaults --initialize-insecure --basedir=${DB_DIR}"
  elif [ "$(${DB_DIR}/bin/mysqld --version | grep -oe '5\.[567]' | head -n1)" == "5.6" ]; then
    MID="${DB_DIR}/scripts/mysql_install_db --no-defaults --basedir=${DB_DIR}"
  fi

  if [ ${BENCH_SUITE} == "sysbench" ];then
    if [ $run_mid -eq 1 ]; then
      node1="${BIG_DIR}/sysbench_data_template/node1"
      node2="${BIG_DIR}/sysbench_data_template/node2"
      node3="${BIG_DIR}/sysbench_data_template/node3"
      if [ "$(${DB_DIR}/bin/mysqld --version | grep -oe '5\.[567]' | head -n1)" != "5.7" ]; then
        mkdir -p $node1 $node2 $node3
      fi
    else
      node1="${DB_DIR}/node1"
      node2="${DB_DIR}/node2"
      node3="${DB_DIR}/node3"
    fi
  else
    node1="${DB_DIR}/node1"
    node2="${DB_DIR}/node2"
    node3="${DB_DIR}/node3"
    if [ "$(${DB_DIR}/bin/mysqld --version | grep -oe '5\.[567]' | head -n1)" != "5.7" ]; then
      mkdir -p $node1 $node2 $node3
    fi
  fi
   
  echo 'Starting PXC nodes....'
  if [ $run_mid -eq 1 ]; then
    ${MID} --datadir=$node1  > ${DB_DIR}/startup_node1.err 2>&1 || exit 1;
  fi

  ${DB_DIR}/bin/mysqld $PXC_MYEXTRA --basedir=${DB_DIR} --datadir=$node1 \
    --innodb_autoinc_lock_mode=2 \
    --wsrep-provider=${DB_DIR}/lib/libgalera_smm.so \
    --wsrep_cluster_address=gcomm:// \
    --wsrep_node_incoming_address=$ADDR \
    --wsrep_provider_options=gmcast.listen_addr=tcp://$LADDR1 \
    --wsrep_sst_method=rsync --wsrep_sst_auth=$SUSER:$SPASS \
    --wsrep_node_address=$ADDR  \
    --log-error=$node1/node1.err \
    --socket=$node1/pxc-mysql.sock --log-output=none \
    --port=$RBASE1 --wsrep_slave_threads=2 > $node1/node1.err 2>&1 &

  for X in $(seq 0 ${PXC_START_TIMEOUT}); do
    sleep 1
    if ${DB_DIR}/bin/mysqladmin -uroot -S$node1/pxc-mysql.sock ping > /dev/null 2>&1; then
      echo 'Started PXC node1...'
      break
    fi
  done

  if [ $run_mid -eq 1 ]; then
    ${MID} --datadir=$node2  > ${DB_DIR}/startup_node2.err 2>&1 || exit 1;
  fi

  ${DB_DIR}/bin/mysqld $PXC_MYEXTRA --basedir=${DB_DIR} --datadir=$node2 \
    --innodb_autoinc_lock_mode=2 \
    --wsrep-provider=${DB_DIR}/lib/libgalera_smm.so \
    --wsrep_cluster_address=gcomm://$LADDR1,gcomm://$LADDR3 \
    --wsrep_node_incoming_address=$ADDR \
    --wsrep_provider_options=gmcast.listen_addr=tcp://$LADDR2 \
    --wsrep_sst_method=rsync --wsrep_sst_auth=$SUSER:$SPASS \
    --wsrep_node_address=$ADDR  \
    --log-error=$node2/node2.err \
    --socket=$node2/pxc-mysql.sock --log-output=none \
    --port=$RBASE2 --wsrep_slave_threads=2 > $node2/node2.err 2>&1 &

  for X in $(seq 0 ${PXC_START_TIMEOUT}); do
    sleep 1
    if ${DB_DIR}/bin/mysqladmin -uroot -S$node2/pxc-mysql.sock ping > /dev/null 2>&1; then
      echo 'Started PXC node2...'
      break
    fi
  done

  if [ $run_mid -eq 1 ]; then
    ${MID} --datadir=$node3  > ${DB_DIR}/startup_node3.err 2>&1 || exit 1;
  fi

  ${DB_DIR}/bin/mysqld $PXC_MYEXTRA --basedir=${DB_DIR} --datadir=$node3 \
    --innodb_autoinc_lock_mode=2 \
    --wsrep-provider=${DB_DIR}/lib/libgalera_smm.so \
    --wsrep_cluster_address=gcomm://$LADDR1,gcomm://$LADDR2 \
    --wsrep_node_incoming_address=$ADDR \
    --wsrep_provider_options=gmcast.listen_addr=tcp://$LADDR3 \
    --wsrep_sst_method=rsync --wsrep_sst_auth=$SUSER:$SPASS \
    --wsrep_node_address=$ADDR  \
    --log-error=$node3/node3.err \
    --socket=$node3/pxc-mysql.sock --log-output=none \
    --port=$RBASE3 --wsrep_slave_threads=2 > $node3/node3.err 2>&1 &

  for X in $(seq 0 ${PXC_START_TIMEOUT}); do
    sleep 1
    if ${DB_DIR}/bin/mysqladmin -uroot -S$node3/pxc-mysql.sock ping > /dev/null 2>&1; then
      ${DB_DIR}/bin/mysql -uroot -S$node1/pxc-mysql.sock -e "create database if not exists test" > /dev/null 2>&1
      sleep 2
      echo 'Started PXC node3...'
      break
    fi
  done

  if [ ${BENCH_SUITE} == "sysbench" ];then
    if [ $run_mid -eq 1 ]; then
      if [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "0.5" ]; then
        /usr/bin/sysbench --test=/usr/share/doc/sysbench/tests/db/parallel_prepare.lua --num-threads=${NUM_TABLES} --oltp-tables-count=${NUM_TABLES}  --oltp-table-size=${NUM_ROWS} --mysql-db=test --mysql-user=root    --db-driver=mysql --mysql-socket=${node1}/pxc-mysql.sock run > ${BIG_DIR}/sysbench_prepare.log 2>&1
      elif [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "1.0" ]; then
        sysbench /usr/share/sysbench/oltp_insert.lua --mysql-storage-engine=$MYSQL_STORAGE_ENGINE --rand-type=$RAND_TYPE  --threads=${NUM_TABLES} --tables=${NUM_TABLES}  --table-size=${NUM_ROWS} --mysql-db=test --mysql-user=root    --db-driver=mysql --mysql-socket=${node1}/pxc-mysql.sock prepare > $WORK_DIR/sysbench_prepare.log 2>&1
      fi
      timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${node1}/pxc-mysql.sock shutdown > /dev/null 2>&1
      timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${node2}/pxc-mysql.sock shutdown > /dev/null 2>&1
      timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${node3}/pxc-mysql.sock shutdown > /dev/null 2>&1
    fi
  fi
}

psmode_startup(){
  PXC_MYEXTRA=$1
  
  if [ "$(${DB_DIR}/bin/mysqld --version | grep -oe '5\.[567]' | head -n1)" == "5.7" ]; then
    MID="${DB_DIR}/bin/mysqld --no-defaults --initialize-insecure --basedir=${DB_DIR}"
  elif [ "$(${DB_DIR}/bin/mysqld --version | grep -oe '5\.[567]' | head -n1)" == "5.6" ]; then
    MID="${DB_DIR}/scripts/mysql_install_db --no-defaults --basedir=${DB_DIR}"
  fi

  if [ ${BENCH_SUITE} == "sysbench" ];then
    if [ $run_mid -eq 1 ]; then
      node1="${BIG_DIR}/sysbench_data_template/node1"
      if [ "$(${DB_DIR}/bin/mysqld --version | grep -oe '5\.[567]' | head -n1)" != "5.7" ]; then
        mkdir -p $node1
      fi
    else
      node1="${DB_DIR}/node1"
    fi
  else
    node1="${DB_DIR}/node1"
    if [ "$(${DB_DIR}/bin/mysqld --version | grep -oe '5\.[567]' | head -n1)" != "5.7" ]; then
      mkdir -p $node1
    fi
  fi
   
  echo 'Starting PXC nodes....'
  if [ $run_mid -eq 1 ]; then
    ${MID} --datadir=$node1  > ${DB_DIR}/startup_node1.err 2>&1 || exit 1;
  fi

  ${DB_DIR}/bin/mysqld --no-defaults --defaults-group-suffix=.1 \
    --basedir=${DB_DIR} --datadir=$node1 \
    --loose-debug-sync-timeout=600 --skip-performance-schema \
    --innodb_file_per_table $PXC_MYEXTRA --innodb_autoinc_lock_mode=2 --innodb_locks_unsafe_for_binlog=1 \
    --binlog-format=ROW --log-bin=mysql-bin  --gtid-mode=ON  --log-slave-updates --enforce-gtid-consistency \
    --innodb_flush_method=O_DIRECT \
    --core-file --loose-new --sql-mode=no_engine_substitution \
    --loose-innodb --secure-file-priv= --loose-innodb-status-file=1 \
    --log-error=$node1/node1.err \
    --socket=$node1/pxc-mysql.sock --log-output=none \
    --port=$RBASE1 --server-id=1  > $node1/node1.err 2>&1 &

  for X in $(seq 0 ${PXC_START_TIMEOUT}); do
    sleep 1
    if ${DB_DIR}/bin/mysqladmin -uroot -S$node1/pxc-mysql.sock ping > /dev/null 2>&1; then
      ${DB_DIR}/bin/mysql -uroot -S$node1/pxc-mysql.sock -e "create database if not exists test" > /dev/null 2>&1
      sleep 2
      echo 'Started PXC node1...'
      break
    fi
  done

  # Running sysbench
  echo "Running sysbench"
  if [ ${BENCH_SUITE} == "sysbench" ];then
    if [ $run_mid -eq 1 ]; then
      if [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "0.5" ]; then
        /usr/bin/sysbench --test=/usr/share/doc/sysbench/tests/db/parallel_prepare.lua --rand-type=$RAND_TYPE --num-threads=${NUM_TABLES} --oltp-tables-count=${NUM_TABLES}  --oltp-table-size=${NUM_ROWS} --mysql-db=test --mysql-user=root    --db-driver=mysql --mysql-socket=${node1}/pxc-mysql.sock run > ${BIG_DIR}/sysbench_prepare.log 2>&1
      elif [ "$(sysbench --version | cut -d ' ' -f2 | grep -oe '[0-9]\.[0-9]')" == "1.0" ]; then
        sysbench /usr/share/sysbench/oltp_insert.lua --mysql-storage-engine=$MYSQL_STORAGE_ENGINE --rand-type=$RAND_TYPE  --threads=${NUM_TABLES} --tables=${NUM_TABLES}  --table-size=${NUM_ROWS} --mysql-db=test --mysql-user=root    --db-driver=mysql --mysql-socket=${node1}/pxc-mysql.sock prepare > $WORK_DIR/sysbench_prepare.log 2>&1
      fi
      timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${node1}/pxc-mysql.sock shutdown > /dev/null 2>&1
    fi
  fi

}

if [ ${PS_MODE} -eq 1 ];then
  psmode_startup ${MYEXTRA}
else
  pxc_startup ${MYEXTRA}
fi
