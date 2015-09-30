#! /bin/bash

baseDir=~/temp
workingDir=ftbench

numRows=100000000
numSeconds=600
compressPercentage=.25
keySize=16
valueSize=100
ftDir=/home/tcallaghan/temp/perf
#quicklz | zlib | lzma | none
compressionType=quicklz
basementNodeSize=16384
nodeSize=4194304
cacheSize=4294967296
syncPeriod=100
queryThreads=4
updateThreads=4
perfOutputSeconds=10
checkpointSeconds=60

# create ftDir if non-existent
mkdir ${ftDir}

pushd ${baseDir}/${workingDir}/ft-index/opt

# load
T="$(date +%s)"
echo "`date` | loading ${numRows} key/value pairs"
./src/tests/perf_read_write.tdb --num_elements ${numRows} --num_DBs 1 --num_seconds 1 \
  --compressibility ${compressPercentage} --key_size ${keySize} --val_size ${valueSize} --memcmp_keys \
  --compression_method ${compressionType} --envdir ${ftDir} --basement_node_size ${basementNodeSize} \
  --node_size ${nodeSize} --cachetable_size ${cacheSize} --only_create
echo "`date` | done - loader"
T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))"
ROWS_PER_SECOND=`echo "scale=2; ${numRows}/${T}" | bc `
printf "`date` | key/value pairs loaded per second = %'.1f\n" "${ROWS_PER_SECOND}"
echo ""

# execute
./src/tests/perf_read_write.tdb --num_elements ${numRows} --num_DBs 1 --num_seconds ${numSeconds} \
  --sync_period ${syncPeriod} --num_ptquery_threads ${queryThreads} --num_update_threads ${updateThreads} \
  --compressibility ${compressPercentage} --key_size ${keySize} --val_size ${valueSize} --print_performance \
  --memcmp_keys --direct_io --envdir ${ftDir} --performance_period ${perfOutputSeconds} \
  --checkpointing_period ${checkpointSeconds} --cachetable_size ${cacheSize} --only_stress

popd

