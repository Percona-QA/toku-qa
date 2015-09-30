import random
from bson import Binary
import pymongo, bson

max_index = 10

db = pymongo.Connection().compaction_test
db.numbers.ensure_index([('parent', pymongo.ASCENDING)])
db.numbers.ensure_index([('checksum', pymongo.ASCENDING)], unique=True)
db.parents.ensure_index([('index', pymongo.ASCENDING)], unique=True)

# Random data stream
data = " "  * 4000000
data_len = len(data)


def insert_chunks(parent):
    checksums = []
    for i in xrange(60):
        length = random.randrange(0, data_len)
        checksum = random.randrange(6000)
        checksums.append(checksum)
        db.numbers.insert({'parent': [parent['index']],
                           'checksum': checksum,
                           'data': Binary(data[0:length])}, w=0)
    db.numbers.update({'checksum': {'$in': checksums}}, {'$addToSet': {'parent': parent['index']}}, multi=True)


def create_blob(index):
    parent = {'index': index,
              'salt': Binary(data[0:random.randrange(1000, 1000000)])}
    insert_chunks(parent)
    db.parents.insert(parent, w=0)


def remove_blob(index):
    parent = db.parents.find_one({'index': index})
    db.numbers.update({'parent': parent['index']}, {'$pull': {'parent': parent['index']}}, multi=True)
    db.numbers.remove({'parent': {'$size':0}}, w=0)
    db.parents.remove(parent, w=0)


if __name__ == '__main__':
    indices = list(db.parents.distinct('index'))
    numOps = 0

    if not indices:
        for i in xrange(16):
            item = random.randrange(1000)
            print "Inserted %s blob index: %s" % (i, item)
            create_blob(item)

    while True:
        indices = list(db.parents.distinct('index'))
        item = indices[random.randrange(len(indices))]

        # Remove item
        remove_blob(item)

        #insert item
        create_blob(item)
        
        numOps += 1

        print "(%d) Item %s removed and readded" % (numOps, item)
