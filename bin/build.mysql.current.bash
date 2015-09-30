#! /bin/bash

get.make.mysql.bash

github_token=b338436b0fb03cdf44a18389a17879e603de1215

date_string=`date +%Y%m%d`

d=/opt/centos/devtoolset-1.1/root/usr/bin
if [ -d $d ] ; then
    PATH=$d:$PATH
    export CC=gcc
    export CXX=g++
    unset LD_LIBRARY_PATH
else
    #export CC=gcc47
    #export CXX=g++47
    #export LD_LIBRARY_PATH
    export CC=gcc47
    export CXX=g++47
    export LD_LIBRARY_PATH
fi

#build_type=enterprise
build_type=community

#tokudbengine_tree=master
#jemalloc_tree=tokudb-7.1.5
#backup_tree=tokudb-7.1.5

tokudbengine_tree=
jemalloc_tree=3.6.0
backup_tree=

mysql=mysql-5.5.39
mysql_tree=

ftindex_tree=

tokudb_version=current.${date_string}
mkdir ${tokudb_version}; pushd ${tokudb_version}
../make.mysql.bash --tokudbengine_tree=${tokudbengine_tree} --ftindex_tree=${ftindex_tree} --mysql=${mysql} --mysql_tree=${mysql_tree} --tokudb_version=${tokudb_version} --jemalloc_tree=${jemalloc_tree} --backup_tree=${backup_tree} --build_type=${build_type} --github_token=${github_token} --cc=${CC} --cxx=${CXX}
scp */*/*linux-x86_64.tar.gz tcallaghan@192.168.1.242:~
popd
