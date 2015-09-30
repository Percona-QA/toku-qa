#!/bin/bash

DATE=`date +"%Y%m%d"`
dumpFileName="./cdash-${DATE}.sql"

pushd /mnt/2tb/backups/cdash

#~/benchdb/bin/mysqldump --user=root --host=lex1 --port=33305 cdash | gzip > ./cdash-$DATE.sql.gz

echo "Creating myqsldump of cdash database"
time mysqldump --user=root --host=lex1 --port=33305 cdash > ${dumpFileName}
echo "Compressing LZMA2 deault compression level"
time 7z a -m0=lzma2 cdash-$DATE.sql.7z ${dumpFileName}

rm ${dumpFileName}

popd
