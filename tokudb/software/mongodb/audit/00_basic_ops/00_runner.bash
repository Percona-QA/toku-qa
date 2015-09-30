#! /bin/bash

export testUsername=bob
export testPassword=bob
export testDatabase=test

export adminUsername=admin
export adminPassword=admin
export adminDatabase=admin
export newDatabase=timbo

echo "***********************************************"; echo "01_authenticate.bash"
./01_authenticate.bash

echo "***********************************************"; echo "02_authCheck.bash"
./02_authCheck.bash

export collectionName=foo

echo "***********************************************"; echo "03_createCollection.bash"
./03_createCollection.bash

echo "***********************************************"; echo "04_createDatabase.bash"
./04_createDatabase.bash

export indexName=idx1
export indexNameBackground=idx2Background

echo "***********************************************"; echo "05_createIndex.bash"
./05_createIndex.bash

echo "***********************************************"; echo "06_dropIndex.bash"
./06_dropIndex.bash

export newCollectionName=bar

echo "***********************************************"; echo "07_renameCollection.bash"
./07_renameCollection.bash

echo "***********************************************"; echo "08_dropCollection.bash"
./08_dropCollection.bash

echo "***********************************************"; echo "09_dropDatabase.bash"
./09_dropDatabase.bash



echo "***********************************************"; echo "99_shutdown.bash"
./99_shutdown.bash

