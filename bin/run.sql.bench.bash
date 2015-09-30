#!/bin/bash

function usage() {
    echo "run the sql bench tests"
    echo "--mysql-$mysql"
    echo "--branch=$branch"
    echo "--revision=$revision"
    echo "--commit=$commit"
    echo "--tokudb_debug=$tokudb_debug"
}

function retry() {
    local cmd
    local retries
    local exitcode
    cmd=$*
    let retries=0
    while [ $retries -le 10 ] ; do
        echo `date` $cmd
        bash -c "$cmd"
        exitcode=$?
        echo `date` $cmd $exitcode $retries
        let retries=retries+1
        if [ $exitcode -eq 0 ] ; then break; fi
        sleep 10
    done
    test $exitcode = 0
}

svnserver=https://svn.tokutek.com/tokudb
basedir=$HOME/svn.build
builddir=$basedir/mysql.build
mysql=mysql-5.1.46
mysqlserver=`hostname`
branch=.
revision=0
suffix=.
commit=0
engine=tokudb
socket=/tmp/mysql.sock
tokudb_debug=0
system=`uname -s | tr [:upper:] [:lower:]`
arch=`uname -m | tr [:upper:] [:lower:]`
instancetype=""

# parse the command line
while [ $# -gt 0 ] ; do
    arg=$1; shift
    if [[ $arg =~ --(.*)=(.*) ]] ; then
        eval ${BASH_REMATCH[1]}=${BASH_REMATCH[2]}
    else
        usage; exit 1
    fi
done

# make sure a revision is requested
if [ $revision -eq 0 ] ; then exit 1; fi
if [ $branch = "." ] ; then branchrevision=$revision; else branchrevision=`basename $branch`-$revision; fi
if [ "$suffix" != "." ] ; then branchrevision=$branchrevision-$suffix; fi
if [ $tokudb_debug -ne 0 ] ; then branchrevision=$branchrevision-$tokudb_debug; fi

# goto the base directory
if [ ! -d $basedir ] ; then mkdir $basedir; fi
pushd $basedir

# update the build directory
if [ ! -d $builddir ] ; then mkdir $builddir; fi

date=`date +%Y%m%d`
testresultsdir=$builddir/$date
pushd $builddir
while [ ! -d $date ] ; do
    svn mkdir $svnserver/mysql.build/$date -m ""
    svn checkout -q $svnserver/mysql.build/$date
    if [ $? -ne 0 ] ; then rm -rf $date; fi
done
popd

# get the sql-bench directory from the appropriate mysql source
if [ $branch = "." ] ; then
    mysql_branch=mysql.com
else 
    mysql_branch=$branch
fi
rm -rf sql-bench-$mysql-$branchrevision
retry svn export -q -r $revision $svnserver/$mysql_branch/$mysql/sql-bench sql-bench-$mysql-$branchrevision
exitcode=$?
if [ $exitcode -ne 0 ] ; then 
    echo `date` svn export  -q -r $revision $svnserver/$mysql_branch/$mysql/sqlbench sql-bench-$mysql-$branchrevision exitcode=$exitcode >>/tmp/sql.bench.trace
    exit 1
fi

if [ $tokudb_debug -ne 0 ] ; then
    mysql -S $socket -e "set global tokudb_debug=$tokudb_debug"
    exitcode=$?
    if [ $exitcode -ne 0 ] ; then
        echo `date` mysql $mysql $branchrevision set tokudb-debug=$tokudb_debug $exitcode >>/tmp/sql.bench.trace
        exit 1
    fi
fi

# run the tests
pushd sql-bench-$mysql-$branchrevision
releasename=$mysql-$branchrevision-$system-$arch
tracefile=sql-bench-$engine-$releasename-$mysqlserver
summaryfile=sql-bench-$engine-$releasename-$mysqlserver
if [ "$instancetype" != "" ] ; then 
    tracefile=$tracefile-$instancetype
    summaryfile=$summaryfile-$instancetype
fi
tracefile=$tracefile.trace
summaryfile=$summaryfile.summary

function mydate() {
    date +"%Y%m%d %H:%M:%S"
}

function setuptests() {
    echo `date` setuptests `pwd` >>/tmp/sql.bench.trace
    sed -e "1,\$s/@PERL@/\/usr\/bin\/env perl/" <./bench-init.pl.sh >./bench-init.pl
    sed -e "1,\$s/@PERL@/\/usr\/bin\/env perl/" <./server-cfg.sh >./server-cfg
    for testsh in test-*.sh ; do
        if [[ $testsh =~ ^(.*).sh$ ]] ; then
            t=${BASH_REMATCH[1]}
            sed -e "1,\$s/@PERL@/\/usr\/bin\/env perl/" <./$testsh >./$t
            chmod u+x ./$t
        fi
    done
}

function runtests() {
    testargs=""
    skip=""
    for arg in $* ; do
        if [[ $arg =~ --skip=(.*) ]] ; then
            skip=${BASH_REMATCH[1]}
        else
            testargs="$testargs $arg"
        fi
    done
    for testname in test*.sh ; do
        if [[ $testname =~ ^(.*).sh$ ]] ; then
            t=${BASH_REMATCH[1]}
        else
            continue
        fi
        echo `mydate` $t $testargs
        if [ "$skip" != "" ] && [[ "$t" =~ $skip ]]; then 
            echo "skip $t"
            exitcode=0
        else
            ./$t $testargs
            exitcode=$?
        fi
        echo `mydate`
        if [ $exitcode != 0 ] ; then
            # assume that the test failure due to a crash.  allow mysqld to restart.
            sleep 60
        fi
    done
}

>$testresultsdir/$tracefile

setuptests

runtests --create-options=engine=$engine --socket=$socket --verbose --small-test         >>$testresultsdir/$tracefile 2>&1
runtests --create-options=engine=$engine --socket=$socket --verbose --small-test --fast  >>$testresultsdir/$tracefile 2>&1
runtests --create-options=engine=$engine --socket=$socket --verbose                      >>$testresultsdir/$tracefile 2>&1
runtests --create-options=engine=$engine --socket=$socket --verbose              --fast  >>$testresultsdir/$tracefile 2>&1
runtests --create-options=engine=$engine --socket=$socket --verbose              --fast --fast-insert >>$testresultsdir/$tracefile 2>&1
runtests --create-options=engine=$engine --socket=$socket --verbose              --fast --lock-tables >>$testresultsdir/$tracefile 2>&1

popd

# summarize the results
python ~/bin/bench.summary.py <$testresultsdir/$tracefile >$testresultsdir/$summaryfile

testresult=""
pf=`mktemp`
egrep "^PASS" $testresultsdir/$summaryfile >$pf 2>&1
if [ $? -eq 0 ] ; then testresult="PASS=`cat $pf | wc -l` $testresult"; fi
egrep "^FAIL" $testresultsdir/$summaryfile >$pf 2>&1
if [ $? -eq 0 ] ; then testresult="FAIL=`cat $pf | wc -l` $testresult"; fi
rm $pf
if [ "$testresult" = "" ] ; then testresult="?"; fi

# commit the results
pushd $testresultsdir
if [ $commit != 0 ] ; then
    svn add $tracefile $summaryfile
    retry svn commit -m \"$testresult sql-bench $releasename $mysqlserver\" $tracefile $summaryfile
fi
popd

popd

if [[ $testresult =~ "PASS" ]] ; then exitcode=0; else exitcode=1; fi
exit $exitcode



