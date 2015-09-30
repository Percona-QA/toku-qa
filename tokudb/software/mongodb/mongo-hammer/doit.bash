#!/bin/bash

if [ -z "$TARBALL" ]; then
    #export TARBALL=tokumx-1.0.0-rc.6-linux-x86_64
    export TARBALL=mongodb-linux-x86_64-2.2.3
fi
if [ -z "$MONGO_TYPE" ]; then
    #export MONGO_TYPE=tokumx
    export MONGO_TYPE=mongo
fi
if [ -z "$MONGO_DIR" ]; then
    echo "Need to set MONGO_DIR"
    exit 1
fi
if [ ! -d "$MONGO_DIR" ]; then
    echo "Need to create directory MONGO_DIR"
    exit 1
fi
if [ "$(ls -A $MONGO_DIR)" ]; then
    echo "$MONGO_DIR contains files, cannot run script"
    exit 1
fi
if [ -z "$MONGO_COMPRESSION" ]; then
    # lzma, quicklz, zlib, uncompressed
    export MONGO_COMPRESSION=zlib
fi
if [ -z "$MONGO_BASEMENT" ]; then
    # 131072, 65536
    export MONGO_BASEMENT=65536
fi

if [ -z "$BENCHMARK_NUMBER" ]; then
    export BENCHMARK_NUMBER=999
fi
if [ -z "$COMMIT_SYNC" ]; then
    export COMMIT_SYNC=0
fi


export PYTHONUNBUFFERED=1


RUN_TIME_SECONDS=1000000
IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[RUN_TIME_SECONDS/IOSTAT_INTERVAL+1]

export MINI_LOG_NAME=${MACHINE_NAME}-mongoHammer-${NUM_COLLECTIONS}-${NUM_DOCUMENTS_PER_COLLECTION}-${MONGO_TYPE}
    
if [ ${MONGO_TYPE} == "tokumx" ]; then
    if [ ${COMMIT_SYNC} == "1" ]; then
        LOG_NAME=${MINI_LOG_NAME}-${MONGO_COMPRESSION}-${MONGO_BASEMENT}-SYNC_COMMIT.log
    else
        LOG_NAME=${MINI_LOG_NAME}-${MONGO_COMPRESSION}-${MONGO_BASEMENT}-NOSYNC_COMMIT.log
    fi
else
    LOG_NAME=${MINI_LOG_NAME}.log
fi
    
export MONGO_LOG=${LOG_NAME}.mongolog
LOG_NAME_IOSTAT=${LOG_NAME}.iostat
    
rm -f $LOG_NAME
rm -f $BENCHMARK_TSV

echo "`date` | wiping existing data folder at ${MONGO_DATA_DIR}" | tee -a $LOG_NAME
mongo-clean

# unpack mongo files
echo "Creating mongo from ${TARBALL} in ${MONGO_DIR}"
pushd $MONGO_DIR
mkmon $TARBALL
popd

echo "`date` | starting the ${MONGO_TYPE} server at ${MONGO_DIR}" | tee -a $LOG_NAME
if [ ${MONGO_TYPE} == "tokumx" ]; then
    mongo-start-tokumx-fork
else
    mongo-start-pure-numa-fork
fi
    
mongo-is-up
echo "`date` | server is available" | tee -a $LOG_NAME

iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &

T="$(date +%s)"
python mongo_hammer.py | tee -a $LOG_NAME
echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | app duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

bkill
    
echo "" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
echo "Sizing Information" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
        
SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR} | tail -n 1 | cut -f1`
SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${MONGO_DATA_DIR} | tail -n 1 | cut -f1`
SIZE_MB=`echo "scale=2; ${SIZE_BYTES}/(1024*1024)" | bc `
SIZE_APPARENT_MB=`echo "scale=2; ${SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
echo "`date` | post-load sizing (SizeMB / ASizeMB) = ${SIZE_MB} / ${SIZE_APPARENT_MB}" | tee -a $LOG_NAME
