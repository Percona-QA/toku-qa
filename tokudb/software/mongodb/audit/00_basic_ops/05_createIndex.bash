#! /bin/bash

$MONGO_DIR/bin/mongo --username=$testUsername --password=$testPassword $testDatabase --eval "printjson(db.${collectionName}.ensureIndex({a:1},{clustering:true, compression:'lzma', name:\"${indexName}\"}))"

$MONGO_DIR/bin/mongo --username=$testUsername --password=$testPassword $testDatabase --eval "printjson(db.${collectionName}.ensureIndex({b:1},{clustering:true, background:true, compression:'lzma', name:\"${indexNameBackground}\"}))"
