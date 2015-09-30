var server = 'localhost:27017';
var count = 20 * 1000000;
var max_a = 100000;
var threads = 8;
var ns = 'sysbench.test';


function randomString() {
        var chars =
"0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz";
        var randomstring = '';
        var string_length = 100+Math.floor(Math.random()*200);
        for (var i=0; i<string_length; i++) {
                var rnum = Math.floor(Math.random() * chars.length);
                randomstring += chars.substring(rnum,rnum+1);
        }
        return randomstring;
}
> for(var i=0; i<20000000; i++){db.test.save({x:i, data=randomString()});}

Is this what you were hoping to accomplish?


db.bench.ensureIndex({ a: 1 });

for (var i = 0; i < count; i++) {
    db.collection.insert({ a: i, count: 0 });
}

res = benchRun( {
    ops : [ {
        ns : ns,
        op : "insert",
        doc : { a : { "#RAND_STRING" : [ max_a ] } }
    } ] ,
    host: server,
    parallel : threads,
    seconds : 1 ,
    safe : true,
    totals : true
} );
print( "threads: 2\t insert/sec: " + res.insert );


ar hostAndPort = 'localhost:27017';
var threads = 8;
var ns = 'test.collection';
var count = 20 * 1000 * 1000;
var seconds = 3600;
var o = {
    ops: [
    {
        ns: ns,
        op: 'update',
        query: { a: { '#RAND_INT': [ 0, count ] } },
        update: { $inc: { count: 1 } }
    },
    {
        ns: ns,
        op: 'findOne',
        query: { a: { '#RAND_INT': [ 0, count ] } }
    }
    ],
    host: hostAndPort,
    seconds: seconds,
    parallel: threads
}