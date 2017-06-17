#-------------------------------------------------------------------------------
# Name:         UpdateGPXData.py
# Purpose:      For each formatted GPX file, calculate several additional stats
#               including distance (miles,feet,meters), and speed (by miles,feet,meters)
#
# Author:       Ben Spaulding @thebenspaulding
#
# Created:      Feb, 28, 2016
# Copyright:
# Licence:
#-------------------------------------------------------------------------------

import os, sys

import fiona
from fiona.crs import from_epsg
from shapely.geometry import mapping, Point, Polygon, LineString
import pyproj
import datetime as dt
from datetime import timedelta,datetime

print('Start Script')
print('------------------------------------------------------')
print('')

 #--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 #                 Set Global Variables
 #--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


runID = 0

#path to data
path = 'input path'
outpath =  'output folder path'

#write the sumary results of each run to a summary file for later analysis
summaryfile = open(outpath+'rBr_summaryfile.txt', 'a' )
summaryfile.write('RunID,DateVal,FinalTime,DistMiles,AvgPace,RunType\n')

listing = os.listdir(path)

for inputFilename in listing:
    datalist = []
    #input path
    inpath = path

    #input run file
    inputFile = inputFilename.split(".")
    infile =  str(str(inputFile[0]))


    print('---------- Run Stats ----------')
    print('Processing: ',infile )

    #output shapefile
    outShape = 'rBr_'+infile+'_shape.shp'

    #output crs
    crs = fiona.crs.from_epsg(4326)

    #output shapefile
    schema = {
        'geometry': 'LineString',
        'properties': {'id': 'int','distMeters':'float','MpS':'float','TtlMtrs':'float','TtlFt':'float','TtlMile':'float','TtlTime':'str:50','FlagDist':'float','FlagTime':'str:50',},
    }

    finalfile = open(outpath+'rBr_'+infile+'_tbl.txt', 'w' )

    #--------------------------------------------------------------------------------------------------
    #                 Set Parameters for Geographic Transformation
    #--------------------------------------------------------------------------------------------------

    geod = pyproj.Geod(ellps='WGS84')

    #--------------------------------------------------------------------------------------------------

    #Convert text file into list- only every other record
    with open(inpath+infile+'.txt', 'r') as f:
        count = 0
        for x in f:
            count+=1
            if count %2 ==0:
                inner_list = [(elt.strip()) for elt in x.split(',')]
                if inner_list[0] != 'ID':
                    datalist.append([(elt.strip()) for elt in x.split(',')])
    #--------------------------------------------------------------------------------------------------

    #write file header
    finalfile.write('ID,distMeters,MpS,TotalDistMeters,TotalDistFeet,TotalDistMiles,TotalTime,SplitFlagDist,SplitFlagTime\n')

    #--------------------------------------------------------------------------------------------------
    #set counters as global variables
    distanceCounter = 0.0
    timeCounter = datetime.strptime(str("0.0"), "%S.%f")
    timeCounterSecs = 0
    #--------------------------------------------------------------------------------------------------

    #Start Data Conversion

    with fiona.open(outpath+outShape, 'w', driver='ESRI Shapefile',crs = crs, schema = schema) as c:
        #perform caclulations
        for i in range(len(datalist)):
            if i < (len(datalist))-1:
                #Set ID value
                dateVal = datalist[i][4]
                IDval = datalist[i][0]

                #Set origin Lon/Lat pair
                LatVal = round(float(datalist[i][1]),6)
                LonVal = round(float(datalist[i][2]),6)

                #Set destination Lon/Lat pair - the next point
                LatVal2 = round(float(datalist[i+1][1]),6)
                LonVal2 = round(float(datalist[i+1][2]),6)

                #Set timestamps - no need to worry about the dates, since all runs take place in the same day
                if len(datalist[i][5]) == 8:
                    timestep1 = datetime.strptime(datalist[i][5],'%H:%M:%S')
                else:
                    timestep1 = datetime.strptime(datalist[i][5],'%H:%M:%S.%f')

                if len(datalist[i+1][5]) == 8:
                    timestep2 = datetime.strptime(datalist[i+1][5],'%H:%M:%S')

                else:
                    timestep2 = datetime.strptime(datalist[i+1][5],'%H:%M:%S.%f')

                #fine time difference between the two steps
                timedif = timestep2-timestep1

                #generate Shapely Points
                Point1 = Point(LonVal,LatVal)
                Point2 = Point(LonVal2,LatVal2)

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

                #write final string to file
                finalfile.write(str(IDval)+','+
                        str("{0:.6f}".format(LonVal))+','+
                        str("{0:.6f}".format(LatVal))+','+
                        str("{0:.2f}".format(distancebtwPoints))+','+
                        str("{0:.2f}".format(speed))+','+
                        str("{0:.4f}".format(distanceCounter))+','+
                        str("{0:.4f}".format(distanceCounterFeet))+','+
                        str("{0:.4f}".format(distanceCounterMiles))+','+
                        str(datetime.time(timeCounter))+','+
                        str(SplitFlagDist)+','+
                        str(SplitFlagTime)+'\n')

                #set final variable
                finaldistancebtwPoints = round(distancebtwPoints,2)
                finalSpeed = round(speed,2)
                finaldistanceCounter = round(distanceCounter,2)
                finaldistanceCounterFeet = round(distanceCounterFeet,2)
                finaldistanceCounterMiles = round(distanceCounterMiles,2)
                finaltimeCounter = str(datetime.time(timeCounter))
                finalSplitFlagDist = round(SplitFlagDist,2)

                #build linestring
                linestring = LineString([Point1,Point2])

                # Write a new Shapefile
                c.write({
                        'geometry': mapping(linestring),
                        'properties': {'id': IDval,'distMeters':finaldistancebtwPoints,'MpS':finalSpeed,'TtlMtrs':finaldistanceCounter,'TtlFt':finaldistanceCounterFeet,'TtlMile':finaldistanceCounterMiles,'TtlTime':finaltimeCounter, 'FlagDist':finalSplitFlagDist,'FlagTime':finalSplitFlagTime, },
                        })
    runID+=1
    c.close()
    finalfile.close()



    finalAvgPace = timedelta(seconds=int(abs((timeCounterSecs)/finaldistanceCounterMiles)))


    #set Timedeltas for static times for comparisons
    s1 = timedelta(seconds=int(360))
    s2 = timedelta(seconds=int(375))
    s3 = timedelta(seconds=int(390))
    s4 = timedelta(seconds=int(405))
    s5 = timedelta(seconds=int(420))
    s6 = timedelta(seconds=int(435))
    s7 = timedelta(seconds=int(450))
    s8 = timedelta(seconds=int(465))

    if round(finaldistanceCounterMiles,0) < 3:
        runType = 'Too Short to Count'
    elif round(finaldistanceCounterMiles,0) == 3:
        if finalAvgPace <= s1:
            runType = 'Awesome'
        elif finalAvgPace >= s1 and finalAvgPace <= s3:
            runType = 'Great'
        elif finalAvgPace >= s3 and finalAvgPace <= s5:
            runType = 'OK'
        elif finalAvgPace >= s5:
            runType = 'Ehh'
        else:
            runType = 'Unknown'
    elif round(finaldistanceCounterMiles,0) >= 4 and round(finaldistanceCounterMiles,0) < 6:
        if finalAvgPace <= s3:
            runType = 'Awesome'
        elif finalAvgPace >= s3 and finalAvgPace <=s4:
            runType = 'Great'
        elif finalAvgPace >= s4 and finalAvgPace <= s6:
            runType = 'OK'
        elif finalAvgPace >= s6:
            runType = 'Ehh'
        else:
            runType = 'Unknown'
    elif round(finaldistanceCounterMiles,0) >= 6 and round(finaldistanceCounterMiles,0) <8:
        if finalAvgPace <= s4:
            runType = 'Awesome'
        elif finalAvgPace >= s4 and finalAvgPace <= s6:
            runType = 'Great'
        elif finalAvgPace >= s6 and finalAvgPace <= s7:
            runType = 'OK'
        elif finalAvgPace >= s7:
            runType = 'Ehh'
        else:
            runType = 'Unknown'
    elif round(finaldistanceCounterMiles,0) >= 8 and round(finaldistanceCounterMiles,0) <10:
        if finalAvgPace <= s5:
            runType = 'Awesome'
        elif finalAvgPace >=s5 and finalAvgPace <= s7:
            runType = 'Great'
        elif finalAvgPace >= s7 and finalAvgPace <= s8:
            runType = 'OK'
        elif finalAvgPace >= s8:
            runType = 'Ehh'
        else:
            runType = 'Unknown'
    elif round(finaldistanceCounterMiles,0) >= 10:
        if finalAvgPace <= s6:
            runType = 'Awesome'
        elif finalAvgPace >= s6 and finalAvgPace <= s7:
            runType = 'Great'
        elif finalAvgPace >= s7 and finalAvgPace <= s8:
            runType = 'OK'
        elif finalAvgPace >= s8:
            runType = 'Ehh'
        else:
            runType = 'Unknown'
    else:
        runType = 'FINAL ELSE'


    summaryfile.write(str(runID)+','+str(dateVal)+','+str(finaltimeCounter)+','+str(finaldistanceCounterMiles)+','+str(finalAvgPace)+','+str(runType)+'\n')


    print('')
    print('RunID:',str(runID))
    print('Date:',dateVal)
    print('Total Time:',finaltimeCounter)
    print('Total Miles:',finaldistanceCounterMiles)
    print('Average Pace:',finalAvgPace)
    print('Run Type:',runType)
    print('')
    print('----------------------------------')
    print('')

print('All Runs Processed')
summaryfile.close()
