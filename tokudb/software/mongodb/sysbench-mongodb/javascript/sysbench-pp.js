var server = 'localhost:27017';
var threads = 16;
var seconds = 600;
var ns = 'sbtest.sbtest1';
var count = 1000000;
var o = {
    ops: [
        {
            ns: 'sbtest.sbtest1',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest2',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest3',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest4',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest5',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest6',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest7',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest8',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest9',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest10',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest11',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest12',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest13',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest14',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest15',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: 'sbtest.sbtest16',
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
    ],
    host: server,
    seconds: seconds,
    parallel: threads
};
printjson(benchRun(o));
