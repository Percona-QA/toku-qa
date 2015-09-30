#!/bin/bash
echo "Stopping all mongo processes"
ps -ef |grep [m]ongo | awk '{print $2}' | xargs kill -2 
echo "Cleaning up folders"
read -p "Press any key to continue...Deletes all mongo-node folders... " -n1 -s
rm -rf mongo-node*
rm -rf mongodb-*
echo "Done.."