#! /bin/bash

mongoDir=/home/tcallaghan/svn/mongodb-2.2
mongoDatabase=mydb
mongoCollection=tokubench
mongoIndexVersion=1
backgroundBuild=true

#${mongoDir}/mongo ${mongoDatabase} --eval "show collections"

time ${mongoDir}/mongo ${mongoDatabase} --eval "db.${mongoCollection}.ensureIndex({creation : 1}, {background : ${backgroundBuild}, v : ${mongoIndexVersion}})"
#time ${mongoDir}/mongo ${mongoDatabase} --eval "db.${mongoCollection}.ensureIndex({name : 1}, {background : ${backgroundBuild}, v : ${mongoIndexVersion}})"
#time ${mongoDir}/mongo ${mongoDatabase} --eval "db.${mongoCollection}.ensureIndex({origin : 1}, {background : ${backgroundBuild}, v : ${mongoIndexVersion}})"
#time ${mongoDir}/mongo ${mongoDatabase} --eval "db.${mongoCollection}.ensureIndex({uri : 1}, {background : ${backgroundBuild}, v : ${mongoIndexVersion}})"
