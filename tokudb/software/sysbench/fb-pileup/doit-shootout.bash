#!/bin/bash

export SCP_FILES=Y
export DIRECTIO=Y
export INNODB_CACHE=16G
export TOKUDB_DIRECTIO_CACHE=16G
export TOKUDB_COMPRESSION=quicklz
export NUM_ROWS=250000
export NUM_TABLES=16
export RUN_TIME_SECONDS=300
export RAND_TYPE=uniform
export TOKUDB_READ_BLOCK_SIZE=64K
export BENCHMARK_NUMBER=007
#export threadCountList="0001 0004 0016 0064 0128 0256 0512 1024"
export threadCountList="0001 0002 0004 0008 0016 0032 0064 0128 0256 0512 1024"


# TokuDB 717
export TARBALL=blank-toku717-mysql-5.5.38
export BENCH_ID=717.${TOKUDB_COMPRESSION}.4mm
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.38
export MYSQL_STORAGE_ENGINE=tokudb
./doit.bash

# TokuDB 750
export TARBALL=blank-tokudb.current.20140828-mysql-5.5.39
export BENCH_ID=750.${TOKUDB_COMPRESSION}.4mm
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.39
export MYSQL_STORAGE_ENGINE=tokudb
./doit.bash

# TokuDB 750 - clustered secondary
export TARBALL=blank-tokudb.current.20140828-mysql-5.5.39
export BENCH_ID=750.clustered.${TOKUDB_COMPRESSION}.4mm
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.39
export MYSQL_STORAGE_ENGINE=tokudb_clustered
./doit.bash

# InnoDB 5.5.39
export TARBALL=blank-mysql5539
export BENCH_ID=5539.4mm
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.39
export MYSQL_STORAGE_ENGINE=innodb
./doit.bash

# InnoDB 5.5.39 - no AHI
export TARBALL=blank-mysql5539
export BENCH_ID=5539noAHI.4mm
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.5.39
export MYSQL_STORAGE_ENGINE=innodb
export DISABLE_AHI=Y
./doit.bash
unset DISABLE_AHI

# InnoDB 5.6.20
export TARBALL=blank-mysql5620
export BENCH_ID=5620.4mm
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.6.20
export MYSQL_STORAGE_ENGINE=innodb
./doit.bash

# InnoDB 5.6.20 - no AHI
export TARBALL=blank-mysql5620
export BENCH_ID=5620noAHI.4mm
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.6.20
export MYSQL_STORAGE_ENGINE=innodb
export DISABLE_AHI=Y
./doit.bash
unset DISABLE_AHI

# InnoDB 5.7.4.m14
export TARBALL=blank-mysql574m14
export BENCH_ID=574m14.4mm
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.7.4.m14
export MYSQL_STORAGE_ENGINE=innodb
./doit.bash

# InnoDB 5.7.4.m14 - no AHI
export TARBALL=blank-mysql574m14
export BENCH_ID=574m14noAHI.4mm
export MYSQL_NAME=mysql
export MYSQL_VERSION=5.7.4.m14
export MYSQL_STORAGE_ENGINE=innodb
export DISABLE_AHI=Y
./doit.bash
unset DISABLE_AHI
