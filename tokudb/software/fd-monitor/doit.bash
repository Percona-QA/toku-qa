#!/bin/bash

#secondsBetweenChecks=300
#logFile=$PWD/fd-monitor.log

#~/Dropbox/Public/tokutek/pager.log

#while [ 1 -eq 1 ] ; do
#    ./fd-monitor.py | tee -a ${logFile}
#    echo "sleeping for ${secondsBetweenChecks} seconds..."
#    sleep ${secondsBetweenChecks}
#done

baseDir=/root/fdmonitor
logFile=${baseDir}/fd-monitor.log

${baseDir}/fd-monitor.py >> ${logFile}
