#!/usr/bin/env python 

import os
import sys
import time
import re

unknownToken=-100000000.999

def usage():
    print "compare output of two toku[mx]stat.py files"
    print "usage 2compare.py file1 file2"
    return 1


def get_vars(input_file):
    print "processing %s" % (input_file)
    tmpDict = {}
    skipLines = 0

    ins = open(input_file, "r")
    for line in ins:
        if (skipLines > 0):
            skipLines -= 1
        elif (line.strip() == "******************************"):
            skipLines = 2
        elif (line.strip() == "Type\tName\tStatus"):
            skipLines = 0
        elif (line.strip() != ""):
            #print "non-empty line: %s" % (line) ,
            vals = line.strip().split('\t')
            thisKey = vals[1]
            thisValue = vals[2]
            if tmpDict.has_key(thisKey):
                # update existing key
                tmpDict[thisKey]['end'] = thisValue
            else:
                # insert new key
                tmpDict[thisKey] = {'start':thisValue, 'end':thisValue}
    ins.close()

    return tmpDict


def diff_vars(vars1, vars2):
    tmpDiff = []

    # compare matched keys
    for k in sorted(vars1):
        if (k in vars2):
            try:
                v1 = float(vars1[k]['end'])-float(vars1[k]['start'])
                v2 = float(vars2[k]['end'])-float(vars2[k]['start'])
                if ((v2 == 0) and (v1 == 0)):
                    pctDiff = 0
                elif (v2 != 0):
                    pctDiff = ((v2 - v1) / v2) * 100.0
                else:
                    pctDiff = 100.0
                if (v1 != v2):
                    # only want to show differences
                    tmpDiff.append([k,v1,v2,pctDiff,abs(pctDiff)]) 
            except ValueError:
                tmpDiff.append([k,vars1[k]['end'],vars2[k]['end'],unknownToken,abs(unknownToken)])

    return sorted(tmpDiff,key=lambda offset: offset[4])
        
def main():
    file1 = None
    file2 = None

    if (len(sys.argv) != 3):
        return usage()

    file1 = sys.argv[1]
    file2 = sys.argv[2]

    #ftfilesize = os.path.getsize(ftfile)

    print ""

    # read in file1
    vars1 = {}
    vars1 = get_vars(file1)
    # read in file2
    vars2 = {}
    vars2 = get_vars(file2)

    results = []
    results = diff_vars(vars1, vars2)

    print ""
    print "NOTE: suppressing unchanged values"

    for i in results:
        if (i[3] == unknownToken):
            print "%12s : %-80s : %25s : %25s" % ("UNKNOWN", i[0], i[1], i[2])
        else:
            print "%12.1f : %-80s : %25.1f : %25.1f" % (i[3], i[0], i[1], i[2])

    # look for keys only in file1
    for k in sorted(vars1):
        if (k not in vars2):
            print "file2 is missing %s" % (k)

    # look for keys only in file2
    for k in sorted(vars2):
        if (k not in vars1):
            print "file1 is missing %s" % (k)
            
    print ""

    return 0

sys.exit(main())
