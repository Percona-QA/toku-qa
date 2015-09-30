"use admin;"
 
cfg = {"_id" : "snow", "members" : [ 
				{ "_id" : 0, "host" : "localhost:10001"}, 
				{ "_id" : 1, "host" : "localhost:10002"}, 
				{ "_id" : 2, "host" : "localhost:10003"}, 
				{ "_id" : 3, "host" : "localhost:10004"}, 
				{ "_id" : 4, "host" : "localhost:10005"}, 
				{ "_id" : 5, "host" : "localhost:10006"}, 
				{ "_id" : 6, "host" : "localhost:10007"}, 
				{ "_id" : 7, "host" : "localhost:10008", "votes":0}, 
				{ "_id" : 8, "host" : "localhost:10009", "votes":0}, 
				{ "_id" : 9, "host" : "localhost:10010", "votes":0} 
				] 
			};
 
rs.initiate(cfg);
 
print("Waiting for Replica-Set to initialize..");
var rsState = rs.status().myState;
do 
 {  
	rsState = rs.status().myState;
 }
while (rsState == undefined)
 
printjson(rs.status());
print("Replica-Set initialized..")