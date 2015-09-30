#!/bin/bash

if [ $# -eq 0 ]; then
  echo "usage: capture-iostat-datasize.bash <check-frequency-seconds> <log-file-name> <iibench-log-name>"
  exit 1
fi

# time to wait between checks
CHECK_FREQUENCY_SECONDS=${1}

# name of log file to create
LOG_NAME=${2}

# name of iibench log file to parse for current rows inserted
IIBENCH_LOG_NAME=${3}

PROCESS_NAME=mongod

# kill existing log file if it exists
rm -f ${LOG_NAME}

if [ -z "$MONGO_DATA_DIR" ]; then
    echo "Need to set MONGO_DATA_DIR" >> ${LOG_NAME}
    exit 1
fi

if [ -z "$MONGO_TYPE" ]; then
    echo "Need to set MONGO_TYPE" >> ${LOG_NAME}
    exit 1
fi

if [ -z "$DATA_DEVICE" ]; then
    echo "Need to set DATA_DEVICE" >> ${LOG_NAME}
    exit 1
fi

START_TIME="$(date +%s)"

while true; do
    # parse iostat output for ${DATA_DEVICE}, exit if not found
    DEVICE_LINE=`iostat -dxmy ${CHECK_FREQUENCY_SECONDS} 1 | grep ${DATA_DEVICE}`
    if [ "$?" -ne "0" ]; then
        echo "*** ERROR *** : Unable to locate device ${DATA_DEVICE} in iostat output, exiting..." >> ${LOG_NAME}
        exit 1
    fi
    
    ELAPSED_SECONDS="$(($(date +%s)-START_TIME))"
    
    # get process information (RSS, VMSIZE, CPU)
    CHECK_PID=`pgrep -u $USER -x ${PROCESS_NAME}`
    PROCESS_INFO=`ps -o rss,vsz,pcpu ${CHECK_PID} | tail -n 1`
    PROCESS_RSS_KB=`echo ${PROCESS_INFO} | cut -f1 -d' '`
    PROCESS_RSS_MB=`echo "scale=2; ${PROCESS_RSS_KB}/1024" | bc `
    PROCESS_VSZ_KB=`echo ${PROCESS_INFO} | cut -f2 -d' '`
    PROCESS_VSZ_MB=`echo "scale=2; ${PROCESS_VSZ_KB}/1024" | bc `
    PROCESS_CPU=`echo ${PROCESS_INFO} | cut -f3 -d' '`

    # parse ${IIBENCH_LOG_NAME} for most current row count, exit if not found
    CURRENT_BENCHMARK_INFO=`tail -n1 ${IIBENCH_LOG_NAME}`
    if [ "$?" -ne "0" ]; then
        echo "*** ERROR *** : Unable to locate current rows in ${IIBENCH_LOG_NAME}, exiting..." >> ${LOG_NAME}
        exit 1
    fi
    CURRENT_ROWS=`echo ${CURRENT_BENCHMARK_INFO} | cut -f1`

    # get the size of the entire data folder    
    DATA_FOLDER_SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR} | tail -n 1 | cut -f1`
    DATA_FOLDER_SIZE_MB=`echo "scale=2; ${DATA_FOLDER_SIZE_BYTES}/(1024*1024)" | bc `

    if [ ${MONGO_TYPE} == "tokumx" ]; then
        # get the size of the data files in the data folder
        DATA_SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR}/*.tokumx --exclude='local_*' | tail -n 1 | cut -f1`
        DATA_SIZE_MB=`echo "scale=2; ${DATA_SIZE_BYTES}/(1024*1024)" | bc `
        
        # get the size of the log files in the data folder
        LOG_SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR}/*.tokulog* | tail -n 1 | cut -f1`
        LOG_SIZE_MB=`echo "scale=2; ${LOG_SIZE_BYTES}/(1024*1024)" | bc `

        # get the size of the local database (oplog) files in the data folder
        LOCAL_DATABASE_SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR}/local_* | tail -n 1 | cut -f1`
        LOCAL_DATABASE_SIZE_MB=`echo "scale=2; ${LOCAL_DATABASE_SIZE_BYTES}/(1024*1024)" | bc `
    elif [ ${MONGO_TYPE} == "mxse" ]; then
        # get the size of the data files in the data folder
        DATA_SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR}/*.tokuft --exclude='local_*' | tail -n 1 | cut -f1`
        DATA_SIZE_MB=`echo "scale=2; ${DATA_SIZE_BYTES}/(1024*1024)" | bc `
        
        # get the size of the log files in the data folder
        LOG_SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR}/*.tokulog* | tail -n 1 | cut -f1`
        LOG_SIZE_MB=`echo "scale=2; ${LOG_SIZE_BYTES}/(1024*1024)" | bc `

        # get the size of the local database (oplog) files in the data folder
        LOCAL_DATABASE_SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR}/local_* | tail -n 1 | cut -f1`
        LOCAL_DATABASE_SIZE_MB=`echo "scale=2; ${LOCAL_DATABASE_SIZE_BYTES}/(1024*1024)" | bc `
    else
        # get the size of the data files in the data folder
        DATA_SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR} --exclude='journal/*' --exclude='local.*' | tail -n 1 | cut -f1`
        DATA_SIZE_MB=`echo "scale=2; ${DATA_SIZE_BYTES}/(1024*1024)" | bc `
        
        # get the size of the log files in the data folder
        LOG_SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR}/journal/* | tail -n 1 | cut -f1`
        LOG_SIZE_MB=`echo "scale=2; ${LOG_SIZE_BYTES}/(1024*1024)" | bc `
        
        # get the size of the local database (oplog) files in the data folder
        LOCAL_DATABASE_SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR}/local.* | tail -n 1 | cut -f1`
        LOCAL_DATABASE_SIZE_MB=`echo "scale=2; ${LOCAL_DATABASE_SIZE_BYTES}/(1024*1024)" | bc `
    fi

    # write out single unified line, with number of rows first, stripping out all excess whitespace
    CLEAN_OUTPUT=$(echo ${ELAPSED_SECONDS} =IIBENCH= ${CURRENT_BENCHMARK_INFO} =IOSTAT= ${DEVICE_LINE} =DU= ${DATA_FOLDER_SIZE_MB} ${DATA_SIZE_MB} ${LOG_SIZE_MB} ${LOCAL_DATABASE_SIZE_MB} =PROCESS= ${PROCESS_RSS_MB} ${PROCESS_VSZ_MB} ${PROCESS_CPU})
    echo "${CLEAN_OUTPUT}" >> ${LOG_NAME}
done
