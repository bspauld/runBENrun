
/*
	Script:  rBr_AnalyzeNikeGPSData.sql

	Purpose: Series of sql scripts to analyze tables and data created from rBr_ProcessNikeGPSData.sql 

	Instructions: run script

	Code built using PostgreSQL and PostGIS
	
	Author - Benjamin Spaulding @gisdoctor

	Created - October 2016

*/


/* ******************************************************************************************************** 

			Find top 10 miles

 ******************************************************************************************************** */

create table public.fastestmiles (runid int,dateval varchar(50), fastestmilemarker int, fastestmile varchar(50));
SELECT AddGeometryColumn ('public','fastestmiles','linegeom',4326,'LINESTRING',2);

insert into public.fastestmiles
select i.runid,i.dateval, i.fastestmilemarker, i.fastestmile, p.linegeom
from public.rbr_allruns_2016_points p  inner join public.rbr_AllRuns_2016_ID  i on p.runid = i.runid and p.milemarker = i.fastestmilemarker
where p.runid in (select runid from public.rbr_AllRuns_2016_ID where runtype != 'Intervals'
	order by fastestmile asc
	limit 10) and linegeom is not null 
order by p.runid;

select distinct f.runid, a.* from public.fastestmiles f inner join public.rbr_AllRuns_2016_ID a on f.runid = a.runid
limit 10;

/* ******************************************************************************************************** 

			Find slowest 10 miles

 ******************************************************************************************************** */

create table public.slowesttmiles (runid int,dateval varchar(50), fastestmilemarker int, fastestmile varchar(50));
SELECT AddGeometryColumn ('public','slowesttmiles','linegeom',4326,'LINESTRING',2);

insert into public.slowesttmiles
select i.runid,i.dateval, i.fastestmilemarker, i.fastestmile, p.linegeom
from public.rbr_allruns_2016_points p  inner join public.rbr_AllRuns_2016_ID  i on p.runid = i.runid and p.milemarker = i.fastestmilemarker
where p.runid in (select runid from public.rbr_AllRuns_2016_ID where runtype != 'Intervals'
	order by fastestmile desc
	limit 10) and linegeom is not null 
order by p.runid;

select distinct runid from public.slowesttmiles
limit 10;

/* ******************************************************************************************************** 

			General analysis

 ******************************************************************************************************** */


--breakdown of run type
select runtype, count(*) as TotalRuns from public.rbr_AllRuns_2016_ID
group by runtype
order by count(*) desc


--get count of all points
select count(*) as TotalGPSPoints from public.rbr_AllRuns_2016_Points

--get count of distinct runs
select count(distinct runid) from public.rbr_AllRuns_2016_Points

--get total time spent running
select sum(cast(milesplit as time)) from public.rbr_AllRuns_2016_MileSplits

--get total miles
select sum(cast(rundist as decimal(16,4))) as TotalMiles from public.rbr_AllRuns_2016_ID


/* ******************************************************************************************************** 

			runtype analysis

 ******************************************************************************************************** */

--get breakdown of run types

select 	
	 runtype,
	 avg(cast(avgpacepermile as time)) as AvgPace,
	 sum(cast(rundist as decimal(16,6))) as RunDist, 
	 date_part('month',(cast(dateval as date))) as MonthVal, 
	 to_char(cast(dateval as date), 'MONTH') as MonthTEXT, 
	 date_part('year',(cast(dateval as date))) as YearVal
from public.rbr_AllRuns_2016_ID 
group by date_part('year',(cast(dateval as date))),
	 to_char(cast(dateval as date), 'MONTH'),
	 date_part('month',(cast(dateval as date))),
	 runtype
order by 
	 date_part('year',(cast(dateval as date))),
	 date_part('month',(cast(dateval as date))),
	 runtype;

/* ************************************************************************************************************************************* 

	Find breakdown of run types

	Great
	OK
	Ehh
	Awesome
	Interval

 ************************************************************************************************************************************* */

--Great
select  
	date_part('month',(cast(dateval as date))) as MonthVal, 
	to_char(cast(dateval as date), 'MONTH') as MonthTEXT, 
	date_part('year',(cast(dateval as date))) as YearVal,
	count(*) as TotalRuns, 
	avg(cast(rundist as decimal(16,2))) as AvgDist,
	avg(cast(avgpacepermile as time)) as AvgPace
from public.rbr_AllRuns_2016_ID 
where runtype = 'Great'
group by runtype,date_part('month',(cast(dateval as date))),to_char(cast(dateval as date), 'MONTH'),date_part('year',(cast(dateval as date)))
order by date_part('month',(cast(dateval as date)))

--OK
select  
	date_part('month',(cast(dateval as date))) as MonthVal, 
	to_char(cast(dateval as date), 'MONTH') as MonthTEXT, 
	date_part('year',(cast(dateval as date))) as YearVal,
	count(*) as TotalRuns, 
	avg(cast(rundist as decimal(16,2))) as AvgDist,
	avg(cast(avgpacepermile as time)) as AvgPace
from public.rbr_AllRuns_2016_ID 
where runtype = 'OK'
group by runtype,date_part('month',(cast(dateval as date))),to_char(cast(dateval as date), 'MONTH'),date_part('year',(cast(dateval as date)))
order by date_part('month',(cast(dateval as date)))

--Ehh
select  
	date_part('month',(cast(dateval as date))) as MonthVal, 
	to_char(cast(dateval as date), 'MONTH') as MonthTEXT, 
	date_part('year',(cast(dateval as date))) as YearVal,
	count(*) as TotalRuns, 
	avg(cast(rundist as decimal(16,2))) as AvgDist,
	avg(cast(avgpacepermile as time)) as AvgPace
from public.rbr_AllRuns_2016_ID 
where runtype = 'Ehh'
group by runtype,date_part('month',(cast(dateval as date))),to_char(cast(dateval as date), 'MONTH'),date_part('year',(cast(dateval as date)))
order by date_part('month',(cast(dateval as date)))

--Awesome
select  
	date_part('month',(cast(dateval as date))) as MonthVal, 
	to_char(cast(dateval as date), 'MONTH') as MonthTEXT, 
	date_part('year',(cast(dateval as date))) as YearVal,
	count(*) as TotalRuns, 
	avg(cast(rundist as decimal(16,2))) as AvgDist,
	avg(cast(avgpacepermile as time)) as AvgPace
from public.rbr_AllRuns_2016_ID 
where runtype = 'Awesome'
group by runtype,date_part('month',(cast(dateval as date))),to_char(cast(dateval as date), 'MONTH'),date_part('year',(cast(dateval as date)))
order by date_part('month',(cast(dateval as date)))

--Interval
select  
	date_part('month',(cast(dateval as date))) as MonthVal, 
	to_char(cast(dateval as date), 'MONTH') as MonthTEXT, 
	date_part('year',(cast(dateval as date))) as YearVal,
	count(*) as TotalRuns, 
	avg(cast(rundist as decimal(16,2))) as AvgDist,
	avg(cast(avgpacepermile as time)) as AvgPace
from public.rbr_AllRuns_2016_ID 
where runtype = 'Intervals'
group by runtype,date_part('month',(cast(dateval as date))),to_char(cast(dateval as date), 'MONTH'),date_part('year',(cast(dateval as date)))
order by date_part('month',(cast(dateval as date)))

/* ************************************************************************************************************************************* 

	Analysis of Fastest Miles

************************************************************************************************************************************ */

--Fastest Mile
select fastestmilemarker, count(*) as TotalRecords, AVG(cast(fastestmile as time))
from public.rbr_AllRuns_2016_ID 
where fastestmilemarker <>0
group by fastestmilemarker
order by fastestmilemarker;


--fastest mile by month
select 
	min(cast(fastestmile as time)), 
	to_char(cast(dateval as date), 'MONTH') as MonthTEXT, 
	date_part('month',(cast(dateval as date))) as MonthVal 
from public.rbr_AllRuns_2016_ID 
where cast(fastestmile as time) <> '00:00:00'
group by to_char(cast(dateval as date), 'MONTH'), date_part('month',(cast(dateval as date)))
order by date_part('month',(cast(dateval as date)))


--fastest mile by month and week
select 
	min(cast(fastestmile as time)), 
	extract('week' from (cast(dateval as date))) as weekVal,
	to_char(cast(dateval as date), 'MONTH') as MonthTEXT, 
	date_part('month',(cast(dateval as date))) as MonthVal 
from public.rbr_AllRuns_2016_ID 
where cast(fastestmile as time) <> '00:00:00'
group by to_char(cast(dateval as date), 'MONTH'), date_part('month',(cast(dateval as date))),extract('week' from (cast(dateval as date))) 
order by date_part('month',(cast(dateval as date))),extract('week' from (cast(dateval as date))); 


--average mile speed and total miles by WEEK
select 	avg(cast(avgpacepermile as time)) as AvgPace,
	sum(cast(rundist as decimal(16,6))) as RunDist, 
	date_part('month',(cast(dateval as date))) as MonthVal, 
	extract('week' from (cast(dateval as date))) as weekVal,
	date_part('year',(cast(dateval as date))) as YearVal
from public.rbr_AllRuns_2016_ID 
group by extract('week' from (cast(dateval as date))),date_part('month',(cast(dateval as date))) , date_part('year',(cast(dateval as date)))
order by date_part('year',(cast(dateval as date))),extract('week' from (cast(dateval as date))), date_part('month',(cast(dateval as date)));


--average mile speed and total miles by MONTH
select 	avg(cast(avgpacepermile as time)) as AvgPace,
	sum(cast(rundist as decimal(16,6))) as RunDist, 
	date_part('month',(cast(dateval as date))) as MonthVal, 
	to_char(cast(dateval as date), 'MONTH') as MonthTEXT, 
	date_part('year',(cast(dateval as date))) as YearVal
from public.rbr_AllRuns_2016_ID 
group by date_part('year',(cast(dateval as date))),to_char(cast(dateval as date), 'MONTH'),date_part('month',(cast(dateval as date)))
order by date_part('year',(cast(dateval as date))),date_part('month',(cast(dateval as date)));



/* ************************************************************************************************************************************* 

	Analysis of Distance

************************************************************************************************************************************ */



--Shortest Run by month
select  min(cast(rundist as decimal(16,6))) as minDist,
	to_char(cast(dateval as date), 'MONTH') as MonthTEXT, 
	date_part('month',(cast(dateval as date))) as MonthVal
from public.rbr_AllRuns_2016_ID 
group by to_char(cast(dateval as date), 'MONTH'), date_part('month',(cast(dateval as date)))
order by date_part('month',(cast(dateval as date)))

--Longest Run by Month 
select  max(cast(rundist as decimal(16,6))) as minDist,
	to_char(cast(dateval as date), 'MONTH') as MonthTEXT, 
	date_part('month',(cast(dateval as date))) as MonthVal
from public.rbr_AllRuns_2016_ID 
group by to_char(cast(dateval as date), 'MONTH'), date_part('month',(cast(dateval as date)))
order by date_part('month',(cast(dateval as date)))


--Average Dist by Month	 
select  avg(cast(rundist as decimal(16,2))) as AvgDist,
	to_char(cast(dateval as date), 'MONTH') as MonthTEXT, 
	date_part('month',(cast(dateval as date))) as MonthVal
from public.rbr_AllRuns_2016_ID 
group by to_char(cast(dateval as date), 'MONTH'), date_part('month',(cast(dateval as date)))
order by date_part('month',(cast(dateval as date)))


--Average Dist by Week
select  avg(cast(rundist as decimal(16,2))) as AvgDist,
	extract('week' from (cast(dateval as date))) as weekVal,
	to_char(cast(dateval as date), 'MONTH') as MonthTEXT, 
	date_part('month',(cast(dateval as date))) as MonthVal 
from public.rbr_AllRuns_2016_ID 
group by extract('week' from (cast(dateval as date))), to_char(cast(dateval as date), 'MONTH'), date_part('month',(cast(dateval as date)))
order by date_part('month',(cast(dateval as date)))




