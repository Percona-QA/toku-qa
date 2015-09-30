#!/bin/bash

fullPath=$1
dirName=$2
benchName=$3

machineName=`echo ${dirName} | cut -d "-" -f1`
numCollections=`echo ${dirName} | cut -d "-" -f6`
numRowsPerCollection=`echo ${dirName} | cut -d "-" -f7`
mongoType=`echo ${dirName} | cut -d "-" -f5`

#    raw_line=`grep ${search_string} /tmp/tmcinfo.txt`
#    this_what=`echo ${raw_line} | cut -d " " -f4`

echo "---------------------------------------------------------"
echo "type = ${mongoType}, ${numCollections} x ${numRowsPerCollection}"

for i in ${fullPath}/*mongoSysbenchLoad*.log; do
  loadSize=`grep "post-load" ${i} | cut -d " " -f15`
  loadSpeed=`tail -n1 ${i}.tsv | cut -f3`
done

echo "---------------------------------------------------------"
echo "threads/avg/exit : load / ${loadSpeed} / ${loadSize}"

for i in ${fullPath}/*${benchName}*.log; do
  baseName=$(basename $i)
  threadCount=`echo ${baseName} | cut -d "-" -f5`
  runSize=`grep "post-load" ${i} | cut -d " " -f15`
  runSpeed=`tail -n1 ${i}.tsv | cut -f2`
  echo "threads/avg/exit : ${threadCount} / ${runSpeed} / ${runSize}"
done
