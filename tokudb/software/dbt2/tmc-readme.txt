building dbt2
-------------

aclocal; autoheader; autoconf; automake

# build one of two ways
  # non-stored-procedure version
  ./configure --enable-nonsp --with-mysql --with-mysql-includes=$DB_DIR/include --with-mysql-libs=$DB_DIR/lib
  # stored-procedure version
  ./configure --with-mysql --with-mysql-includes=$DB_DIR/include --with-mysql-libs=$DB_DIR/lib
  
make


creating sample data files
--------------------------

# 1000 warehouses
src/datagen -w 1000 -d /data/tcallaghan/temp/dbt2 --mysql


loading sample data files
-------------------------

cd scripts/mysql

[ edit line 433 of build_db.sh to add support for TOKUDB engine ]

time ./build_db.sh -d dbt2 -f /data/tcallaghan/temp/dbt2 -s ${MYSQL_SOCKET} -u root -e TOKUDB -v

# check filesystem sizing after loading

#   options:
#       -d <database name>
#       -f <path to dataset files>
#       -m <database scheme [OPTIMIZED|ORIG] (default scheme OPTIMIZED)>
#       -c <path to mysql client binary. (default /usr/bin/mysql)>
#       -s <database socket>
#       -h <database host>
#       -u <database user>
#       -p <database password>
#       -e <storage engine: [MYISAM|INNODB|BDB]. (default INNODB)>
#       -l <to use LOCAL keyword while loading dataset>
#       -v <verbose output>


running the benchmark
---------------------

cd scripts
./run_mysql.sh -c 32 -t 300 -w 1000 -n dbt2 -o ${MYSQL_SOCKET} -u root -e

#usage: run_workload.sh -c <number of database connections> -t <duration of test> -w <number of warehouses>
#other options:
#       -n <database name. (default dbt2)>
#       -h <database host name. (default localhost)>
#       -l <database port number>
#       -o <database socket>
#       -u <database user>
#       -p <database password>
#       -s <delay of starting of new thread in milliseconds>
#       -k <stack size. (default 256k)>
#       -m <terminals per warehouse. [1..10] (default 10)>
#       -z <comments for the test>
#       -e <enable zero delays for test (default no)>
#       -v <verbose output>


