#! /bin/bash

export testUsername=bob
export testPassword=bob

export adminUsername=admin
export adminPassword=admin
export adminDatabase=admin

export newDatabase=timbo

export collectionName=testCollectionName

echo "***********************************************"; echo "01_createDatabase.bash"
./01_createDatabase.bash

echo "***********************************************"; echo "02_addUser.bash"
./02_addUser.bash

export testPassword=bob2

echo "***********************************************"; echo "02_changeUserPassword.bash"
./03_changeUserPassword.bash

export logMessage="this message should appear in the audit log"

echo "***********************************************"; echo "04_logApplicationMessage.bash"
./04_logApplicationMessage.bash

echo "***********************************************"; echo "05_removeUser.bash"
./05_removeUser.bash



echo "***********************************************"; echo "99_shutdown.bash"
./99_shutdown.bash

