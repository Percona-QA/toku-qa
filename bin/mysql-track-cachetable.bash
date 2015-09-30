#!/bin/bash

# wait between checks
WAIT_TIME_SECONDS=$1

tempFile=/tmp/mysql-track-cachetable.txt

headerLineEvery=20
headerLineLast=25

while true ; do
    #currentInfo=`$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} --password=${MYSQL_PASSWORD} ext`
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "select * from information_schema.global_status where variable_name like '%CACHETABLE_SIZE%' or variable_name like '%CHECKPOINT%'" > ${tempFile}
    #echo ${currentInfo}
    #cat ${tempFile}
    sizeCachepressure=`grep TOKUDB_CACHETABLE_SIZE_CACHEPRESSURE ${tempFile} | awk '{print $2}'`
    sizeCurrent=`grep TOKUDB_CACHETABLE_SIZE_CURRENT ${tempFile} | awk '{print $2}'`
    sizeCloned=`grep TOKUDB_CACHETABLE_SIZE_CLONED ${tempFile} | awk '{print $2}'`
    sizeLeaf=`grep TOKUDB_CACHETABLE_SIZE_LEAF ${tempFile} | awk '{print $2}'`
    sizeNonleaf=`grep TOKUDB_CACHETABLE_SIZE_NONLEAF ${tempFile} | awk '{print $2}'`
    sizeRollback=`grep TOKUDB_CACHETABLE_SIZE_ROLLBACK ${tempFile} | awk '{print $2}'`
    sizeWriting=`grep TOKUDB_CACHETABLE_SIZE_WRITING ${tempFile} | awk '{print $2}'`
    checkpointDurationLast=`grep TOKUDB_CHECKPOINT_DURATION_LAST ${tempFile} | awk '{print $2}'`
    checkpointDuration=`grep -P 'TOKUDB_CHECKPOINT_DURATION\t' ${tempFile} | awk '{print $2}'`
    checkpointTaken=`grep TOKUDB_CHECKPOINT_TAKEN ${tempFile} | awk '{print $2}'`
    
    cachepressureMB=`echo "scale=0; ${sizeCachepressure}/(1024*1024)" | bc `
    currentMB=`echo "scale=0; ${sizeCurrent}/(1024*1024)" | bc `
    clonedMB=`echo "scale=0; ${sizeCloned}/(1024*1024)" | bc `
    leafMB=`echo "scale=0; ${sizeLeaf}/(1024*1024)" | bc `
    nonleafMB=`echo "scale=0; ${sizeNonleaf}/(1024*1024)" | bc `
    rollbackMB=`echo "scale=0; ${sizeRollback}/(1024*1024)" | bc `
    writingMB=`echo "scale=0; ${sizeWriting}/(1024*1024)" | bc `
    
    nonleafPerc=`echo "scale=5; (${sizeNonleaf}/${sizeCurrent})*100.0" | bc `
    leafPerc=`echo "scale=5; (${sizeLeaf}/${sizeCurrent})*100.0" | bc `
    clonedPerc=`echo "scale=5; (${sizeCloned}/${sizeCurrent})*100.0" | bc `
    rollbackPerc=`echo "scale=5; (${sizeRollback}/${sizeCurrent})*100.0" | bc `
    writingPerc=`echo "scale=5; (${sizeWriting}/${sizeCurrent})*100.0" | bc `
    cachepressurePerc=`echo "scale=5; (${sizeCachepressure}/${sizeCurrent})*100.0" | bc `
    
    checkpointDurationAvg=`echo "scale=7; (${checkpointDuration}/${checkpointTaken})" | bc `
    
    if [ $headerLineLast -gt $headerLineEvery ]; then
        echo "         | Overall   --- Nonleaf ---  ----- Leaf ----  ---- Cloned ---  --- Rollback --  --- Writing ---  -- Pressure ---  -- Checkpoint -"
        echo "time     | size MB   size MB  size %  size MB  size %  size MB  size %  size MB  size %  size MB  size %  size MB  size %      avg    last"
        echo "========= =========  ======= =======  ======= =======  ======= =======  ======= =======  ======= =======  ======= =======  ======= ======="
        headerLineLast=0
    fi
    let headerLineLast=headerLineLast+1

    printf "`date +%T` |  %7d  %7d %7.1f  %7d %7.1f  %7d %7.1f  %7d %7.1f  %7d %7.1f  %7d %7.1f  %7.2f %7d\n" "$currentMB" "$nonleafMB" "$nonleafPerc" "$leafMB" "$leafPerc" "$clonedMB" "$clonedPerc" "$rollbackMB" "$rollbackPerc" "$writingMB" "$writingPerc" "$cachepressureMB" "$cachepressurePerc" "$checkpointDurationAvg" "$checkpointDurationLast"
    
    #echo $sizeCachepressure
    sleep $WAIT_TIME_SECONDS
done
