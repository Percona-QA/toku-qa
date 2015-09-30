#!/bin/bash

if [ $# -eq 0 ]; then
  echo "usage: mysql-capture-iostat-commits.bash <check-frequency-seconds> <log-file-name>"
  exit 1
fi

# time to wait between checks
CHECK_FREQUENCY_SECONDS=${1}

# name of log file to create
LOG_NAME=${2}

PROCESS_NAME=mysqld

# kill existing log file if it exists
rm -f ${LOG_NAME}

if [ -z "$DATA_DEVICE" ]; then
    echo "Need to set DATA_DEVICE" >> ${LOG_NAME}
    exit 1
fi

START_TIME="$(date +%s)"
lastCommits=0

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
    
    tempFile=/tmp/iostatcommits.txt
    
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "select * from information_schema.global_status where variable_name like 'COM_COMMIT'" > ${tempFile}
    thisCommits=`grep COM_COMMIT ${tempFile} | awk '{print $2}'`
    commitsPerSecond=`echo "scale=1; (${thisCommits}-${lastCommits})/${CHECK_FREQUENCY_SECONDS}" | bc `
    lastCommits=${thisCommits}
    printf "`date +%T` |  %7.1f\n" "$commitsPerSecond"

    # write out single unified line, with number of rows first, stripping out all excess whitespace
    CLEAN_OUTPUT=$(echo ${ELAPSED_SECONDS} =CPS= ${commitsPerSecond} =IOSTAT= ${DEVICE_LINE} =PROCESS= ${PROCESS_RSS_MB} ${PROCESS_VSZ_MB} ${PROCESS_CPU})
    echo "${CLEAN_OUTPUT}" >> ${LOG_NAME}
done
