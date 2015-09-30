#! /bin/bash

inputFile=$1

#rm fileSingle.gz fileMultiple.gz
rm fileMultiple.gz
rm -f TOKUMX-COMPRESSION-TEST*

split -a 8 -b 64k -d ${inputFile} TOKUMX-COMPRESSION-TEST-
gzip -5 -c TOKUMX-COMPRESSION-TEST-* > fileMultiple.gz

rm -f TOKUMX-COMPRESSION-TEST-*

#gzip -c ${inputFile} > fileSingle.gz

ls -lh *.gz
ls -lh $1
