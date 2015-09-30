#!/bin/bash

#export TARBALL=tokumx-1.5.0-linux-x86_64-main.tar.gz
export TARBALL=tokumx-20140811-linux-x86_64-main.tar.gz

unset MONGO_REPL
export TOKUMON_CACHE_SIZE=8G
export MONGO_LOG=/tmp/tokumx.log
export BENCHMARK_LOG=./${TARBALL}.log

NUM_DOCUMENTS=100000
CHAR_FIELD_LENGTH=8096
NUM_UPDATES=250000

rm -rf $MONGO_LOG
rm -rf $BENCHMARK_LOG

mongo-clean
mkmon $TARBALL
mongo-start-tokumx-fork
mongo-is-up

# load the data
$MONGO_DIR/bin/mongo --eval "myGlobalEnv = {numDocuments:'$NUM_DOCUMENTS', numUpdates:'$NUM_UPDATES', charLength:'$CHAR_FIELD_LENGTH'}" 1-load.js | tee -a ${BENCHMARK_LOG}

mongo-stop
mongo-is-down
export MONGO_REPL=tmcRepl
mongo-start-tokumx-fork
mongo-is-up
mongo-start-replication


# run the benchmark
$MONGO_DIR/bin/mongo --eval "myGlobalEnv = {numDocuments:'$NUM_DOCUMENTS', numUpdates:'$NUM_UPDATES', charLength:'$CHAR_FIELD_LENGTH'}" 2-execute.js | tee -a ${BENCHMARK_LOG}

mongo-stop
mongo-is-down

echo ""; echo ""; echo ""

grep "\.\.\." ${BENCHMARK_LOG}
rm -rf $BENCHMARK_LOG

echo ""; echo ""; echo ""

