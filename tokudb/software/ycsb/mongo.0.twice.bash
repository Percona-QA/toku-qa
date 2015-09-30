#!/bin/bash

export RECORDCOUNT=15000000


export TARBALL=tokumx-1.3.1-linux-x86_64
export BENCH_ID=tokumx.131
export MONGO_TYPE=tokumx
export TOKUMON_CACHE_SIZE=12G
mongo-clean
./mongo.1.doit.bash


export TARBALL=mongodb-linux-x86_64-2.4.8
export BENCH_ID=mongodb.248
export MONGO_TYPE=mongo
mongo-clean    
# ************************************************************
# LOCKOUT MEMORY
# ************************************************************
if [ -z "$LOCK_MEM_SIZE_16" ]; then
    echo "Need to set LOCK_MEM_SIZE_16"
    exit 1
fi
sudo pkill -9 lockmem
echo "locking ${LOCK_MEM_SIZE_16} of RAM on server"
sudo ~/bin/lockmem $LOCK_MEM_SIZE_16 &
sleep 10
# ************************************************************
# END - LOCKOUT MEMORY
# ************************************************************
./mongo.1.doit.bash
# ************************************************************
# UNLOCK MEMORY
# ************************************************************
echo "returning ${LOCK_MEM_SIZE_16} of RAM to server"
sudo pkill -9 lockmem
sleep 10
# ************************************************************
# END - UNLOCK MEMORY
# ************************************************************


