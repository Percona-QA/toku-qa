#!/bin/bash
# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
SCRIPTPATH=`dirname $SCRIPT`

MYSQL_USER=$1
MYSQL_PASS=$2
MYSQL_HOST=$3
SCHEMA=$4
TABLE=$5
NUM_ROWS=$6
TRANSACTION_SIZE=$7
MAX_THREADS=$8
CONFIG=$9
RUNTHIS_PID_DIR=${10}

CHUNK_SIZE=100000
MODE="insert" #insert or tab_del_dump

START_AT=$SECONDS

if [ "$NUM_ROWS" -gt $CHUNK_SIZE ] ; then
	iterations=`expr $NUM_ROWS / $CHUNK_SIZE`
	for i in `seq 1 $iterations`; do
		j=$(( i-1 ))
		#echo "j is $j"
	    while [ "$(jobs -pr | wc -l)" -ge "$MAX_THREADS" ] ; do sleep 2; done
	    $SCRIPTPATH/bin/gen_data.php --config=$CONFIG -u $MYSQL_USER -p $MYSQL_PASS -h=$MYSQL_HOST --database=$SCHEMA --extended_insert_size=$TRANSACTION_SIZE --seed=$i $TABLE $CHUNK_SIZE $MODE &
	    #echo "$!" >> "$SCRIPTPATH/pid_map/$RUNTHIS_PID_DIR/$$.pids"
	done
else
	while [ "$(jobs -pr | wc -l)" -ge "$MAX_THREADS" ] ; do sleep 2; done
	$SCRIPTPATH/bin/gen_data.php --config=$CONFIG -u $MYSQL_USER -p $MYSQL_PASS -h=$MYSQL_HOST --database=$SCHEMA --extended_insert_size=$TRANSACTION_SIZE --seed=0 $TABLE $NUM_ROWS $MODE &
	#echo "$!" >> "$SCRIPTPATH/pid_map/$RUNTHIS_PID_DIR/$$.pids"
fi

wait
FINISHED_INSERTING_AT=$SECONDS
insert_time=`expr $FINISHED_INSERTING_AT - $START_AT`
num_rows=$(mysql -u"$MYSQL_USER" -p$MYSQL_PASS -h"$MYSQL_HOST" -BNe "SELECT count(*) FROM $SCHEMA.$TABLE;")
rows_per_sec=`expr $num_rows / $insert_time`
echo -e '\033[0;0f';
echo "Inserted $num_rows rows into $SCHEMA.$TABLE in $insert_time seconds ($rows_per_sec rows/sec) " >> load-performance.log

