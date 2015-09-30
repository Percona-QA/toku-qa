#!/usr/bin/env bash

function usage() {
    echo "run the tokudb mysql tests"
    echo "--mysql=$mysql"
    echo "--branch=$branch"
    echo "--revision=$revision"
    echo "--suffix=$suffix"
    echo "--commit=$commit"
    echo "--tests=$tests --engine=$engine --checkouttests=$checkouttests"
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
mysql=mysql-5.1.30
mysql_basedir=/usr/local/mysql
mysqlserver=`hostname`
branch="."
revision=0
suffix="."
commit=0
system=`uname -s | tr [:upper:] [:lower:]`
arch=`uname -m | tr [:upper:] [:lower:]`
instancetype=""
checkouttests=1
tests="*"
engine=""
parallel=1

while [ $# -gt 0 ] ; do
    arg=$1; shift
    if [[ $arg =~ --(.*)=(.*) ]] ; then
	eval ${BASH_REMATCH[1]}=${BASH_REMATCH[2]}
    else
	usage; exit 1
    fi
done

if [ $revision -eq 0 ] ; then exit 1; fi
if [ $branch = "." ] ; then branchrevision=$revision; else branchrevision=`basename $branch`-$revision; fi
if [ "$suffix" != "." ] ; then branchrevision=$branchrevision-$suffix; fi

if [ -d $mysql_basedir/lib/mysql ] ; then
    export LD_LIBRARY_PATH=$mysql_basedir/lib/mysql
fi

# update the build directory
if [ ! -d $basedir ] ; then mkdir $basedir ; fi

pushd $basedir
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

    releasename=$mysql-$branchrevision-$system-$arch

    if [ -z $engine ] ; then
	tracefile=mysql-test-$releasename-$mysqlserver
    else
	tracefile=mysql-engine-$engine-$releasename-$mysqlserver
    fi
    if [ "$instancetype" != "" ] ; then tracefile=$tracefile-$instancetype; fi
    echo >$testresultsdir/$tracefile

    if [ $checkouttests != 0 ] ; then
	rm -rf mysql-test mysql-test-$mysql-$branchrevision

        # checkout the mysql-test directory
	if [ $branch = "." ] ; then 
	    if [[ $mysql =~ mariadb(.*) ]] ; then
		mysql_branch=askmonty.org
	    else
		mysql_branch=mysql.com
	    fi
	else 
	    mysql_branch=$branch
	fi

	retry svn export -r $revision -q $svnserver/$branch/mysql/tests/mysql-test mysql-test-common-$branchrevision
	if [ $? -ne 0 ] ; then exit 3 ; fi

        # copy the suite to the mysql install directory
	pushd mysql-test-common-$branchrevision
	if [ $? != 0 ] ; then exit 4; fi
        cp -r suite $mysql_basedir/mysql-test
	if [ $? -ne 0 ] ; then exit 4; fi
	popd

	rm -rf mysql-test-common-$branchrevision

	retry svn export -r $revision -q $svnserver/$mysql_branch/$mysql/mysql-test mysql-test-$mysql-$branchrevision
	if [ $? -ne 0 ] ; then exit 3 ; fi

        # copy the suite to the mysql install directory
	pushd mysql-test-$mysql-$branchrevision
	if [ $? != 0 ] ; then exit 4; fi
        cp -r suite $mysql_basedir/mysql-test
	if [ $? != 0 ] ; then exit 4; fi
	popd

	rm -rf mysql-test-$mysql-$branchrevision
    fi

    if [ -z $engine ] ; then

    # run all test suites including main
    teststorun_original=""
    teststorun_tokudb=""
    pushd $mysql_basedir/mysql-test/suite
    if [ $? = 0 ] ; then
        for t in $tests ;  do
            if [[ $t =~ .*\.xfail$ ]] ; then continue; fi
            if [ $t = "perfschema_stress" ] ; then continue; fi
            if [ $t = "large_tests" ] ; then continue; fi
            if [ $t = "pbxt" ] ; then continue; fi
            if [ -d $t/t ] ; then 
              if [[ $t =~ tokudb* ]] ; then
                if [ -z $teststorun_tokudb ] ; then teststorun_tokudb="$t" ; else teststorun_tokudb="$teststorun_tokudb,$t"; fi
              else
                teststorun_original="$teststorun_original,$t";
              fi
            fi
        done
        popd
    fi

    default_storage_engine="myisam"

        # run the tests
	pushd $mysql_basedir/mysql-test
	./mysql-test-run.pl --suite=rpl/rpl_temp_table --big-test --mysqld=--loose-tokudb-debug=3072 --max-test-fail=0 --force --retry=1 --testcase-timeout=30 \
	    --parallel=$parallel --mysqld=--default-storage-engine=$default_storage_engine --mysqld=--sql-mode="" >>$testresultsdir/$tracefile 2>&1  
#	./mysql-test-run.pl --suite=$teststorun_original --big-test --mysqld=--loose-tokudb-debug=3072 --max-test-fail=0 --force --retry=1 --testcase-timeout=30 \
#	    --parallel=$parallel --mysqld=--default-storage-engine=$default_storage_engine --mysqld=--sql-mode="" >>$testresultsdir/$tracefile 2>&1  

#	./mysql-test-run.pl --suite=$teststorun_tokudb --big-test --mysqld=--loose-tokudb-debug=3072 --max-test-fail=0 --force --retry=1 --testcase-timeout=30 \
#	    --parallel=$parallel >>$testresultsdir/$tracefile 2>&1  
	exitcode=$?
	popd

	engine="tokudb"
    fi

    if [ ! -z $engine ] ; then
	teststorun="engines/funcs,engines/iuds"
	pushd $mysql_basedir/mysql-test
#	./mysql-test-run.pl --suite=$teststorun --mysqld=--default-storage-engine=$engine --force --retry-failure=0 --max-test-fail=0 --nowarnings \
#	    --parallel=$parallel >>$testresultsdir/$tracefile 2>&1
	exitcode=$?
	popd
    fi

    let tests_failed=0
    let tests_passed=0
    while read line ; do
	if [[ "$line" =~ (Completed|Timeout):\ Failed\ ([0-9]+)\/([0-9]+) ]] ; then
	    # failed[2]/total[3]
	    let tests_failed=tests_failed+${BASH_REMATCH[2]}
	    let tests_passed=tests_passed+${BASH_REMATCH[3]}-${BASH_REMATCH[2]}
	elif [[ "$line" =~ Completed:\ All\ ([0-9]+)\ tests ]] ; then
	    # passed[1]
	    let tests_passed=tests_passed+${BASH_REMATCH[1]}
	fi
    done <$testresultsdir/$tracefile

    # commit the results
    if [ $exitcode = 0 -a $tests_failed = 0 ] ; then
	testresult="PASS=$tests_passed"
    else
	testresult="FAIL=$tests_failed PASS=$tests_passed"
    fi
    pushd $testresultsdir
        if [ $commit != 0 ] ; then
	    svn add $tracefile 
	    if [[ $tracefile =~ "mysql-test" ]] ; then test=mysql-test; else test=mysql-engine-$engine; fi
	    retry svn commit -m \"$testresult $test $releasename $mysqlserver\" $tracefile 
	fi
    popd

popd

if [[ $testresult =~ "PASS" ]] ; then exitcode=0; else exitcode=1; fi
exit $exitcode


