#! /bin/bash

# create a single custom TokuDB build


#   --ftengine_tree (master, releases/tokudb-7.0, custom)
if [ -z "$ftengine_tree" ]; then
    ftengine_tree=master
fi

#   --ftindex_tree (master, releases/tokudb-7.0, custom)
if [ -z "$ftindex_tree" ]; then
    ftindex_tree=hotIndexingImprovement
fi

#   --mysql (mysql-5.5.30, mariadb-5.5.30, ...), determines which mysql repo we use
if [ -z "$mysql" ]; then
    mysql=mysql-5.5.30
fi

#   --mysql_tree (master, releases/tokudb-7.0, custom)
if [ -z "$mysql_tree" ]; then
    mysql_tree=releases/tokudb-7.0
fi

#   --tokudb_version (part of tarball file name)
if [ -z "$tokudb_version" ]; then
    tokudb_version=zhot
fi


get.make.mysql.bash

mkdir ${tokudb_version}; pushd ${tokudb_version}
../make.mysql.bash --ftengine_tree=${ftengine_tree} --ftindex_tree=${ftindex_tree} --mysql=${mysql} --mysql_tree=${mysql_tree} --tokudb_version=${tokudb_version} --cc=gcc47 --cxx=g++47
scp */*/*linux-x86_64.tar.gz tcallaghan@192.168.1.242:~
popd
