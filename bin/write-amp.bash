#! /bin/bash

bytesLeafNotCheckpoint=`grep "brt: leaf nodes flushed to disk (not for checkpoint) (bytes)" *.engine_status | tail -n 1 | cut -f3`
bytesNonLeafNotCheckpoint=`grep "brt: nonleaf nodes flushed to disk (not for checkpoint) (bytes)" *.engine_status | tail -n 1 | cut -f3`
bytesLeafCheckpoint=`grep "brt: leaf nodes flushed to disk (for checkpoint) (bytes)" *.engine_status | tail -n 1 | cut -f3`
bytesNonLeafCheckpoint=`grep "brt: nonleaf nodes flushed to disk (for checkpoint) (bytes)" *.engine_status | tail -n 1 | cut -f3`

bytesLeafNotCheckpointUncompressed=`grep "brt: leaf nodes flushed to disk (not for checkpoint) (uncompressed bytes)" *.engine_status | tail -n 1 | cut -f3`
bytesNonLeafNotCheckpointUncompressed=`grep "brt: nonleaf nodes flushed to disk (not for checkpoint) (uncompressed bytes)" *.engine_status | tail -n 1 | cut -f3`
bytesLeafCheckpointUncompressed=`grep "brt: leaf nodes flushed to disk (for checkpoint) (uncompressed bytes)" *.engine_status | tail -n 1 | cut -f3`
bytesNonLeafCheckpointUncompressed=`grep "brt: nonleaf nodes flushed to disk (for checkpoint) (uncompressed bytes)" *.engine_status | tail -n 1 | cut -f3`

bytesLogged=`grep "logger: writes (bytes)" *.engine_status | tail -n 1 | cut -f3`

rowsInserted=`grep Handler_write *.writecap | tail -n 1 | cut -d \| -f 3`
bytesInserted=`expr $rowsInserted \* 28`

echo ${bytesLeafNotCheckpoint}
echo ${bytesNonLeafNotCheckpoint}
echo ${bytesLeafCheckpoint}
echo ${bytesNonLeafCheckpoint}
echo ${bytesLeafNotCheckpointUncompressed}
echo ${bytesNonLeafNotCheckpointUncompressed}
echo ${bytesLeafCheckpointUncompressed}
echo ${bytesNonLeafCheckpointUncompressed}
echo ${bytesLogged}
echo ${bytesInserted}
