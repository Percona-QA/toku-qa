#! /bin/bash

baseDir=~/temp
workingDir=ftbench

pushd ${baseDir}

mkdir ${workingDir}
cd ${workingDir}

git clone https://github.com/Tokutek/ft-index
cd ft-index/third_party
git clone https://github.com/Tokutek/jemalloc
cd ..
mkdir opt
cd opt
cmake -D CMAKE_BUILD_TYPE=Release -D USE_VALGRIND=OFF -D TOKU_DEBUG_PARANOID=OFF -D USE_CTAGS=OFF -D USE_ETAGS=OFF -D USE_GTAGS=OFF -D USE_CSCOPE=OFF -D CMAKE_LINK_DEPENDS_NO_SHARED=ON ..
make -j16 perf_read_write.tdb

popd

