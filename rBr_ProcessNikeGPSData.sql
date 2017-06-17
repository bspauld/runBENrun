/*
	Script:  rBr_ProcessNikeGPSData.sql

	Purpose: Series of sql scripts to load and process data outputed from TCXtoText.py

	Instructions: Set input text file to load into points table (line 54) and then run the script

	Code built using PostgreSQL and PostGIS

	Script Steps
	1. Build and load rbr_AllRuns_2016_Points table
	2. Add Geometry column in rbr_AllRuns_2016_Points Table and update fields
	3. Create a table to correct the date value
	4. In rbr_allruns_2016_points table add a mile indicator and populate it
	5. Build and Populate RunID Table
	6. Clean out bad MpS values - algorightm to smooth values - Not started yet, just a place holder
	7. Build and Populate mile split table
	8. Update RunID Table - Add information about the fastest mile, including which mile was the fastest
	9. Update runtype column in runID table 


	Author - Benjamin Spaulding @thebenspaulding

	Created - October 2016

*/


/* ******************************************************************************************************** 

			Build and Populate Master Point Table

 ******************************************************************************************************** */

--CREATE table
create table public.rbr_AllRuns_2016_Points(
	RunID INT,
	idvalList INT,
	DateVal Varchar(50), 
	AltitudeMeters Decimal(18,2),
	finaldistancebtwPoints Decimal(18,2),
	finalSpeed Decimal(18,2),
	finaldistanceCounter Decimal(18,4),
	finaldistanceCounterFeet Decimal(18,4),
	finaldistanceCounterMiles Decimal(18,4),
	finaltimeCounter varchar(50),
	finalSplitFlagDist Decimal(18,2),
	finalSplitFlagTime varchar(50),
	Lat Decimal(18,6),
	Lon Decimal(18,6));

--insert data from text file
Copy public.rbr_AllRuns_2016_Points
from 'rBr_Points2016.txt' DELIMITER ',' CSV Header;

/* ******************************************************************************************************** 

			Add Geometry column in Point Table and update fields

 ******************************************************************************************************** */

--Add Geometry Column
SELECT AddGeometryColumn ('public','rbr_allruns_2016_points','geom',4326,'POINT',2);

--Update geometry column from lat and lon fields
Update public.rbr_allruns_2016_points set geom = ST_SetSRID(ST_MakePoint(Lon, Lat),4326);

--create spatial index
CREATE INDEX idx_gpspoints_geom ON public.rbr_allruns_2016_points USING GIST(geom);

/* ******************************************************************************************************** 

			Create a table to correct the date value

 ******************************************************************************************************** */

--update dateval - some runs get multiple dates because something is weird with the time. create a table with distinct minimum dates for each runID
drop table public.mindateValbyRunId;
create table public.mindateValbyRunId (runid int, dateval varchar(50));
insert into public.mindateValbyRunId
select runID, min(dateval) from public.rbr_allruns_2016_points  
group by runid
order by runID; 

update public.rbr_allruns_2016_points a
set dateval = p.dateval
from public.mindateValbyRunId p 
where a.runid = p.runid;

/* ******************************************************************************************************** 

	In rbr_allruns_2016_points table add a mile indicator and populate it

 ******************************************************************************************************** */

--add mile indicator - round the finaldistancecountermiles field - will need to add one to each mile
alter table public.rbr_allruns_2016_points
add column mileMarker INT;
update public.rbr_allruns_2016_points
set mileMarker = round(finaldistanceCounterMiles, 0)+1;

/* ******************************************************************************************************** 

			Build line segements between points for a given runid

 ******************************************************************************************************** */

--Add Line Geometry Column
SELECT AddGeometryColumn ('public','rbr_allruns_2016_points','linegeom',4326,'LINESTRING',2);

drop table public.rbr_allruns_2016_linesegTEMP;
create table public.rbr_allruns_2016_linesegTEMP(
	runid int,
	idvalList int, 
	from_lat Decimal(18,6), 
	from_lon Decimal(18,6), 
	to_idvalList int, 
	to_lat Decimal(18,6), 
	to_lon Decimal(18,6) );

SELECT AddGeometryColumn ('public','rbr_allruns_2016_linesegtemp','linegeom',4326,'LINESTRING',2);

insert into public.rbr_allruns_2016_linesegTEMP
select 	f.runid,
	f.idvalList, 
	f.lat as from_lat, 
	f.lon as from_lon,
	t.idvalList as to_idvalList,
	t.lat as to_lat,
	t.lon as to_lon,
	ST_SetSRID(ST_MakeLine(ST_MakePoint(f.lon,f.lat),ST_MakePoint(t.lon,t.lat)),4326) as linegeom
from public.rbr_allruns_2016_points f join public.rbr_allruns_2016_points t on f.runid = t.runid 
where f.idvalList = t.idvalList -1
order by f.idvallist, t.idvalList;

--add the line geometry to the points table
update public.rbr_AllRuns_2016_Points 
set public.rbr_AllRuns_2016_Points.linegeom = lt.linegeom
from public.rbr_allruns_2016_linesegTEMP lt 
where public.rbr_AllRuns_2016_Points.runid = lt.runid and public.rbr_AllRuns_2016_Points.idvalList = lt.idvalList;

--Get samples
select * from public.rbr_allruns_2016_points where runid = 3;
select distinct(runID) as distinct_runID from public.rbr_allruns_2016_points;
select runid, (dateval) as distinct_dateval, count(*) as TotalRecords from public.rbr_allruns_2016_points group by dateval,runid order by dateval; 


/* ******************************************************************************************************** 

			Build and Populate RunID Table

 ******************************************************************************************************** */

--drop old table
drop table public.rbr_AllRuns_2016_ID;

--CREATE table
create table public.rbr_AllRuns_2016_ID(
	RunID INT,
	DateVal Varchar(50), 
	RunType Varchar(50),
	RunDist Varchar(50),
	RunTime Varchar(50),
	AvgPacePerMile varchar(50),
	FastestMile varchar(50),
	FastestMileMarker int,
	NetElevation varchar(50));

insert into public.rbr_AllRuns_2016_ID
select distinct runid, 
	dateval, 
	'' as RunType,
	max(finaldistancecountermiles) as RunDist, 
	max(finaltimecounter) as RunTime,
	cast(max(finaltimecounter) as time)/max(finaldistancecountermiles)  as AvgPacePerMile,
	'' as FastestMile,
	0 as FastestMileMarker,
	sum(AltitudeMeters) as NetElevation --need to work out algorighm to find net elevation gain/drop
from public.rbr_allruns_2016_points
group by runid,dateval;

select count(distinct runid) from public.rbr_AllRuns_2016_ID;
select count(*) as RowCount from public.rbr_AllRuns_2016_ID;


/* ******************************************************************************************************** 

			Clean out bad MpS values - algorightm to smooth values

 ******************************************************************************************************** */

--To Do


/* ******************************************************************************************************** 

			Build and Populate mile split Table

 ******************************************************************************************************** */

--CREATE temp table for mile splits
create table public.rbr_AllRuns_2016_MileSplitsPrep(
	RunID INT,
	DateVal Varchar(50), 
	MileSplits Varchar(50),
	MileDistVal int
	);
--insert values into temp mile splits table 
insert into public.rbr_AllRuns_2016_MileSplitsPrep
select runid,dateval, min(finalsplitflagtime)as MileSplits,finalsplitflagdist as MileDistVal
from public.rbr_allruns_2016_points
where finalsplitflagdist/1 in (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26)
group by runid,dateval,finalsplitflagdist;

--CREATE table to store mile splits
create table public.rbr_AllRuns_2016_MileSplits(
	RunID INT,
	DateVal Varchar(50), 
	MileDistVal int,
	MileSplit Varchar(50)
	
	);

insert into public.rbr_AllRuns_2016_MileSplits
select 
	u.from_runID as runID,
	u.dateval as dateval,
	u.from_mile as MileDistVal,
	case when cast(u.milesplit_timedif as time) = '00:00:00' then cast(u.to_milesplits as time)
		else cast(u.MileSplit_TimeDif as time)
		end as milesplit
		
 from
(
	select 	o.runid as from_runID, 
		t.runid as to_runIF,
		o.dateval as dateval,
		o.milesplits as from_milesplits,
		t.milesplits as to_milesplits,
		cast(o.milesplits as time)-cast(t.milesplits as time) as MileSplit_TimeDif,
		o.miledistval as From_mile,
		t.miledistval as To_mile
	from public.rbr_AllRuns_2016_MileSplitsPrep o join public.rbr_AllRuns_2016_MileSplitsPrep t
	on o.runid = t.runid 
	where  	
		(cast(o.milesplits as time)-cast(t.milesplits as time)) >= '00:00:00' 
		and o.miledistval - t.miledistval = 1 
		or (o.miledistval = 1 and t.miledistval = 1 and (cast(o.milesplits as time)-cast(t.milesplits as time)) = '00:00:00' )
	group by o.runid, t.runid,o.dateval,o.milesplits,t.milesplits,o.miledistval,t.miledistval
	order by o.runid, o.dateval, o.miledistval, t.miledistval
) u;


--get sample resutls
select * from public.rbr_AllRuns_2016_MileSplits
order by cast(MileSplit as time) desc
limit 25;


/*  ******************************************************************************************************** 

	update RunID Table

	Add information about the fastest mile, including which mile was the fastest

 ********************************************************************************************************  */

create table public.temprunidminmiles (RunID INT,MileSplit Varchar(50),MileDistVal int);

--create temp table with the runid, mile splits, and the mile it was
insert into public.temprunidminmiles 
select runid, min(milesplit) as milesplit, MileDistVal
from public.rbr_AllRuns_2016_MileSplits
group by runid,MileDistVal;

--update rbr_AllRuns_2016_ID. set all fastestmile to null - clean up any old stuff
update public.rbr_AllRuns_2016_ID
set fastestmile =  null;

--using temp table, update rbr_AllRuns_2016_ID with the fastest mile speed value
update public.rbr_AllRuns_2016_ID 
set fastestmile =  s.milesplit
from public.temprunidminmiles s 
where public.rbr_AllRuns_2016_ID.runid =  s.runid;

--using temp table, update rbr_AllRuns_2016_ID with the fastest mile mile value
update public.rbr_AllRuns_2016_ID 
set FastestMileMarker =  s.MileDistVal
from public.temprunidminmiles s 
where public.rbr_AllRuns_2016_ID.runid =  s.runid;


/* ******************************************************************************************************** 

	Update runtype column in runID table 

 ******************************************************************************************************** */

--build a case statement where the run distance and average time are compared and then scored. store results
--in temp table to eventually join to rbr_AllRuns_2016_ID table

drop table public.runtypetemp;
create table public.runtypetemp (runid int,  runtype varchar(50));
insert into public.runtypetemp
select 
	runid, 
	case 
		when cast(rundist as decimal(16,4)) <3.00 then 'Intervals'
		when round(cast(rundist as decimal(16,4)),0) = 3 
			and cast(avgpacepermile as time) <= '00:06:30' then 'Awesome'
		when round(cast(rundist as decimal(16,4)),0) = 3 
			and cast(avgpacepermile as time) between '00:06:30' and '00:06:45' then 'Great'
		when round(cast(rundist as decimal(16,4)),0) = 3 
			and cast(avgpacepermile as time) between '00:06:45' and '00:07:15' then 'OK'
		when round(cast(rundist as decimal(16,4)),0) = 3 
			and cast(avgpacepermile as time) > '00:07:15' then 'Ehh'
		
		when round(cast(rundist as decimal(16,4)),0) between 4 and 5 
			and cast(avgpacepermile as time) <= '00:06:30' then 'Awesome'
		when round(cast(rundist as decimal(16,4)),0) between 4 and 5
			and cast(avgpacepermile as time) between '00:06:30' and '00:06:45' then 'Great'
		when round(cast(rundist as decimal(16,4)),0) between 4 and 5 
			and cast(avgpacepermile as time) between '00:06:45' and '00:07:30' then 'OK'
		when round(cast(rundist as decimal(16,4)),0) between 4 and 5
			and cast(avgpacepermile as time) > '00:07:30' then 'Ehh'

		when round(cast(rundist as decimal(16,4)),0) between 6 and 13 
			and cast(avgpacepermile as time) <= '00:06:45' then 'Awesome'
		when round(cast(rundist as decimal(16,4)),0) between 6 and 13 
			and cast(avgpacepermile as time) between '00:06:45' and '00:07:00' then 'Great'
		when round(cast(rundist as decimal(16,4)),0) between 6 and 13 
			and cast(avgpacepermile as time) between '00:07:00' and '00:07:45' then 'OK'
		when round(cast(rundist as decimal(16,4)),0) between 6 and 13
			and cast(avgpacepermile as time) > '00:07:45' then 'Ehh'

		when round(cast(rundist as decimal(16,4)),0) between 13 and 16 
			and cast(avgpacepermile as time) <= '00:06:45' then 'Awesome'
		when round(cast(rundist as decimal(16,4)),0) between 13 and 16
			and cast(avgpacepermile as time) between '00:06:45' and '00:07:15' then 'Great'
		when round(cast(rundist as decimal(16,4)),0) between 13 and 16
			and cast(avgpacepermile as time) between '00:07:15' and '00:07:45' then 'OK'
		when round(cast(rundist as decimal(16,4)),0) between 13 and 16
			and cast(avgpacepermile as time) > '00:07:45' then 'Ehh'

		when round(cast(rundist as decimal(16,4)),0) > 16 
			and cast(avgpacepermile as time) <= '00:07:00' then 'Awesome'
		when round(cast(rundist as decimal(16,4)),0) > 16
			and cast(avgpacepermile as time) between '00:07:00' and '00:07:30' then 'Great'
		when round(cast(rundist as decimal(16,4)),0) > 16
			and cast(avgpacepermile as time) between '00:07:30' and '00:08:00' then 'OK'
		when round(cast(rundist as decimal(16,4)),0) > 16
			and cast(avgpacepermile as time) > '00:08:00' then 'Ehh'

	else 'TBA'

	end as runtype	
from public.rbr_AllRuns_2016_ID;

--Update rbr_AllRuns_2016_ID with runtypes
update public.rbr_AllRuns_2016_ID
set runtype = t.runtype
from public.runtypetemp t 
where public.rbr_AllRuns_2016_ID.runid = t.runid;


