#!/usr/bin/python2.7

import sys 

if (len(sys.argv) > 6): 
 print ""
 print "This script takes one mandatory argument, the name of a file containing"
 print "data to be plotted.  It takes up to four optional arguments as follows:"
 print " 1) the number of points before a data point to add into average."
 print " 2) the number of points after a data point to add into average."
 print " 3) the column number of y data (first column is column 1)"
 print " 4) the column number of x data (first column is column 1)"
 print ""
 exit()

# set variable defaults
box_back = 10   # number of points before current point to add into average
box_front = 10  # number of points after current point to add into average
y_col = 2       # column number of y data (first column is column 1)
x_col = 1       # column number of x data (first column is column 1)

# assign variables from command line arguments
inputFileName = str(sys.argv[1])
if (len(sys.argv) > 2): 
 box_back = int(sys.argv[2])
if (len(sys.argv) > 3): 
 box_front = int(sys.argv[3])
if (len(sys.argv) > 4): 
 y_col = int(sys.argv[4])
if (len(sys.argv) > 5): 
 x_col = int(sys.argv[5])

# open input file
f = open(inputFileName)

# make list from lines in file
lines = f.readlines()

# make sure boxcar average will work
if ((box_back + box_front + 1) > len(lines)):
 print ""
 print "ERROR: too many points for boxcar averaging."
 print ""
 exit()

# this is the number of points encompassed in the boxcar average
num_points = box_back + box_front + 1 

# this variable is the running sum.
sum_vals = 0

# add up values for first boxcar average
for i_ in range(0,num_points):
 sum_vals += float(lines[i_].split()[y_col-1])
print float(lines[box_back].split()[x_col-1]),sum_vals/num_points

# each subsequent average differs only in the first and last points from the
# previous average.
for i_ in range(box_back+1,len(lines)-box_front):
 sum_vals += float(lines[i_+box_front].split()[y_col-1])
 sum_vals -= float(lines[i_-box_back-1].split()[y_col-1])
 print float(lines[i_].split()[x_col-1]),sum_vals/num_points
