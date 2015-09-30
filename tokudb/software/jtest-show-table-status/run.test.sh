#! /bin/bash

storage_engine=tokudb
logfile_name=test-output.log

mysql --user=root --socket=/tmp/mysql.sock test < schema_${storage_engine}.sql
ant clean default run | tee ${logfile_name}
