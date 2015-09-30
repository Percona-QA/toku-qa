#! /bin/bash

rm -f make.mysql.bash common.sh

wget --no-check-certificate https://github.com/Tokutek/tokudb-engine/raw/master/scripts/make.mysql.bash
wget --no-check-certificate https://github.com/Tokutek/tokudb-engine/raw/master/scripts/common.sh
wget --no-check-certificate https://github.com/Tokutek/tokudb-engine/raw/master/scripts/make.mysql.debug.env.bash

#wget https://github.com/Tokutek/tokudb-engine/raw/master/scripts/make.mysql.bash
#wget https://github.com/Tokutek/tokudb-engine/raw/master/scripts/common.sh
#wget https://github.com/Tokutek/tokudb-engine/raw/master/scripts/make.mysql.debug.env.bash

chmod 755 make.mysql.bash
chmod 755 make.mysql.debug.env.bash
