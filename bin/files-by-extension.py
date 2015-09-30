#! /usr/bin/python

import os
import collections
import locale

locale.setlocale(locale.LC_ALL, '')

extensionsCount = collections.defaultdict(int)
extensionsSize = collections.defaultdict(int)

for path, dirs, files in os.walk('.'):
   for filename in files:
       thisExtension=os.path.splitext(filename)[1].lower()
       if (thisExtension == ''):
           thisExtension = filename
       extensionsCount[thisExtension] += 1
       extensionsSize[thisExtension] += os.path.getsize(os.path.join(path,filename))

# unsorted
#for key,value in extensionsCount.items():
#    thisMB = extensionsSize[key] / 1024.0 / 1024.0
#    print key, ', ', format(value,"n"), ' file(s), ', ('%.2f' % thisMB), ' MB'

for w in sorted(extensionsSize, key=extensionsSize.get, reverse=True):
    thisCount = extensionsCount[w]
    thisMB = extensionsSize[w] / 1024.0 / 1024.0
    print w, ', ', format(thisCount,"n"), ' file(s), ', ('%.2f' % thisMB), ' MB'
