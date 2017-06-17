#-------------------------------------------------------------------------------
# Name:        TCXtoShape.py
# Purpose:     Simple script to convert a TCX file into a line shapefile
#
#               User will need to set the input file, and output filename and
#               directory
#
# Author:      Benjamin Spaulding - @thebenspaulding
#
# Created:     August/08/2016
#
# Instructions: the user will need to set the input and output directories.  Input - Line 53, Output - Line 70  
#
#
# tcx parser based on https://github.com/jhofman/fitnesshacks
# Shapely and Fiona are also awesome -
#       http://toblerity.org/fiona/manual.html
#       http://toblerity.org/shapely/manual.html
#-------------------------------------------------------------------------------

import os, sys, re
from xml.etree.ElementTree import fromstring

import fiona
from fiona.crs import from_epsg
from shapely.geometry import mapping, Point, LineString
import pyproj
import datetime as dt
from datetime import timedelta,datetime


#--------------------------------------------------------------------------------------------------
#                 Set Parameters for Geographic Transformation
#--------------------------------------------------------------------------------------------------

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

#Set input data path
path = ''

listing = os.listdir(path)


for infile in listing:

    #build empty list
    datalist = []

    #Input file TCX file
    inputFile = infile
    outputShapefileName = shapeName = (infile.split("."))[0]

    print("Building "+outputShapefileName + " Shapefile")

    #output folder location
    outpath =  ''

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

    #output shapefile
    outShape = 'rBr_'+outputShapefileName+'_shape.shp'

    print("    Final Shapefile: "+ outShape)

    #output crs
    crs = fiona.crs.from_epsg(4326)

    #output shapefile schema

    schema = {
        'geometry': 'LineString',
        'properties': {'id': 'int','distMeters':'float','MpS':'float','TtlMtrs':'float','TtlFt':'float','TtlMile':'float','TtlTime':'str:50','FlagDist':'float','FlagTime':'str:50',},
    }

    print ("    Start TCX Extraction")
    print( "    Full Path: "+ outpath+outShape)

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

    #--------------------------------------------------------------------------------------------------
    #set counters as global variables
    distanceCounter = 0.0
    timeCounter = datetime.strptime(str("0.0"), "%S.%f")
    timeCounterSecs = 0
    #--------------------------------------------------------------------------------------------------

    #using Fiona, create a new shapefile and then populate it with data from the tcx file
    with fiona.open(outpath+outShape, 'w', driver='ESRI Shapefile',crs = crs, schema = schema) as c:
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

                #build shapely point
                latlonPoint = Point([LongitudeDegreesList,LatitudeDegreesList])

                #generate Shapely Points
                Point1 = Point(LongitudeDegreesList,LatitudeDegreesList)
                Point2 = Point(LongitudeDegrees2List,LatitudeDegrees2List)

                timeHolder1 = (timestampList.split("T")[1]).replace("Z","")
                timeHolder2 = (timestampList2.split("T")[1]).replace("Z","")


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



                #build linestring
                linestring = LineString([Point1,Point2])

                #set final variable
                finaldistancebtwPoints = round(distancebtwPoints,2)
                finalSpeed = round(speed,2)
                finaldistanceCounter = round(distanceCounter,2)
                finaldistanceCounterFeet = round(distanceCounterFeet,2)
                finaldistanceCounterMiles = round(distanceCounterMiles,2)
                finaltimeCounter = str(datetime.time(timeCounter))
                finalSplitFlagDist = round(SplitFlagDist,2)

                # Write a new Shapefile
                c.write({
                        'geometry': mapping(linestring),
                        'properties': {'id': idvalList,'distMeters':finaldistancebtwPoints,'MpS':finalSpeed,'TtlMtrs':finaldistanceCounter,'TtlFt':finaldistanceCounterFeet,'TtlMile':finaldistanceCounterMiles,'TtlTime':finaltimeCounter, 'FlagDist':finalSplitFlagDist,'FlagTime':finalSplitFlagTime, },
                        })




    outpath = ""
    outShape = ""
    c.close()
    print ("    Extraction Complete")
    print()
print('Script Complete')
