#!/bin/bash

if [ -z "$MYSQL_SOCKET" ]; then
    echo "Need to set MYSQL_SOCKET"
    exit 1
fi
if [ -z "$MYSQL_DATABASE" ]; then
    echo "Need to set MYSQL_DATABASE"
    exit 1
fi
if [ -z "$MYSQL_USER" ]; then
    echo "Need to set MYSQL_USER"
    exit 1
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    echo "Need to set MYSQL_STORAGE_ENGINE"
    exit 1
fi
if [ -z "$MACHINE_NAME" ]; then
    echo "Need to set MACHINE_NAME"
    exit 1
fi
if [ -z "$MYSQL_NAME" ]; then
    echo "Need to set MYSQL_NAME"
    exit 1
fi
if [ -z "$MYSQL_VERSION" ]; then
    echo "Need to set MYSQL_VERSION"
    exit 1
fi
if [ -z "$SCP_TARGET" ]; then
    echo "Need to set SCP_TARGET"
    exit 1
fi


LOG_BENCHMARK_NAME=atc
LOG_NAME_TIMING=$LOG_NAME.perf.txt

pushd sql
for qfile in q*.sql ; do
    if [[ $qfile =~ q(.*)\.sql ]] ; then
        qname=${BASH_REMATCH[1]}
        q=`cat $qfile`
        qrun=q${qname}.run

        echo `date` $qfile

        echo `date` explain $qfile >>${LOG_NAME}
        echo explain $q >>${LOG_NAME}
        $DB_DIR/bin/mysql -S ${MYSQL_SOCKET} -u ${MYSQL_USER} -D ${MYSQL_DATABASE} -e "explain $q"  >$qrun
        exitcode=$?
        echo `date` explain $qfile $exitcode >>${LOG_NAME}
        cat $qrun >>${LOG_NAME}

        echo `date` $qfile >>${LOG_NAME}
        start=$(date +%s)
        echo $q >>${LOG_NAME}
        $DB_DIR/bin/mysql -S ${MYSQL_SOCKET} -u ${MYSQL_USER} -D ${MYSQL_DATABASE} -e "$q"  >$qrun
        exitcode=$?
        let qtime=$(date +%s)-$start
        echo `date` $qfile qtime=$qtime $exitcode >>${LOG_NAME}
        echo $qfile $qtime $exitcode >>${LOG_NAME_TIMING}
        cat $qrun >>${LOG_NAME}
        if [ $exitcode -ne 0 ] ; then
            testresult="FAIL"
            echo "********** FAIL **********" >>${LOG_NAME}
            echo "********** FAIL **********" >>${LOG_NAME_TIMING}
        else
            if [ -f q${qname}.result ] ; then
                diff $qrun q${qname}.result >>${LOG_NAME}
                exitcode=$?
                if [ $exitcode -ne 0 ] ; then
                    testresult="FAIL"
                    echo "********** FAIL **********" >>${LOG_NAME}
                    echo "********** FAIL **********" >>${LOG_NAME_TIMING}
                fi
            fi
        fi
    fi
done
popd

