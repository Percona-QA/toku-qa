#!/bin/bash

if [ -z "$SCP_TARGET" ]; then
    echo "Need to set SCP_TARGET"
    exit 1
fi

for num_additional_writers in 0 1 3 7 15 31 63 ; do
    export ADDITIONAL_WRITERS=${num_additional_writers}
    echo "Running benchmark with ${ADDITIONAL_WRITERS} additional writers..."
    ./run.benchmark.sh
    sleep 15
    let TOTAL_WRITERS=ADDITIONAL_WRITERS+1
    scp *.writecap ${SCP_TARGET}:~/${MACHINE_NAME}-new-${TOTAL_WRITERS}.writecap
done
