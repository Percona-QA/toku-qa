#!/bin/bash

$MONGO_DIR/bin/mongo admin --eval "printjson(db.runCommand({setParameter:1,fastUpdates:false}))"