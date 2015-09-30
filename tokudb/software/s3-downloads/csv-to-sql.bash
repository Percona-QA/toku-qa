#! /bin/bash

firstLine=Y

while read line; do
    if [ $firstLine == "Y" ]; then
        firstLine=N
    else
        dt=`echo $line | cut -d, -f1`
        ip=`echo $line | cut -d, -f2`
        fn=`echo $line | cut -d, -f3`
        echo "insert into package_downloads (download_datetime, download_ip, download_filename) values ('$dt','$ip','$fn');" >> inserts-$2.sql
    fi
done < "$1"
