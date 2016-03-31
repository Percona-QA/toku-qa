#!/bin/bash

if [ -z "$DB_DIR" ]; then
  echo "Need to set DB_DIR"
  exit 1
fi

if [ ! -z $1 ]; then
  if [ "$1" == "start-dirty" ];then
    start_dirty="--start-dirty"
  fi
fi

# PXC startup script.
pxc_startup(){
  PXC_MYEXTRA=$1
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
  
  if [ ${BENCH_SUITE} == "sysbench" ];then
    if [ -z $start_dirty ]; then
      node1="${BIG_DIR}/sysbench_data_template/node1"
      node2="${BIG_DIR}/sysbench_data_template/node2"
      node3="${BIG_DIR}/sysbench_data_template/node3"
      mkdir -p $node1 $node2 $node3
    else
      node1="${DB_DIR}/node1"
      node2="${DB_DIR}/node2"
      node3="${DB_DIR}/node3"
    fi
  else
    node1="${DB_DIR}/node1"
    node2="${DB_DIR}/node2"
    node3="${DB_DIR}/node3"
  fi
   
  echo 'Starting PXC nodes....'
  pushd ${DB_DIR}/mysql-test/
  
  set +e 
   perl mysql-test-run.pl \
      --start-and-exit $start_dirty \
      --port-base=$RBASE1 \
      --nowarnings \
      --vardir=$node1 \
      --mysqld=--skip-performance-schema  \
      --mysqld=--innodb_file_per_table \
      --mysqld=--binlog-format=ROW \
      --mysqld=--wsrep-slave-threads=2 \
      --mysqld=--innodb_autoinc_lock_mode=2 \
      --mysqld=--innodb_locks_unsafe_for_binlog=1 \
      --mysqld=--wsrep-provider=${DB_DIR}/lib/libgalera_smm.so \
      --mysqld=--wsrep_cluster_address=gcomm:// \
      --mysqld=--wsrep_sst_receive_address=$RADDR1 \
      --mysqld=--wsrep_node_incoming_address=$ADDR \
      --mysqld=--wsrep_provider_options="gmcast.listen_addr=tcp://$LADDR1" \
      --mysqld=--wsrep_sst_method=rsync \
      --mysqld=--wsrep_sst_auth=$SUSER:$SPASS \
      --mysqld=--wsrep_node_address=$ADDR \
      --mysqld=--innodb_flush_method=O_DIRECT \
      --mysqld=--core-file \
      --mysqld=--loose-new \
      --mysqld=--sql-mode=no_engine_substitution \
      --mysqld=--loose-innodb \
      --mysqld=--secure-file-priv= \
      --mysqld=--loose-innodb-status-file=1 \
      --mysqld=--skip-name-resolve \
      --mysqld=--socket=$node1/pxc-mysql.sock \
      --mysqld=--log-error=$node1/node1.err \
      --mysqld=--log-output=none $PXC_MYEXTRA \
     1st > $node1/node1.err 2>&1 
  set -e
  set +e 
   perl mysql-test-run.pl \
      --start-and-exit $start_dirty \
      --port-base=$RBASE2 \
      --nowarnings \
      --vardir=$node2 \
      --mysqld=--skip-performance-schema  \
      --mysqld=--innodb_file_per_table  \
      --mysqld=--binlog-format=ROW \
      --mysqld=--wsrep-slave-threads=2 \
      --mysqld=--innodb_autoinc_lock_mode=2 \
      --mysqld=--innodb_locks_unsafe_for_binlog=1 \
      --mysqld=--wsrep-provider=${DB_DIR}/lib/libgalera_smm.so \
      --mysqld=--wsrep_cluster_address=gcomm://$LADDR1 \
      --mysqld=--wsrep_sst_receive_address=$RADDR2 \
      --mysqld=--wsrep_node_incoming_address=$ADDR \
      --mysqld=--wsrep_provider_options="gmcast.listen_addr=tcp://$LADDR2" \
      --mysqld=--wsrep_sst_method=rsync \
      --mysqld=--wsrep_sst_auth=$SUSER:$SPASS \
      --mysqld=--wsrep_node_address=$ADDR \
      --mysqld=--innodb_flush_method=O_DIRECT \
      --mysqld=--core-file \
      --mysqld=--loose-new \
      --mysqld=--sql-mode=no_engine_substitution \
      --mysqld=--loose-innodb \
      --mysqld=--secure-file-priv= \
      --mysqld=--loose-innodb-status-file=1 \
      --mysqld=--skip-name-resolve \
      --mysqld=--socket=$node2/pxc-mysql.sock \
      --mysqld=--log-error=$node2/node2.err \
      --mysqld=--log-output=none $PXC_MYEXTRA  \
     1st > $node2/node2.err 2>&1
  set -e
  set +e 
   perl mysql-test-run.pl \
      --start-and-exit $start_dirty \
      --port-base=$RBASE3 \
      --nowarnings \
      --vardir=$node3 \
      --mysqld=--skip-performance-schema  \
      --mysqld=--innodb_file_per_table  \
      --mysqld=--binlog-format=ROW \
      --mysqld=--wsrep-slave-threads=2 \
      --mysqld=--innodb_autoinc_lock_mode=2 \
      --mysqld=--innodb_locks_unsafe_for_binlog=1 \
      --mysqld=--wsrep-provider=${DB_DIR}/lib/libgalera_smm.so \
      --mysqld=--wsrep_cluster_address=gcomm://$LADDR1,$LADDR2 \
      --mysqld=--wsrep_sst_receive_address=$RADDR3 \
      --mysqld=--wsrep_node_incoming_address=$ADDR \
      --mysqld=--wsrep_provider_options="gmcast.listen_addr=tcp://$LADDR3" \
      --mysqld=--wsrep_sst_method=rsync \
      --mysqld=--wsrep_sst_auth=$SUSER:$SPASS \
      --mysqld=--wsrep_node_address=$ADDR \
      --mysqld=--innodb_flush_method=O_DIRECT \
      --mysqld=--core-file \
      --mysqld=--loose-new \
      --mysqld=--sql-mode=no_engine_substitution \
      --mysqld=--loose-innodb \
      --mysqld=--secure-file-priv= \
      --mysqld=--loose-innodb-status-file=1 \
      --mysqld=--skip-name-resolve \
      --mysqld=--socket=$node3/pxc-mysql.sock \
      --mysqld=--log-error=$node3/node3.err \
      --mysqld=--log-output=none $PXC_MYEXTRA \
     1st > $node3/node3.err 2>&1
   set -e
  popd
  if $DB_DIR/bin/mysqladmin -uroot --socket=${node1}/pxc-mysql.sock ping > /dev/null 2>&1; then
   echo 'Started PXC node1...'
  else
   echo 'PXC node1 not started...'
  fi
  if $DB_DIR/bin/mysqladmin -uroot --socket=${node2}/pxc-mysql.sock ping > /dev/null 2>&1; then
   echo 'Started PXC node2...'
  else
   echo 'PXC node2 not started...'
  fi
  if $DB_DIR/bin/mysqladmin -uroot --socket=${node3}/pxc-mysql.sock ping > /dev/null 2>&1; then
   echo 'Started PXC node3...'
  else
   echo 'PXC node3 not started...'
  fi
  if [ ${BENCH_SUITE} == "sysbench" ];then
    if [ -z $start_dirty ]; then
      /usr/bin/sysbench --test=/usr/share/doc/sysbench/tests/db/parallel_prepare.lua --num-threads=${NUM_TABLES} --oltp-tables-count=${NUM_TABLES}  --oltp-table-size=${NUM_ROWS} --mysql-db=test --mysql-user=root    --db-driver=mysql --mysql-socket=${node1}/pxc-mysql.sock run > ${BIG_DIR}/sysbench_prepare.log 2>&1
      timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${node1}/pxc-mysql.sock shutdown > /dev/null 2>&1
      timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${node2}/pxc-mysql.sock shutdown > /dev/null 2>&1
      timeout --signal=9 20s ${DB_DIR}/bin/mysqladmin -uroot --socket=${node3}/pxc-mysql.sock shutdown > /dev/null 2>&1
    fi
  fi
}

pxc_startup ${MYEXTRA}
