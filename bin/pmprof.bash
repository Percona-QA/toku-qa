#!/bin/bash

if [ $# -eq 0 ]; then
  echo "usage: pmprof.bash <total-time-seconds> <seconds-between-samples> <number-of-runs> <process-name> <output-file-name> <seconds-delay-before-start>"
  exit 1
fi

# figure out which gdb to use
gdbCommand=gdb75
type -P ${gdbCommand} &>/dev/null
if [ $? -eq 0 ]; then
    # use gdb75
    gdbCommand=gdb75
else
    # just use gdb
    gdbCommand=gdb
fi
# END: figure out which gdb to use

totalTimeSeconds=${1}
sleepSeconds=${2}
numRuns=${3}
processName=${4}
#pidCheck=`pidof ${4}`
pidCheck=`pgrep -u $USER -x ${4}`
outputFile=${5}
delaySeconds=${6}

echo "${processName} process found with pid=${pidCheck}"

startSeconds="$(date +%s)"

secondsPerLoop=$((${totalTimeSeconds} / ${numRuns}))

sleep ${delaySeconds}

for loops in $(seq 1 $numRuns) ; do
  echo "Starting loop ${loops}"

  beginSeconds="$(($(date +%s)-startSeconds))"

  thisRunStartSeconds="$(date +%s)"
  thisRunSeconds="$(($(date +%s)-thisRunStartSeconds))"
  
  #for x in $(seq 1 $nsamples) ; do
  while [ ${thisRunSeconds} -le ${secondsPerLoop} ]; do
    ${gdbCommand} -ex "set pagination 0" -ex "thread apply all bt" -batch -p ${pidCheck}
    sleep ${sleepSeconds}
    thisRunSeconds="$(($(date +%s)-thisRunStartSeconds))"
  done | \
  awk '
    BEGIN { s = ""; } 
    /^Thread/ { if (s != "") print s; s = ""; } 
    /^\#/ { if ($3 == "in") { v = $4; } else { v = $2 } if (s != "" ) { s = s "," v} else { s = v } } 
    END { print s }' | \
  sort | uniq -c | sort -r -n -k 1,1 > ${outputFile}.${beginSeconds}.pmprof
done
