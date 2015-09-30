#!/bin/bash -ex
workingdir=`pwd`
nodedirectory='mongo-node'
 
#!/bin/bash
echo "Checking if mongo is downloaded"
if [ ! -f "mongodb-osx-x86_64-2.6.1.tgz" ]; then
  rm -rf mongodb-2-6-1
  wget http://fastdl.mongodb.org/osx/mongodb-osx-x86_64-2.6.1.tgz
fi
echo "Unzip and Setup MongoDB"
if [ ! -d "mongodb-2-6-1" ]; then
	tar -xvf mongodb-osx-x86_64-2.6.1.tgz
	mv mongodb-osx-x86_64-2.6.1 mongodb-2-6-1
	echo "Setting up nodes"
	for i in {1..10}
	do	
    cd $workingdir
		mongo_port=`expr 10000 + $i`
		nodeid=$nodedirectory$i
		mkdir $nodeid
		cd $nodeid
		mkdir data
		mkdir log
		$workingdir/mongodb-2-6-1/bin/mongod --dbpath=$workingdir/$nodeid/data --logpath=$workingdir/$nodeid/log/mongo.log --fork --port=$mongo_port --replSet snow
	done
fi	
echo "Waiting for all nodes to initialize.."
sleep 5
$workingdir/mongodb-2-6-1/bin/mongo localhost:10001 $workingdir/initialize-replicaset.js
