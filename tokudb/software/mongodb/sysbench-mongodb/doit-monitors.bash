#!/bin/bash

# **************************************************
# catpure IO and MEMORY/CPU information
# **************************************************

RUN_TIME_SECONDS=1000000
IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[RUN_TIME_SECONDS/IOSTAT_INTERVAL+1]
CAPTURE_MEMORY_INTERVAL=5

LOG_NAME_IOSTAT=mongodb.iostat
LOG_NAME_MEMORY=mongodb.memory

rm -f $LOG_NAME_IOSTAT
rm -f $LOG_NAME_MEMORY

iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
capture-memory.bash ${RUN_TIME_SECONDS} ${CAPTURE_MEMORY_INTERVAL} ${LOG_NAME_MEMORY} mongod &

