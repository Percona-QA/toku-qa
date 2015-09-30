#!/usr/bin/env python
# print block allocation table as offset size pairs sorted by offset
import sys
def main():
    btt = {}
    while 1:
        b = sys.stdin.readline()
        if b == "":
            break
        l = b.split()
        if len(l) != 3:
            continue
        try:
            offset = int(l[1])
            if offset < 0:
                continue
            size = int(l[2])
            assert not btt.has_key(offset)
            btt[offset] = size
        except:
            pass
    bat = btt.keys()
    bat.sort()
    for offset in bat:
        print offset, btt[offset]
    return 0
sys.exit(main())
