#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi

TOTAL_FILE_SIZE=50G
NUM_THREADS=8
# sync, async, fastmmap, slowmmap
FILE_IO_MODE=sync

cd $DB_DIR


sysbench --test=fileio --file-total-size=${TOTAL_FILE_SIZE} --file-test-mode=rndwr --max-time=18000 --max-requests=0 --num-threads=${NUM_THREADS} --rand-init=on --file-num=64 --file-io-mode=${FILE_IO_MODE} --file-extra-flags=direct --file-fsync-freq=0 --file-block-size=16384 --report-interval=10 prepare
sysbench --test=fileio --file-total-size=${TOTAL_FILE_SIZE} --file-test-mode=rndwr --max-time=18000 --max-requests=0 --num-threads=${NUM_THREADS} --rand-init=on --file-num=64 --file-io-mode=${FILE_IO_MODE} --file-extra-flags=direct --file-fsync-freq=0 --file-block-size=16384 --report-interval=10 run
sysbench --test=fileio --file-total-size=${TOTAL_FILE_SIZE} --file-test-mode=rndwr --max-time=18000 --max-requests=0 --num-threads=${NUM_THREADS} --rand-init=on --file-num=64 --file-io-mode=${FILE_IO_MODE} --file-extra-flags=direct --file-fsync-freq=0 --file-block-size=16384 --report-interval=10 cleanup
