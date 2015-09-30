var maxIndexedField = 100000;

var numDocuments = myGlobalEnv.numDocuments;
var charLength = myGlobalEnv.charLength;

var startMillis, endMillis;

function randomString(len) {
    var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz";
    var randomstring = '';
    for (var i=0; i<len; i++) {
        var rnum = Math.floor(Math.random() * chars.length);
        randomstring += chars.substring(rnum,rnum+1);
    }
    return randomstring;
}

db.update_collection.drop();
db.update_collection.ensureIndex({ indexedField: 1 });

startMillis = (new Date()).getTime();

for(var i=0; i<numDocuments; i++) {
    db.update_collection.insert({_id:i, unIndexedField:0, indexedField:Math.floor((Math.random()*maxIndexedField)+1), charField:randomString(charLength)});
}

endMillis = (new Date()).getTime();
elapsedMillis = endMillis - startMillis;
elapsedSeconds = Math.floor((endMillis - startMillis)/1000);
insertsPerSecond = Math.floor(numDocuments / elapsedMillis * 1000);
 
print("... inserted " + numDocuments + " documents in " + elapsedSeconds + " second(s) at " + insertsPerSecond + " inserts/second.");

