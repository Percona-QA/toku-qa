#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi
if [ -z "$MYSQL_PORT" ]; then
    echo "Need to set MYSQL_PORT"
    exit 1
fi


export TARBALLS=""

export MYSQL_STORAGE_ENGINE=tokudb
export TARBALLS="${TARBALLS} blank-custom-tokudb-snappy"

export NUM_ROWS_PER_TABLE=50000000
export NUM_TABLES=1
export NUM_LOADER_THREADS=1
export TOKUDB_READ_BLOCK_SIZE=64K
export DIRECTIO=N
export NUM_INSERTS_PER_FEEDBACK=-1
export NUM_SECONDS_PER_FEEDBACK=10
export TOKUDB_DIRECTIO_CACHE=1G
export INNODB_CACHE=1G
export NUM_DOCUMENTS_PER_INSERT=1000
export MAX_TPS=999999999

export MYSQL_DATABASE=sbtest
export MYSQL_USER=root
export DB_NAME=sbtest

for TARBALL in $TARBALLS; do
#    for compressionType in snappy ; do
    for compressionType in uncompressed snappy quicklz zlib lzma ; do
        export TOKUDB_COMPRESSION=${compressionType}
        export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
    
        if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
            export LOG_NAME=sysbench-java-load-${TARBALL}.log
            rm -f $LOG_NAME
        else
            export LOG_NAME=sysbench-java-load-${TARBALL}-${TOKUDB_COMPRESSION}.log
            rm -f $LOG_NAME
        fi
    
        export BENCHMARK_TSV=${LOG_NAME}.tsv
    
        echo "Creating database from ${TARBALL} in ${DB_DIR}"
        pushd $DB_DIR
        mkdb-quiet $TARBALL
        popd
    
        echo "Configuring my.cnf and starting database"
        pushd $DB_DIR
        if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
            if [ -z "$INNODB_CACHE" ]; then
                echo "Need to set INNODB_CACHE"
                exit 1
            fi
            if [ ${DIRECTIO} == "N" ]; then
                echo "innodb_flush_method=O_DSYNC" >> my.cnf
            fi
            echo "innodb_buffer_pool_size=${INNODB_CACHE}" >> my.cnf
        elif [ ${MYSQL_STORAGE_ENGINE} == "myisam" ]; then
            echo "key_buffer_size=8G" >> my.cnf
        #    echo "table_open_cache=2048" >> my.cnf
        else
            echo "tokudb_read_block_size=${TOKUDB_READ_BLOCK_SIZE}" >> my.cnf
            echo "tokudb_row_format=${TOKUDB_ROW_FORMAT}" >> my.cnf
            echo "tokudb_cache_size=${TOKUDB_DIRECTIO_CACHE}" >> my.cnf
            echo "tokudb_prelock_empty=off" >> my.cnf
            if [ ${DIRECTIO} == "Y" ]; then
                echo "tokudb_directio=1" >> my.cnf
            fi
        fi
        echo "max_connections=2048" >> my.cnf
        mstart
        popd
    
        # create database and tables
        echo "`date` | drop database" | tee -a $LOG_NAME
        $DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} -f drop ${MYSQL_DATABASE}
        
        echo "`date` | create database" | tee -a $LOG_NAME
        $DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} create ${MYSQL_DATABASE}
        
        echo "`date` | creating table sbtest1" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < create_schema_$MYSQL_STORAGE_ENGINE.sql
        
        echo "`date` | dropping secondary index k" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} -e "drop index k on sbtest1;"
        
        TABLE_NUM=2
        while [ ${TABLE_NUM} -le ${NUM_TABLES} ]; do
            thisTable=sbtest${TABLE_NUM}
            echo "`date` | creating table ${thisTable}" | tee -a $LOG_NAME
            $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "create table ${thisTable} like sbtest1;"
            let TABLE_NUM=TABLE_NUM+1
        done

        SHOW_ENGINE_STATUS_INTERVAL=15
        LOG_NAME_ENGINE_STATUS=${LOG_NAME}.load.engine_status
        capture-tokustat.bash $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS &
    
        echo "Loading Data"
        ant clean default
        T="$(date +%s)"
        ant load | tee -a $LOG_NAME
        echo "" | tee -a $LOG_NAME
        T="$(($(date +%s)-T))"
        printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME
        
        pkill -f capture-tokustat.bash
    
        # calculate rows per second
        ROWS_PER_SECOND=`echo "scale=2; (${NUM_ROWS_PER_TABLE}*${NUM_TABLES})/${T}" | bc `
        printf "`date` | rows loaded per second = %'.1f\n" "${ROWS_PER_SECOND}" | tee -a $LOG_NAME
    
        T="$(date +%s)"
        echo "`date` | Stopping database" | tee -a $LOG_NAME
        mstop
        echo "" | tee -a $LOG_NAME
        T="$(($(date +%s)-T))"
        printf "`date` | shutdown duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME
    
        echo "" | tee -a $LOG_NAME
        echo "-------------------------------" | tee -a $LOG_NAME
        echo "Sizing Information" | tee -a $LOG_NAME
        echo "-------------------------------" | tee -a $LOG_NAME
    
        if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
            INNODB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/${MYSQL_DATABASE}*/*.ibd | tail -n 1 | cut -f1`
            INNODB_SIZE_MB=`echo "scale=2; ${INNODB_SIZE_BYTES}/(1024*1024)" | bc `
            echo "`date` | loader InnoDB sizing = ${INNODB_SIZE_MB} MB" | tee -a $LOG_NAME
        else
            TOKUDB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
            TOKUDB_SIZE_MB=`echo "scale=2; ${TOKUDB_SIZE_BYTES}/(1024*1024)" | bc `
            echo "`date` | loader TokuDB sizing = ${TOKUDB_SIZE_MB} MB" | tee -a $LOG_NAME
        fi
        
        echo "Restarting Database"
        pushd $DB_DIR
        mstart
        popd

        SHOW_ENGINE_STATUS_INTERVAL=15
        LOG_NAME_ENGINE_STATUS=${LOG_NAME}.query.engine_status
        capture-tokustat.bash $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS &

        T="$(date +%s)"
        echo "`date` | Starting full table scan" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "select count(*) from sbtest1;"
        echo "" | tee -a $LOG_NAME
        T="$(($(date +%s)-T))"
        printf "`date` | full table scan duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

        sleep $SHOW_ENGINE_STATUS_INTERVAL
        sleep $SHOW_ENGINE_STATUS_INTERVAL
        pkill -f capture-tokustat.bash

        T="$(date +%s)"
        echo "`date` | Stopping database" | tee -a $LOG_NAME
        mstop
        echo "" | tee -a $LOG_NAME
        T="$(($(date +%s)-T))"
        printf "`date` | shutdown duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME
    done 
done
