#!/bin/bash

export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.37
export MYSQL_DATABASE=compression
export MYSQL_USER=root

# tokudb
#export MYSQL_STORAGE_ENGINE=tokudb
#export TARBALL=blank-toku710-mysql-5.5.30

#export TOKUDB_COMPRESSION=zlib
#export TOKUDB_READ_BLOCK_SIZE=64K
#export TOKUDB_ROW_FORMAT=tokudb_${TOKUDB_COMPRESSION}
#./run.load.bash

# innodb
export TARBALL=blank-mysql5537

#export MYSQL_STORAGE_ENGINE=innodb_none
#./run.load.bash

export MYSQL_STORAGE_ENGINE=innodb_8
./run.load.bash

#export MYSQL_STORAGE_ENGINE=innodb_4
#./run.load.bash

#export MYSQL_STORAGE_ENGINE=innodb_2
#./run.load.bash

#export MYSQL_STORAGE_ENGINE=innodb_1
#./run.load.bash
