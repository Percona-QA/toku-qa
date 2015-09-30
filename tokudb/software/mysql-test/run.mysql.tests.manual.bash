#!/usr/bin/env bash

# start in a kits mysql-test folder, the script gets the appropriate tokudb test scripts from SVN
# also, make sure the mysql server is already started

baseSvnUrl=https://svn.tokutek.com/tokudb
tempSvnDir=tmcTempDir

# generic mysql test suites
genericMysqlTests=mysql/tests/mysql-test/suite

# branch we are testing (or main)
# [5.2.7,main]
tokudbVersion=main

# mysql or mariadb specific tests
# [mysql-5.1.61, mysql-5.5.21, mariadb-5.2.10]
mysqlVersion=mysql-5.5.21

# SVN revision number
#svnRev=41351
svnRev=$(svn info https://svn.tokutek.com/tokudb | awk '/^Revision:/{print $2}')

# run engine test instead of standard tests?  provide engine if so
engine=""

# Number of parallel test execution threads
threads=8

# Minutes a test can run before timing out
testtimeout=30

# get tokudb test suites that apply to all databases
rm -rf $tempSvnDir
mkdir $tempSvnDir
if [ $tokudbVersion != "main" ] ; then
  svnGetDir=${baseSvnUrl}/mysql.branches/${tokudbVersion}/mysql/tests/mysql-test/suite
else
  svnGetDir=${baseSvnUrl}/mysql/tests/mysql-test/suite
fi
svn export -r $svnRev --force $svnGetDir $tempSvnDir
cp -r ${tempSvnDir}/* suite

# get tokudb test suites specific to MySQL or MariaDB
rm -rf $tempSvnDir
mkdir $tempSvnDir
if [ $tokudbVersion != "main" ] ; then
  svnGetDir=${baseSvnUrl}/mysql.branches/${tokudbVersion}/${mysqlVersion}/mysql-test/suite
else
  if [[ $mysqlVersion =~ mariadb-(.*) ]] ; then
    svnGetDir=${baseSvnUrl}/askmonty.org/${mysqlVersion}/mysql-test/suite
  else
    svnGetDir=${baseSvnUrl}/mysql.com/${mysqlVersion}/mysql-test/suite
  fi
fi
svn export -r $svnRev --force $svnGetDir $tempSvnDir
cp -r ${tempSvnDir}/* suite

# overlay my changes
#scp -r tcallaghan@192.168.1.4:~/svn/main-mariadb-5.2.10/mysql-test/suite suite
#rsync -vrazRC --progress --stats tcallaghan@192.168.1.4:~/svn/main-mysql/tests/mysql-test/suite suite
#`nrsync -vrazRC --progress --stats tcallaghan@192.168.1.4:~/svn/main-mariadb-5.2.10/mysql-test/suite suite

system=`uname -s | tr [:upper:] [:lower:]`
arch=`uname -m | tr [:upper:] [:lower:]`

date=`date +%Y%m%d`


releasename=$system-$arch


# easy runner (8 threads, 30 minute timeout, main test)
# ./mysql-test-run.pl --big-test --mysqld=--loose-tokudb-debug=3072 --max-test-fail=0 --parallel=8 --testcase-timeout=30 --force --retry=1 --suite=main >tmc-mysql-test.log 2>&1  



if [ -z $engine ] ; then
    # generate the test list
    tests="main"
    pushd suite
    for t in * ; do
        if [[ $t =~ .*\.xfail$ ]] ; then continue; fi
        if [ -d $t/t ] ; then tests="$tests,$t"; fi
    done
    popd

    # run the tests
    ./mysql-test-run.pl --big-test --mysqld=--loose-tokudb-debug=3072 --max-test-fail=0 --parallel=${threads} --testcase-timeout=${testtimeout} --force --retry=1 --suite=$tests >tmc-mysql-test.log 2>&1  
    exitcode=$?
    
else
    tests="engines/funcs,engines/iuds"
    ./mysql-test-run.pl --suite=$tests --mysqld=--default-storage-engine=$engine --force --parallel=${threads} --testcase-timeout=${testtimeout} --retry-failure=0 --max-test-fail=0 --nowarnings >tmc-mysql-engines-test.log 2>&1
    exitcode=$?
fi    

if [ $exitcode -eq 0 ] ; then
    testresult="PASS"
else
    testresult="FAIL"
fi

echo "$testresult mysql-test $releasename"
