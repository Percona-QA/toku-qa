#! /bin/bash

$MONGO_DIR/bin/mongo --username=$adminUsername --password=$adminPassword $adminDatabase --eval "printjson(db=db.getSiblingDB(\"${newDatabase}\")); printjson(db.${collectionName}.insert({a:1}))"

