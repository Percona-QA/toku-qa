var ns = 'test.a';
var count = 10 * 1000 * 1000;
var num_threads = 32;

var o = {
    ops: [ {
        ns: ns,
        op: 'findOne',
        query: { _id: { '#RAND_INT': [ 0, count ] } }
    } ],
    host: 'localhost:29000',
    seconds: 3600,
    parallel: num_threads
}
benchRun(o);
