var server = 'localhost:27017';
var threads = 16;
var seconds = 3600;
var ns = 'sysbench.test';
var count = 16 * 1000 * 1000;
var rangeSize = 1000;
var o = {
    ops: [
        {
            ns: ns,
            op: 'findOne',
            query: { _id: { '#RAND_INT': [ 0, count ] } }
        },
        {
            ns: ns,
            op: 'find',
            query: { _id: { '$gte': { '#RAND_INT': [ 0, count - rangeSize ] } } },
            limit: rangeSize
        },
        {
            ns: ns,
            op: 'command',
            command: {
                aggregate: ns,
                pipeline: [
                    { '$match': { _id: { '$gte': { '#RAND_INT': [ 0, count - rangeSize ] } } } },
                    { '$limit': rangeSize },
                    { '$project': { k: 1, _id: 0 } },
                    { '$group': { _id: null, average: { '$sum': '$k' } } }
                ]
            }
        },
        {
            ns: ns,
            op: 'update',
            multi: false,
            upsert: false,
            query: { _id: { '#RAND_INT': [ 0, count ] } },
            update: { '$inc': { k: 1 } }
        }
    ],
    host: server,
    seconds: seconds,
    parallel: threads
};
printjson(benchRun(o));
