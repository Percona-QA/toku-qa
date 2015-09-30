#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ -z "$MYSQL_SOCKET" ]; then
    echo "Need to set MYSQL_SOCKET"
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

MYSQL_SOCKET=$MYSQL_SOCKET

MYSQL_DATABASE=sbtest
MYSQL_USER=root

NUM_TABLES=$1
deleteFinalBackup=Y

# remove the last backup since it doesn't finish before the database is shutdown
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

    pushd ${DB_DIR}
    
    # stop mysql if it is currently running
    mstop
    
    # start using the given data directory
    mstart-backup ${backupDir}
    
    popd
    
    ./verify.bash ${NUM_TABLES} ${VERIFY_LOG_NAME}
done

mstop