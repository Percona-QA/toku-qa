#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536

export NUM_COLLECTIONS=16
export NUM_DOCUMENTS_PER_COLLECTION=2000000

export NUM_INSERTS_PER_FEEDBACK=500000

export NUM_DOCUMENTS_PER_INSERT=1000
export NUM_LOADER_THREADS=8
export threadCountList="0064"
export RUN_TIME_SECONDS=300
export DB_NAME=sbtest
export BENCHMARK_NUMBER=999

# FSYNC_SAFE, NONE, NORMAL, REPLICAS_SAFE, SAFE
export WRITE_CONCERN=SAFE

export TOKUMON_CACHE_SIZE=4G

export MONGO_REPLICATION=Y



AUDIT_FILTER=""

#AUDIT_FILTER='--auditFilter {atype:{$nin:["createDatabase","authenticate"]}}'
#AUDIT_FILTER='--auditFilter {atype:{$in:["dropCollection","authenticate"]}}'
#AUDIT_FILTER='--auditFilter {atype:"createIndex"}}'

#AUDIT_FILTER='--auditFilter {"users.user":{$nin:["admin","bob2"]}}'
#AUDIT_FILTER='--auditFilter {"users.user":{$in:["admin","bob"]}}'
#AUDIT_FILTER='--auditFilter {"users.user":"bob"}}'

#AUDIT_FILTER='--auditFilter {"users.db":{$nin:["admin","timbo"]}}'
#AUDIT_FILTER='--auditFilter {"users.db":{$in:["admin","test"]},"users.user":"bob"}'
#AUDIT_FILTER='--auditFilter {"users.db":"timbo"}}'

# just bob in test
#AUDIT_FILTER='--auditFilter {"users.db":{$in:["test"]},"users.user":"bob"}'

#export MONGOD_EXTRA="--auditDestination=file --auditFormat=JSON --auditPath=/tmp/audit.log ${AUDIT_FILTER}"



# TOKUMX - audit on
export MONGOD_EXTRA="--auditDestination=file --auditFormat=JSON --auditPath=/tmp/audit.log ${AUDIT_FILTER}"
export BENCHMARK_SUFFIX=".${TOKUMON_CACHE_SIZE}G"
export MONGO_TYPE=tokumx
export TARBALL=tokumx-e-2.0.0-SNAPSHOT-20140929a-linux-x86_64-main
export BENCH_ID=AUDIT_ON-${TARBALL}-${MONGO_COMPRESSION}-${WRITE_CONCERN}-${MONGO_REPLICATION}
./doit.bash
mongo-clean

# TOKUMX - audit off
unset MONGOD_EXTRA
export BENCHMARK_SUFFIX=".${TOKUMON_CACHE_SIZE}G"
export MONGO_TYPE=tokumx
export TARBALL=tokumx-e-2.0.0-SNAPSHOT-20140929a-linux-x86_64-main
export BENCH_ID=AUDIT_OFF-${TARBALL}-${MONGO_COMPRESSION}-${WRITE_CONCERN}-${MONGO_REPLICATION}
./doit.bash
mongo-clean

# TOKUMX - community edition
unset MONGOD_EXTRA
export BENCHMARK_SUFFIX=".${TOKUMON_CACHE_SIZE}G"
export MONGO_TYPE=tokumx
export TARBALL=tokumx-2.0.0-SNAPSHOT-20140929a-linux-x86_64-main
export BENCH_ID=CE-${TARBALL}-${MONGO_COMPRESSION}-${WRITE_CONCERN}-${MONGO_REPLICATION}
./doit.bash
mongo-clean



unset MONGOD_EXTRA
