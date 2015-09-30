#!/bin/bash

export MINI_LOG_NAME=${MACHINE_NAME}-apavlo-${MONGO_TYPE}
    
if [ ${MONGO_TYPE} == "tokumx" ]; then
    LOG_NAME=${MINI_LOG_NAME}-${MONGO_COMPRESSION}-${MONGO_BASEMENT}.log
else
    LOG_NAME=${MINI_LOG_NAME}.log
fi
    
export MONGO_LOG=${LOG_NAME}.mongolog
    
rm -f $LOG_NAME

echo "`date` | starting the ${MONGO_TYPE} server at ${MONGO_DIR}" | tee -a $LOG_NAME
if [ ${MONGO_TYPE} == "tokumx" ]; then
    mongo-start-tokumx-fork
else
    mongo-start-pure-numa-fork
fi
    
mongo-is-up
echo "`date` | server is available" | tee -a $LOG_NAME

# create the collection
T="$(date +%s)"
if [ ${MONGO_TYPE} == "tokumx" ]; then
    ${MONGO_DIR}/bin/mongo ${DB_NAME} --eval "db.runCommand({create: \"${COLLECTION_NAME}\", compression: \"${MONGO_COMPRESSION}\"})"
else
    ${MONGO_DIR}/bin/mongo ${DB_NAME} --eval "db.runCommand({create: \"${COLLECTION_NAME}\"})"
fi
echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | create collection duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

# run the load
T="$(date +%s)"
${MONGO_DIR}/bin/mongoimport -d ${DB_NAME} -c ${COLLECTION_NAME} --type csv --file ${BACKUP_DIR}/customers/andy-pavlo/peersnapshots-01.csv --headerline
echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

# create index 1
T="$(date +%s)"
if [ ${MONGO_TYPE} == "tokumx" ]; then
    ${MONGO_DIR}/bin/mongo ${DB_NAME} --eval "db.${COLLECTION_NAME}.ensureIndex({peer_id: 1, created: 1}, {background: false, compression: \"${MONGO_COMPRESSION}\"})"
else
    ${MONGO_DIR}/bin/mongo ${DB_NAME} --eval "db.${COLLECTION_NAME}.ensureIndex({peer_id: 1, created: 1}, {background: false})"
fi
echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | create index 1 duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

# create index 2
T="$(date +%s)"
if [ ${MONGO_TYPE} == "tokumx" ]; then
    ${MONGO_DIR}/bin/mongo ${DB_NAME} --eval "db.${COLLECTION_NAME}.ensureIndex({torrent_snapshot_id:1, created: 1}, {background: false, compression: \"${MONGO_COMPRESSION}\"})"
else
    ${MONGO_DIR}/bin/mongo ${DB_NAME} --eval "db.${COLLECTION_NAME}.ensureIndex({torrent_snapshot_id:1, created: 1}, {background: false})"
fi
echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | create index 2 duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

# create index 3
T="$(date +%s)"
if [ ${MONGO_TYPE} == "tokumx" ]; then
    ${MONGO_DIR}/bin/mongo ${DB_NAME} --eval "db.${COLLECTION_NAME}.ensureIndex({created: 1}, {background: false, compression: \"${MONGO_COMPRESSION}\"})"
else
    ${MONGO_DIR}/bin/mongo ${DB_NAME} --eval "db.${COLLECTION_NAME}.ensureIndex({created: 1}, {background: false})"
fi
echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | create index 3 duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME


T="$(date +%s)"
echo "`date` | shutting down the server" | tee -a $LOG_NAME
mongo-stop
mongo-is-down
T="$(($(date +%s)-T))"
printf "`date` | shutdown duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME
    
echo "" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
echo "Sizing Information" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
        
SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR} | tail -n 1 | cut -f1`
SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${MONGO_DATA_DIR} | tail -n 1 | cut -f1`
SIZE_MB=`echo "scale=2; ${SIZE_BYTES}/(1024*1024)" | bc `
SIZE_APPARENT_MB=`echo "scale=2; ${SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
echo "`date` | post-load sizing (SizeMB / ASizeMB) = ${SIZE_MB} / ${SIZE_APPARENT_MB}" | tee -a $LOG_NAME

if [ ${SCP_FILES} == "Y" ]; then
    DATE=`date +"%Y%m%d%H%M%S"`
    tarFileName="${MACHINE_NAME}-${BENCHMARK_NUMBER}-${DATE}-apavlo-${BENCH_ID}.tar.gz"

    tar czvf ${tarFileName} ${MACHINE_NAME}*
    scp ${tarFileName} ${SCP_TARGET}:~

    rm -f ${tarFileName}
    rm -f ${MACHINE_NAME}*
    rm -f ${MONGO_LOG}

    #movecores
fi
