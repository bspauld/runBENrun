#-------------------------------------------------------------------------------
# Name:         ExportGPX.py
# Purpose:      export GPS data from GPX files. Usess gpxpy library
#               gpxpy library - https://github.com/tkrajina/gpxpy
#
#               code assistance from https://gist.github.com/urschrei/5355597 and
#
# Author:       Ben Spaulding
#
# Created:      Feb, 6, 2016
#
#-------------------------------------------------------------------------------

import sys,os,numpy,scipy,gpxpy,csv

inp_dir = 'INPUT Directory'
outputDir = 'OUTPUT Directory'

#file to write to

listing = os.listdir(inp_dir)

for infile in listing:
    inputFilename = infile

    words = infile.split(".")
    newfileName =  str(str(words[0]))

    finalfile = open(outputDir+"/"+newfileName+"_"+"Extract.txt", 'w')

    #initialize counter
    n = 0

    gpx = gpxpy.parse(open(inp_dir+"/"+newfileName+'.gpx'))

    #set global variables - reset for each iteration of the loop
    pointLineTxt = ""
    TimeVal = ""
    DateVal = ""

    finalfile.write('ID,Lat,Lon,Elevation,Date,Time'+'\n')

    for track in gpx.tracks:
        for segment in track.segments:
            for point in segment.points:
                n = n+1
                timeString = str(point.time).split(" ")
                TimeVal = str(str(timeString[0]))
                DateVal = str(str(timeString[1]))

                pointLineTxt = str(str(n)+","+str(point.latitude)+","+str(point.longitude)+","+str(point.elevation)+","+str(TimeVal)+","+str(DateVal))

                finalfile.write(pointLineTxt+'\n')
    print(newfileName+"_"+"Extract.txt Completed")
    finalfile.close()
print("Script Complete")

