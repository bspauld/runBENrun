#-------------------------------------------------------------------------------
# Name:        TCXtoText.py
# Purpose:     Simple script to convert all of my renamed TCX files into a text file
#
#               User will need to set the input file(s) directory (line 47),
#               and output file(s) directory (line 53)
#
# Author:      Benjamin Spaulding - @gisdoctor
#
# Created:     October/2016

#       tcx parser based on https://github.com/jhofman/fitnesshacks
#
#       Code requires following python libraries:
#
#       Fiona - http://toblerity.org/fiona/manual.html
#       Shapely - http://toblerity.org/shapely/manual.html
#       pyproj - https://pypi.python.org/pypi/pyproj/
#-------------------------------------------------------------------------------

import os, sys, re
from xml.etree.ElementTree import fromstring
import fiona
from fiona.crs import from_epsg
from shapely.geometry import mapping, Point, LineString
import pyproj
import datetime as dt
from datetime import timedelta,datetime

#Set Parameters for Geographic Transformation
geod = pyproj.Geod(ellps='WGS84')

#function to return the data in the specific TCX tags - code from https://github.com/jhofman/fitnesshacks
def findtext(e, name, default=None):
    """
    findtext
    helper function to find sub-element of e with given name and
    return text value
    returns default=None if sub-element isn't found
    """
    try:
        return e.find(name).text
    except:
        return default

#input data path - where all the TCX renamed files live
path = 'inputpath'

#Set RunID
RunID = 1

#output folder
outpath =  'outputpath

#outputPointsTXT = 'C:/Work/Projects/runBENrun/Data/output/PointsText/'
outputPointsTXT = open(outpath+'rBr_Points2016.txt', 'a' )
outputPointsTXT.write('RunID,idvalList,DateVal,AltitudeMeters,finaldistancebtwPoints,finalSpeed,finaldistanceCounter,finaldistanceCounterFeet,finaldistanceCounterMiles,finaltimeCounter,finalSplitFlagDist,finalSplitFlagTime,Lat,Lon\n')


listing = os.listdir(path)

for infile in listing:

    #build empty list
    datalist = []

    #Input file TCX file
    inputFile = infile
    outputShapefileName = (infile.split("."))[0]

    print("Proccesing "+outputShapefileName + " Run")

    istream = open(path+'/'+inputFile,'r')

    #initialize an ID counter
    idval = 0

    # read xml contents
    xml = istream.read()

    # parse tcx file
    xml = re.sub('xmlns=".*?"','',xml)

    # parse xml
    tcx=fromstring(xml)

    #pull the activity type from the TCX file
    activity = tcx.find('.//Activity').attrib['Sport']

    #output crs
    crs = fiona.crs.from_epsg(4326)

    print ("    Start TCX Extraction")
    print ("    Run ID: " + str(RunID))

    #build a list for all the points from the TCX file
    for lap in tcx.findall('.//Lap/'):

        for point in lap.findall('.//Trackpoint'):

            idval = idval + 1
            timestamp = findtext(point, 'Time')
            AltitudeMeters = float(findtext(point, 'AltitudeMeters'))
            DistanceMeters = float(findtext(point, 'DistanceMeters'))

            LatitudeDegrees = float(findtext(point, 'Position/LatitudeDegrees'))
            LongitudeDegrees = float(findtext(point, 'Position/LongitudeDegrees'))

            datalist.append((idval,timestamp,AltitudeMeters,DistanceMeters,LatitudeDegrees,LongitudeDegrees))

    #set counters as global variables
    distanceCounter = 0.0
    timeCounter = datetime.strptime(str("0.0"), "%S.%f")
    timeCounterSecs = 0

    #move through the TCX file to calculate run values and append a Text file
    for i in range(len(datalist)):
            if i < (len(datalist))-1:
                idvalList = datalist[i][0]
                timestampList = datalist[i][1]
                timestampList2 = datalist[i+1][1]
                AltitudeMetersList = datalist[i][2]
                DistanceMetersList  = datalist[i][3]

                #set coordinates for first point
                LatitudeDegreesList = datalist[i][4]
                LongitudeDegreesList = datalist[i][5]

                #set coordinates for next point
                LatitudeDegrees2List = datalist[i+1][4]
                LongitudeDegrees2List = datalist[i+1][5]

                #build shapely point - needed to measure distance
                latlonPoint = Point([LongitudeDegreesList,LatitudeDegreesList])

                #generate Shapely Points
                Point1 = Point(LongitudeDegreesList,LatitudeDegreesList)
                Point2 = Point(LongitudeDegrees2List,LatitudeDegrees2List)

                #clean timestamps
                timeHolder1 = (timestampList.split("T")[1]).replace("Z","")
                timeHolder2 = (timestampList2.split("T")[1]).replace("Z","")

                dateHolder = (timestampList.split("T")[0]).replace("T","")

                #Set timestamps - no need to worry about the dates, since all runs take place in the same day
                if len(datalist[i][1]) == 8:
                    timestep1 = datetime.strptime(timeHolder1,'%H:%M:%S')
                else:
                    timestep1 = datetime.strptime(timeHolder1,'%H:%M:%S.%f')

                if len(datalist[i+1][1]) == 8:
                    timestep2 = datetime.strptime(timeHolder2,'%H:%M:%S')

                else:
                    timestep2 = datetime.strptime(timeHolder2,'%H:%M:%S.%f')


                #fine time difference between the two steps
                timedif = timestep2-timestep1

                #using pyproj, calculate geodesic distance
                distance = geod.inv(Point1.x, Point1.y, Point2.x, Point2.y)

                #Calculate distance between points
                distancebtwPoints = round(float(distance[2]),2)

                #Calculate time between points
                timebtwnPoints = round(float(timedif.total_seconds()),2)

                if abs(timebtwnPoints) >=86000:
                    timebtwnPoints = round(float(timebtwnPoints+86400),2)

                timebtwnPoints_time = datetime.strptime(str(abs(timebtwnPoints)), "%S.%f")

                #calculate speed - meters per second
                speed = timebtwnPoints*distancebtwPoints

                #calculate cumulative distance - in meters
                distanceCounter = round((distanceCounter+distancebtwPoints),4)
                distanceCounterFeet = round(((distanceCounter+distancebtwPoints)*3.28084),4)
                distanceCounterMiles = round((distanceCounterFeet/5280),4)

                #calculate cumlative time- in seconds
                timeCounter = timeCounter + timedelta(seconds=(timebtwnPoints))
                timeCounterSecs = timeCounterSecs+timebtwnPoints

                #set time and distance flags - based on quarter miles
                if (round((distanceCounterMiles),2)%0.2500/0.25 == 0.0) & (distanceCounterMiles >= 0.25):
                    SplitFlagDist = round((distanceCounterMiles),2)
                    SplitFlagTime = datetime.time(timeCounter)
                    finalSplitFlagTime = str(datetime.time(timeCounter))
                else:
                    SplitFlagDist = 0
                    SplitFlagTime = 0
                    finalSplitFlagTime = '0'

                #set final variable
                finaldistancebtwPoints = round(distancebtwPoints,2)
                finalSpeed = round(speed,2)
                finaldistanceCounter = round(distanceCounter,2)
                finaldistanceCounterFeet = round(distanceCounterFeet,2)
                finaldistanceCounterMiles = round(distanceCounterMiles,2)
                finaltimeCounter = str(datetime.time(timeCounter))
                finalSplitFlagDist = round(SplitFlagDist,2)

                # Write to text file
                outputPointsTXT.write(str(RunID)+','+str(idvalList)+','+str(dateHolder)+','+str(AltitudeMetersList)+','+str(finaldistancebtwPoints)+','+str(finalSpeed)+','+str(finaldistanceCounter)+','+str(finaldistanceCounterFeet)+','+str(finaldistanceCounterMiles)+','+str(finaltimeCounter)+','+str(finalSplitFlagDist)+','+str(finalSplitFlagTime)+','+str(LatitudeDegreesList)+','+str(LongitudeDegreesList)+'\n')

    #increment RunID
    RunID = RunID + 1

    outpath = ""


    print ("    Extraction Complete")
    print()
print('Script Complete')
outputPointsTXT.close()
