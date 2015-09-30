#! /bin/bash

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


#export TARBALL=mongodb-linux-x86_64-2.6.4
#export MONGO_TYPE=mongo
export TARBALL=tokumx-e-2.0.0-linux-x86_64-main
export MONGO_TYPE=tokumx
#export TOKUMX_DEFAULT_COMPRESSION=zlib
#export TOKUMX_DEFAULT_COMPRESSION=lzma


export MONGO_LOG=${PWD}/${MACHINE_NAME}-benchmark-load.mongolog

dbName=test
collName=test

numRows=1000000
#numRows=1000000

#hostName=localhost
#hostPort=?
#userName=test
#userPass=test

inputFile=$BACKUP_DIR/pg-bench/${numRows}/sample.json
LOG_NAME=./${MACHINE_NAME}-benchmark.log
rm -f ${LOG_NAME}

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

echo "`date` | creating collection ${dbName}.${collName}" | tee -a $LOG_NAME
$MONGO_DIR/bin/mongo ${dbName} --eval "printjson(db.createCollection(\"${collName}\"))"
echo "`date` | creating index on 'name' for ${dbName}.${collName}" | tee -a $LOG_NAME
$MONGO_DIR/bin/mongo ${dbName} --eval "db.${collName}.ensureIndex({\"name\":1})"
echo "`date` | creating index on 'type' for ${dbName}.${collName}" | tee -a $LOG_NAME
$MONGO_DIR/bin/mongo ${dbName} --eval "db.${collName}.ensureIndex({\"type\":1})"
echo "`date` | creating index on 'brand' for ${dbName}.${collName}" | tee -a $LOG_NAME
$MONGO_DIR/bin/mongo ${dbName} --eval "db.${collName}.ensureIndex({\"brand\":1})"

#$MONGO_DIR/bin/mongoimport --host ${hostName} --db ${dbName} --username ${userName} --password ${userPass} \
#      --type json --port ${hostPort} --collection ${collName} < ${inputFile}

T="$(date +%s)"
echo "`date` | Running mongoimport" | tee -a $LOG_NAME
if [ ${MONGO_TYPE} == "mongo" ]; then ra-set 32; fi
$MONGO_DIR/bin/mongoimport --db ${dbName} --type json --collection ${collName} < ${inputFile}
if [ ${MONGO_TYPE} == "mongo" ]; then ra-set 256; fi
T="$(($(date +%s)-T))"
printf "`date` | complete loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

# calculate documents per second
rowsPerSecond=`echo "scale=2; (${numRows})/${T}" | bc `
printf "`date` | rows loaded per second = %'.1f\n" "${rowsPerSecond}" | tee -a $LOG_NAME

T="$(date +%s)"
echo "`date` | shutting down the server" | tee -a $LOG_NAME
mongo-stop
mongo-is-down
T="$(($(date +%s)-T))"
printf "`date` | shutdown duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

bkill

# calculate size
SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR} | tail -n 1 | cut -f1`
SIZE_MB=`echo "scale=2; ${SIZE_BYTES}/(1024*1024)" | bc `
echo "`date` | post-load sizing (MB) = ${SIZE_MB}" | tee -a $LOG_NAME
