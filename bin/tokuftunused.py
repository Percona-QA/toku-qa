#!/usr/bin/env python
# print unused parts of a fractal tree file as offset size pairs sorted by offset.
# skip offset 0 as it is the fractal tree header.
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
            blocknum = int(l[0])
            assert 0 <= blocknum
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
    holes(bat, btt)
    return 0
def holes(bat, btt):
    lastoffset = 0
    for offset in bat:
        size = btt[offset]
        nextoffset = offset + size
        if lastoffset > 0:
            print lastoffset, offset-lastoffset
        lastoffset = nextoffset
sys.exit(main())
