var numDocuments = myGlobalEnv.numDocuments;
var numUpdates = myGlobalEnv.numUpdates;

var startMillis, endMillis;
var thisId;

startMillis = (new Date()).getTime();

for(var i=0; i<numUpdates; i++) {
    thisId = Math.floor((Math.random()*numDocuments)+1);
    db.update_collection.update({_id:thisId}, {$inc: {unIndexedField:1}},false, false);
}

endMillis = (new Date()).getTime();
elapsedMillis = endMillis - startMillis;
elapsedSeconds = Math.floor((endMillis - startMillis)/1000);
updatesPerSecond = Math.floor(numUpdates / elapsedMillis * 1000);
 
print("... updated " + numUpdates + " documents in " + elapsedSeconds + " second(s) at " + updatesPerSecond + " updates/second.");

localDb=db.getSiblingDB("local");
oplogSize=localDb.oplog.rs.stats().size;
oplogEntries=localDb.oplog.rs.stats().count;
bytesPerUpdate=Math.floor(oplogSize / oplogEntries);

print("... " + bytesPerUpdate + " oplog bytes/update.");
