import random
from bson import Binary
import pymongo, bson

max_index = 10

db = pymongo.Connection().compaction_test
db.numbers.ensure_index([('parent', pymongo.ASCENDING)])
db.numbers.ensure_index([('checksum', pymongo.ASCENDING)], unique=True)

# Random data stream
data = " "  * 4000000
data_len = len(data)


def insert_chunks(index):
    checksums = []
    for _ in xrange(60):
        length = random.randrange(0, data_len)
        checksum = random.randrange(6000)
        checksums.append(checksum)
        db.numbers.insert({'parent': [index],
                           'checksum': checksum,
                           'data': Binary(data[0:length])}, w=0)
    db.numbers.update({'checksum': {'$in': checksums}}, {'$addToSet': {'parent': index}}, multi=True)


def remove_chunks(index):
    db.numbers.update({'parent': index}, {'$pull': {'parent': index}}, multi=True)
    db.numbers.remove({'parent': {'$size':0}}, w=0)


if __name__ == '__main__':
    indices = list(db.numbers.distinct('parent'))

    if not indices:
        for i in xrange(16):
            item = random.randrange(1000)
            print "Inserted %s blob index: %s" % (i, item)
            insert_chunks(item)

    while True:
        indices = list(db.numbers.distinct('parent'))
        item = indices[random.randrange(len(indices))]

        # Remove item
        remove_chunks(item)

        #insert item
        insert_chunks(item)

        print "Item %s removed and readded" % item
