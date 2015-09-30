#!/usr/bin/env python 

import os
import sys
import time
import re
import subprocess
import Image

def usage():
    print "create an image representing a Fractal Tree index file"
    print "--ftfile=<FRACTAL TREE INDEX FILE>"
    print "--ftdumpdir=<FTDUMP PATH>"
    print "[--width=IMAGE WIDTH IN PIXELS] (default: 1024)"
    print "[--imagefile=<IMAGE FILE NAME> (default: ft-file-name.png)]"
    return 1

def get_ft_bat(ftfile, ftdumpdir):
    p = subprocess.Popen([ftdumpdir + '/tokuftdump', '--translation-table', ftfile], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    #out, err = p.communicate()
    #print out

    tmpftbat = []

    for line in p.stdout:
        #print line.strip()
        vals = line.strip().split('\t')
        #print vals[0], ':', vals[1], ':', vals[2]
        # we don't want the first line
        #if (int(vals[0]) != 0):
        if ((int(vals[1]) > 0) and (int(vals[2]) > 0)):
            tmpftbat.append([int(vals[0]),int(vals[1]),int(vals[2])])
        
    return sorted(tmpftbat,key=lambda offset: offset[1])
        
def create_ft_image(ftbat, width, imagefile, ftfilesize):
    last_offset = ftbat[len(ftbat)-1][1]
    last_length = ftbat[len(ftbat)-1][2]
    #num_blocks = ((last_offset + last_length) / 4096) + 1
    num_blocks = (ftfilesize / 4096) + 1
    #print "num_blocks = ", num_blocks
    num_image_lines = (num_blocks / width) + 1
    #print "num_image_lines = ", num_image_lines
    last_file_block = (ftfilesize / 4096) + 1
    #print "last_file_block = ", last_file_block
    last_image_block = num_image_lines * width
    #print last_offset+last_length, ' / ', ftfilesize
    #print last_file_block, ' / ', last_image_block
    
    # create a new white image
    img = Image.new('RGB', (width,num_image_lines), "white")
    # create the pixel map
    pixels = img.load()
    
    gray = 0
    
    for i in ftbat:
        starting_block=i[1]/4096
        num_blocks=i[2]/4096
        #print starting_block, '/', num_blocks
        for current_block in range(starting_block, starting_block+num_blocks):
            # translate current_block to (x,y)
            x=current_block/width
            y=current_block%width
            #print current_block, '::', x, ':', y
            if (gray == 0):
                pixels[y,x]=(0,0,0)
                gray = 1
            else:
                pixels[y,x]=(127,127,127)
                gray = 0
                
    # make end of image red (it is unusable space)
    for current_block in range(last_file_block+1, last_image_block):
        # translate current_block to (x,y)
        print current_block
        x=current_block/width
        y=current_block%width
        pixels[y,x]=(255,0,0)
    
    img.save(imagefile)
    print "Created ", imagefile

def main():
    ftfile = None
    imagefile = None
    ftdumpdir = None
    width = 1024

    for a in sys.argv[1:]:
        if a == "-h" or a == "-?" or a == "--help":
            return usage()
        match = re.match("--(.*)=(.*)", a)
        if match:
            exec "%s='%s'" % (match.group(1),match.group(2))
            continue
        return usage()
        
    if imagefile == None:
        imagefile = ftfile + '.png'
        
    if (ftfile == None or imagefile == None or ftdumpdir == None):
        return usage()

    width = int(width)

    if ftdumpdir.endswith('/'):
        ftdumpdir = ftdumpdir[:-1]
            
    ftfilesize = os.path.getsize(ftfile)

    #print "file=", ftfile
    #print "image=", imagefile
    #print "ftdumpdir=", ftdumpdir
    #print "width=", width
    #print "ftfilesize=", ftfilesize

    ftbat = []
    ftbat = get_ft_bat(ftfile, ftdumpdir)
    create_ft_image(ftbat, width, imagefile, ftfilesize)

    return 0

sys.exit(main())
