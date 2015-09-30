#!/bin/bash

# wait between checks
WAIT_TIME_SECONDS=$1

tempFile=/tmp/mysql-commit-speed.txt

lastCommits=0

while true ; do
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "select * from information_schema.global_status where variable_name like 'COM_COMMIT'" > ${tempFile}

    #cat ${tempFile}

    thisCommits=`grep COM_COMMIT ${tempFile} | awk '{print $2}'`
    
    commitsPerSecond=`echo "scale=1; (${thisCommits}-${lastCommits})/${WAIT_TIME_SECONDS}" | bc `

    lastCommits=${thisCommits}
    
    printf "`date +%T` |  %7.1f\n" "$commitsPerSecond"
    
    sleep $WAIT_TIME_SECONDS
done
