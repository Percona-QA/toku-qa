#! /bin/bash

$MONGO_DIR/bin/mongo --username=$adminUsername --password=$adminPassword $adminDatabase --eval "printjson(db.shutdownServer())"
