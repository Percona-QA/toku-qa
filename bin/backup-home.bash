#!/bin/bash

DATE=`date +"%Y%m%d"`
tarFileName="/mnt/2tb/tcallaghan/home-directory-backups/${DATE}.tar"

cd

tar cvf ${tarFileName} .
