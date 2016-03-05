#-------------------------------------------------------------------------------
# Name:         ImportGPXfiles.py
# Purpose:      Import gpx files from csv into Postgres database
#
# Author:       Ben Spaulding
#
# Created:      Feb, 15, 2016
# Copyright:
# Licence:
#-------------------------------------------------------------------------------

import os, sys, psycopg2

path="INPUT Directory"

inputTable = 'public.gps_points'

try:
    conn = psycopg2.connect("dbname='DBNAME' user='postgres' host='localhost' port='PortNumber' password='PASSWORD'")
    print ("CONNECTION SUCCESSFUL")
except:
    print ("I am unable to connect to the database")


cur = conn.cursor()

listing = os.listdir(path)


for infile in listing:
    inputFilename = infile
    print('Processing File: ',inputFilename )

    DateVal = inputFilename[0:10]
    formattedDateVal = DateVal.replace('_',':')
    #print(formattedDateVal)
    filePath =path+DateVal+'_Extract.txt'

    cur.execute("""Copy public.gps_points from %s DELIMITER ',' CSV Header""",[filePath])

    conn.commit()
    print(inputFilename, " Loaded into database")

cur.close()

print ('Script Compelte')





