#!/bin/bash

if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    echo "Need to set MYSQL_STORAGE_ENGINE"
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
if [ -z "$NUM_WAREHOUSES" ]; then
    echo "Need to set NUM_WAREHOUSES"
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
if [ -z "$NUM_WAREHOUSES" ]; then
    echo "Need to set NUM_WAREHOUSES"
    exit 1
fi
if [ -z "$STEP" ]; then
    echo "Need to set STEP"
    exit 1
fi

# compile custom tpcc
pushd ../tpcc-mysql/src
make
popd

LOG_BENCHMARK_NAME=tpcc
SERVER_NAME=l

LOG_NAME=${MACHINE_NAME}-${MYSQL_NAME}-${MYSQL_VERSION}-${MYSQL_STORAGE_ENGINE}-${BENCH_ID}-${LOG_BENCHMARK_NAME}-${NUM_WAREHOUSES}-${STEP}.txt

rm -f ${LOG_NAME}

# Get time as a UNIX timestamp (seconds elapsed since Jan 1, 1970 0:00 UTC)
T="$(date +%s)"

echo "`date` : drop database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} -f drop ${MYSQL_DATABASE}

echo "`date` : create database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} create ${MYSQL_DATABASE}

if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "`date` : create innodb tables" | tee -a $LOG_NAME
    if [ ${INNODB_COMPRESSION} == "Y" ]; then
        echo "`date` : innodb compression enabled, key_block_size=${INNODB_KEY_BLOCK_SIZE}" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < fastload/create_schema_${MYSQL_STORAGE_ENGINE}_${INNODB_KEY_BLOCK_SIZE}.sql
    else
        echo "`date` : innodb compression disabled" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < fastload/create_schema_${MYSQL_STORAGE_ENGINE}.sql
    fi
else
    echo "`date` : create tokudb tables and indexes" | tee -a $LOG_NAME
    $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < fastload/create_schema_${MYSQL_STORAGE_ENGINE}.sql
fi

# **********************
# single-threaded loader
# **********************
#../tpcc-mysql/tpcc_load ${SERVER_NAME} ${MYSQL_DATABASE} ${MYSQL_USER} "${MYSQL_PASSWORD}" ${NUM_WAREHOUSES}


# **********************
# multithreaded loader
# **********************
../tpcc-mysql/tpcc_load ${SERVER_NAME} ${MYSQL_DATABASE} ${MYSQL_USER} "${MYSQL_PASSWORD}" ${NUM_WAREHOUSES} 1 1 ${NUM_WAREHOUSES} >> 1.out &
x=1
while [ $x -le ${NUM_WAREHOUSES} ]; do
    echo $x $(( $x + $STEP - 1 ))
    ../tpcc-mysql/tpcc_load ${SERVER_NAME} ${MYSQL_DATABASE} ${MYSQL_USER} "${MYSQL_PASSWORD}" ${NUM_WAREHOUSES} 2 $x $(( $x + $STEP - 1 ))  >> 2_$x.out &
    ../tpcc-mysql/tpcc_load ${SERVER_NAME} ${MYSQL_DATABASE} ${MYSQL_USER} "${MYSQL_PASSWORD}" ${NUM_WAREHOUSES} 3 $x $(( $x + $STEP - 1 ))  >> 3_$x.out &
    ../tpcc-mysql/tpcc_load ${SERVER_NAME} ${MYSQL_DATABASE} ${MYSQL_USER} "${MYSQL_PASSWORD}" ${NUM_WAREHOUSES} 4 $x $(( $x + $STEP - 1 ))  >> 4_$x.out &
    x=$(( $x + $STEP ))
done

wait

T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "`date` : creating innodb indexes" | tee -a $LOG_NAME
    $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < fastload/innodb_add_idx.sql
    
    if [ ${INNODB_FK} == "Y" ]; then
        echo "`date` : innodb FK support enabled, adding foreign keys" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < fastload/innodb_add_fkey.sql
    else
        echo "`date` : innodb FK support disabled, adding as indexes" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < fastload/innodb_add_fkey_as_idx.sql
    fi
    echo "`date` : finished creating innodb indexes" | tee -a $LOG_NAME
fi

echo "`date` | loader checking TokuDB sizing = `du -ch ${DB_DIR}/data/*.tokudb            | tail -n 1`" | tee -a $LOG_NAME
echo "`date` | loader checking InnoDB sizing = `du -ch ${DB_DIR}/data/${MYSQL_DATABASE}   | tail -n 1`" | tee -a $LOG_NAME
