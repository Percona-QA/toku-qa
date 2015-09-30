#!/bin/bash

# start in an appropriate sql-bench folder

bindir=.
testresultsdir=.

engine=tokudb
socket=/tmp/tmc.sock
user=root
system=`uname -s | tr [:upper:] [:lower:]`
arch=`uname -m | tr [:upper:] [:lower:]`
date=`date +%Y%m%d`

# run the tests
releasename=tmc-test
tracefile=sql-bench-$releasename.trace
summaryfile=sql-bench-$releasename.summary

function mydate() {
    date +"%Y%m%d %H:%M:%S"
}

function runtests() {
    testargs=""
    skip=""
    for arg in $* ; do
	if [[ $arg =~ "--skip=(.*)" ]] ; then
	    skip=${BASH_REMATCH[1]}
	else
	    testargs="$testargs $arg"
	fi
    done
    for testname in test* ; do
	#if [[ $testname =~ "^(.*).sh$" ]] ; then
	#    t=${BASH_REMATCH[1]}
	#else
	#    continue
	#fi
	echo `mydate` $testname $testargs
	if [ "$skip" != "" ] && [[ "$testname" =~ "$skip" ]]; then 
	    echo "skip $testname"
	else
	    ./$testname $testargs
	fi
	echo `mydate`
    done
}

>$testresultsdir/$tracefile

runtests --create-options=engine=$engine --socket=$socket --user=$user --verbose --small-test         >>$testresultsdir/$tracefile 2>&1
runtests --create-options=engine=$engine --socket=$socket --user=$user --verbose --small-test --fast  >>$testresultsdir/$tracefile 2>&1
runtests --create-options=engine=$engine --socket=$socket --user=$user --verbose                      >>$testresultsdir/$tracefile 2>&1
runtests --create-options=engine=$engine --socket=$socket --user=$user --verbose              --fast  >>$testresultsdir/$tracefile 2>&1
runtests --create-options=engine=$engine --socket=$socket --user=$user --verbose              --fast --lock-tables >>$testresultsdir/$tracefile 2>&1

# summarize the results
python $bindir/bench.summary.py <$testresultsdir/$tracefile >$testresultsdir/$summaryfile

testresult=""
pf=`mktemp`
egrep "^PASS" $testresultsdir/$summaryfile >$pf 2>&1
if [ $? -eq 0 ] ; then testresult="PASS=`cat $pf | wc -l` $testresult"; fi
egrep "^FAIL" $testresultsdir/$summaryfile >$pf 2>&1
if [ $? -eq 0 ] ; then testresult="FAIL=`cat $pf | wc -l` $testresult"; fi
rm $pf
if [ "$testresult" = "" ] ; then testresult="?"; fi

exit 0
