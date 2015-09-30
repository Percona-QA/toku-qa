#! /bin/bash

for dirName in ./*; do
  if [ -d ${dirName} ]; then
    echo ${dirName}
    echo "  -- SIZE"
    databaseSize=`cat ${dirName}/*SysbenchLoad*.log | tail -n 1 | cut -d "=" -f 2 | cut -d "/" -f 1`
    echo "    -- Database Size (MB): ${databaseSize}"
    echo "  -- LOAD (8 concurrent trickle loaders)"
    cumIps=`grep "cum ips" ${dirName}/*SysbenchLoad*.log | tail -n 1 | cut -d ":" -f 3 | cut -d "=" -f 2`
    nonLeafCompress=`grep FT_NONLEAF_COMPRESS_TOKUTIME ${dirName}/*SysbenchLoad*.engine_status | tail -n 1 | cut -d "|" -f 3`
    leafCompress=`grep FT_LEAF_COMPRESS_TOKUTIME ${dirName}/*SysbenchLoad*.engine_status | tail -n 1 | cut -d "|" -f 3`
    echo "    -- Avg. Inserts/Sec            : ${cumIps}"
    echo "    -- NonLeafCompress (seconds)   : ${nonLeafCompress}"
    echo "    -- LeafCompress (seconds)      : ${leafCompress}"
    echo "  -- QUERY (64 concurrent sysbench read only threads)"
    cumTps=`grep "cum ips" ${dirName}/*SysbenchExecute*.log | tail -n 1 | cut -d ":" -f 2 | cut -d "=" -f 2`
    nonLeafDecompress=`grep FT_NONLEAF_DECOMPRESS_TOKUTIME ${dirName}/*SysbenchExecute*.engine_status | tail -n 1 | cut -d "|" -f 3`
    leafDecompress=`grep FT_LEAF_DECOMPRESS_TOKUTIME ${dirName}/*SysbenchExecute*.engine_status | tail -n 1 | cut -d "|" -f 3`
    echo "    -- Avg. Txn/Sec                : ${cumTps}"
    echo "    -- NonLeafDecompress (seconds) : ${nonLeafDecompress}"
    echo "    -- LeafDecompress (seconds)    : ${leafDecompress}"
  fi
done
