
numDatabases = 1;
numDocumentsPerCollection = 500;

collections = [];
for ( var i=0; i<numDatabases; i++ ) {
    collections.push( db.getSisterDB("mms" + i).things );
}

base = { h : {} };
for ( h=0; h<24; h++ ) {
    base.h[h] = {};
    for ( min=0; min<60; min++ ) {
        base.h[h][min] = { n : 0 , t : 0 };
    }
}

ops = [];

for ( var i=0; i<collections.length; i++ ){
    t = collections[i];

    if ( t.count() != numDocumentsPerCollection ) {

        // drop
        t.drop();

        // insert docs
        for ( var j=0; j<numDocumentsPerCollection; j++ ) {
            base._id = j;
            t.insert( base );
        }
        t.getDB().getLastError();
    }
    // set up ops for load

    ops.push( { op : "update" ,
                ns : t.getFullName() ,
                query : { _id : { "#RAND_INT" : [ 0 , numDocumentsPerCollection ] } } ,
                update : { $inc : { "h.23.59.n" : 1 , "h.23.59.t" : 5 } }
              } );
}

//res = db.adminCommand( { _cpuProfilerStart : { profileFilename : "foo.prof" } } )
//printjson( res );

threads = [ 4 ];
for ( var i=0; i<threads.length; i++ ) {
    res = benchRun( { ops : ops , seconds : 20 , parallel : threads[i] , host : db.getMongo().host } );

    print( threads[i] + "\t" + res.update );
}


//res = db.adminCommand( { _cpuProfilerStop : 1 } )
//printjson( res );
