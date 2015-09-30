#!/bin/bash

if [ -z "$MONGO_DIR" ]; then
    echo "Need to set MONGO_DIR"
    exit 1
fi
if [ -z "$MONGO_TYPE" ]; then
    echo "Need to set MONGO_TYPE"
    exit 1
fi
if [ -z "$HOT_BACKUP_DIR" ]; then
    echo "Need to set HOT_BACKUP_DIR"
    exit 1
fi
if [ -z "$VERIFY_LOG_NAME" ]; then
    echo "Need to set VERIFY_LOG_NAME"
    exit 1
fi
if [ -z "$NUM_COLLECTIONS" ]; then
    echo "Need to set NUM_COLLECTIONS"
    exit 1
fi

# start using the given data directory
export MONGO_LOG=${MACHINE_NAME}-validation.mongolog



# verify that the source database is solid
echo "" | tee -a ${VERIFY_LOG_NAME}
echo "" | tee -a ${VERIFY_LOG_NAME}
echo "--------------------------------------------------------------------------------------" | tee -a ${VERIFY_LOG_NAME}
echo "--------------------------------------------------------------------------------------" | tee -a ${VERIFY_LOG_NAME}
echo "--------------------------------------------------------------------------------------" | tee -a ${VERIFY_LOG_NAME}
echo "checking SOURCE directory" | tee -a ${VERIFY_LOG_NAME}

# stop mongod if it is currently running
mongo-stop
    
echo "`date` | starting the ${MONGO_TYPE} server at ${MONGO_DIR}" | tee -a ${VERIFY_LOG_NAME}
if [ ${MONGO_TYPE} == "tokumx" ]; then
    mongo-start-tokumx-fork
else
    mongo-start-pure-numa-fork
fi
    
mongo-is-up 30
echo "`date` | server is available (or not)" | tee -a ${VERIFY_LOG_NAME}

echo "`date` | checking admin database" | tee -a ${VERIFY_LOG_NAME}
echo "**************************************************************************************************" | tee -a ${VERIFY_LOG_NAME}
$MONGO_DIR/bin/mongo admin --eval "printjson(db.runCommand('dbhash').md5)" | tee -a ${VERIFY_LOG_NAME}
echo "`date` | checking ${DB_NAME} database" | tee -a ${VERIFY_LOG_NAME}
echo "**************************************************************************************************" | tee -a ${VERIFY_LOG_NAME}
$MONGO_DIR/bin/mongo ${DB_NAME} --eval "printjson(db.runCommand('dbhash').md5)" | tee -a ${VERIFY_LOG_NAME}
echo "**************************************************************************************************" | tee -a ${VERIFY_LOG_NAME}

./verify.bash
# END - verify that the source database is solid



deleteFinalBackup=Y

# remove the last backup since it might not finish before the database is shutdown
if [ ${deleteFinalBackup} == "Y" ] ; then
    numBackupDirs=0
    deleteBackupDir=""

    for backupDir in ${HOT_BACKUP_DIR}/* ; do
        let numBackupDirs=numBackupDirs+1
        deleteBackupDir=${backupDir}
    done

    if ! [ ${numBackupDirs} == 0 ] ; then
        # we have a backup directory to kill
        echo "deleteting backup directory ${deleteBackupDir}" | tee -a ${VERIFY_LOG_NAME}
        rm -rf ${deleteBackupDir}
    fi
fi

for backupDir in ${HOT_BACKUP_DIR}/* ; do
    if [ -d "${backupDir}" ]; then
        echo "" | tee -a ${VERIFY_LOG_NAME}
        echo "" | tee -a ${VERIFY_LOG_NAME}
        echo "--------------------------------------------------------------------------------------" | tee -a ${VERIFY_LOG_NAME}
        echo "--------------------------------------------------------------------------------------" | tee -a ${VERIFY_LOG_NAME}
        echo "--------------------------------------------------------------------------------------" | tee -a ${VERIFY_LOG_NAME}
        echo "checking backup directory : ${backupDir}" | tee -a ${VERIFY_LOG_NAME}
    fi

    # startup backup database
    if [ ${MULTI_DIR} == "N" ]; then
        export MONGO_DATA_DIR=${backupDir}
    else
        export MONGO_LOG_DIR=${backupDir}/log
        export MONGO_DATA_DIR=${backupDir}/data
    fi

    # stop mongod if it is currently running
    mongo-stop
    
    echo "`date` | starting the ${MONGO_TYPE} server at ${MONGO_DIR}" | tee -a ${VERIFY_LOG_NAME}
    if [ ${MONGO_TYPE} == "tokumx" ]; then
        mongo-start-tokumx-fork
    else
        mongo-start-pure-numa-fork
    fi
    
    mongo-is-up 30
    echo "`date` | server is available (or not)" | tee -a ${VERIFY_LOG_NAME}

    echo "`date` | checking admin database" | tee -a ${VERIFY_LOG_NAME}
    echo "**************************************************************************************************" | tee -a ${VERIFY_LOG_NAME}
    $MONGO_DIR/bin/mongo admin --eval "printjson(db.runCommand('dbhash').md5)" | tee -a ${VERIFY_LOG_NAME}
    echo "`date` | checking ${DB_NAME} database" | tee -a ${VERIFY_LOG_NAME}
    echo "**************************************************************************************************" | tee -a ${VERIFY_LOG_NAME}
    $MONGO_DIR/bin/mongo ${DB_NAME} --eval "printjson(db.runCommand('dbhash').md5)" | tee -a ${VERIFY_LOG_NAME}
    echo "**************************************************************************************************" | tee -a ${VERIFY_LOG_NAME}

    ./verify.bash
done

echo "`date` | shutting down the server" | tee -a ${VERIFY_LOG_NAME}
mongo-stop
mongo-is-down
