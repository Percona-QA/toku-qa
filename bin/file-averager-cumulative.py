#!/usr/bin/python2.7

import sys 

if (len(sys.argv) > 6): 
 print ""
 print "This script takes one mandatory argument, the name of a file containing"
 print "data to be plotted.  It takes up to two optional arguments as follows:"
 print " 1) the column number of y data (first column is column 1)"
 print " 2) the column number of x data (first column is column 1)"
 print ""
 exit()

# set variable defaults
y_col = 2       # column number of y data (first column is column 1)
x_col = 1       # column number of x data (first column is column 1)

# assign variables from command line arguments
inputFileName = str(sys.argv[1])
if (len(sys.argv) > 2): 
 y_col = int(sys.argv[2])
if (len(sys.argv) > 3): 
 x_col = int(sys.argv[3])

sum_vals = 0
num_points = 0

f = open(inputFileName)
for line in f.readlines():
 sum_vals += float(line.split()[y_col-1])
 num_points += 1
 print line.split()[x_col-1],sum_vals/num_points
