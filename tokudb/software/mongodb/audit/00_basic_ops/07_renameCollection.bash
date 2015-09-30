#! /bin/bash

$MONGO_DIR/bin/mongo --username=$testUsername --password=$testPassword $testDatabase --eval "printjson(db.${collectionName}.renameCollection(\"${newCollectionName}\"))"
