/*
	Script:  rBr_AnalyzeNikeGPSData.sql

	Purpose: Series of sql scripts to analyze tables and data created from rBr_ProcessNikeGPSData.sql 

	Instructions: run script

	Code built using PostgreSQL and PostGIS

	Available Scripts
	1. Find top 10 fasted miles
	2. Find top 10 slowest miles
	
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

select distinct runid from public.fastestmiles
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