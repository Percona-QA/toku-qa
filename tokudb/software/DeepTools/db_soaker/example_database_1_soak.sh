#!/bin/bash
# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
SCRIPTPATH=`dirname $SCRIPT`

MYSQL_USER=$1
MYSQL_PASS=$2
MYSQL_HOST=$3

CONFIG="example_database_1_config.php"
TRANSACTION_SIZE=5
NUM_ROWS=1000000
NUM_CLIENTS=16
rm $SCRIPTPATH/tmp.cache

echo "Checking MySQL connection..."
mysql -u"$MYSQL_USER" -p$MYSQL_PASS -h"$MYSQL_HOST" -e exit 2>/dev/null
if [ $? -ne 0 ]; then
	echo "Failed to connect to MySQL ($MYSQL_HOST) using user:$MYSQL_USER pass:$MYSQL_PASS "
	exit;
fi

DATABASES="example_database_1"


for DATABASE in ${DATABASES}; do
	for table in $(mysql -u"$MYSQL_USER" -p$MYSQL_PASS -h"$MYSQL_HOST" -BNe "show tables" $DATABASE ) ; do
		$SCRIPTPATH/generate_random_data.sh $MYSQL_USER $MYSQL_PASS $MYSQL_HOST $DATABASE $table $NUM_ROWS $TRANSACTION_SIZE $NUM_CLIENTS $CONFIG&
	done
done

echo "Running..."
wait;
echo "Done."




