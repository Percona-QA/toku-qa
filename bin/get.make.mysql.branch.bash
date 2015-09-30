#! /bin/bash

if [ $# -eq 0 ]; then
    echo "usage: get.make.mysql.branch.bash <branch>"
    exit 1
fi

branchName=$1

rm -f make.mysql.bash common.sh

wget https://github.com/Tokutek/ft-engine/raw/${branchName}/scripts/make.mysql.bash
wget https://github.com/Tokutek/ft-engine/raw/${branchName}/scripts/common.sh

chmod 755 make.mysql.bash
