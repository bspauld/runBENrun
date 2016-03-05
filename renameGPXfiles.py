#-------------------------------------------------------------------------------
# Name:         renameGPXfiles.py
# Purpose:      Rename GPXfiles in set directory
#
# Author:       Ben Spaulding
#
# Created:      Feb, 6, 2016
#-------------------------------------------------------------------------------


import os
import sys


path="LOCATION OF INPUT DATA"


listing = os.listdir(path)


for infile in listing:
    inputFilename = infile
    basename = path+'/'+infile
    words = infile.split("-")
    newfileName =  str(str(words[1])+"_"+str(words[2])+"_"+str(words[3])+".gpx")

    newname = path+'/'+newfileName
    os.rename(basename,newname)

print('Script Complete')

