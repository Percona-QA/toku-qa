#!/bin/bash

# 1 : v663   : tpcc-663.51530.zlib.64k
# 2 : holep  : tpcc-5865b.51958.zlib.64k
# 3 : fastcp : tpcc-fastcp.51958.zlib.64k
# 4 : comp   : tpcc-compaction.51995.zlib.64k
# 5 : hpac   : tpcc-hpac.52045.zlib.64k

rm -f 1.txt 2.txt 3.txt 4.txt 5.txt

parse_tpcc.pl tps *tpcc-663.51530.zlib.64k
mv *.tps 1.txt

parse_tpcc.pl tps *tpcc-5865b.51984.zlib.64k
mv *.tps 2.txt

parse_tpcc.pl tps *tpcc-fastcp.51987.zlib.64k
mv *.tps 3.txt

parse_tpcc.pl tps *tpcc-compaction.51995.zlib.64k
mv *.tps 4.txt

parse_tpcc.pl tps *tpcc-hpac.52045.zlib.64k
mv *.tps 5.txt