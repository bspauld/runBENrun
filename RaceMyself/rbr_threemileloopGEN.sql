/*
   Create table with all three mile runs on the Loop course from RunIDs

   Create a speed category for easy visualization later, also include
   lat,lon and geom column

   Order by idvallist field to get points in the right order
   
*/
drop table public.threemileloops;
create table public.threemileloops
(runid int,idvallist int,dateval varchar(50), finalspeed decimal(16,6), 
 finaltimecounter time, lat decimal(16,6), lon decimal(16,6),speedcat int);
--Add Geometry Column
SELECT AddGeometryColumn ('public','threemileloops','geom',4326,'POINT',2);
--Insert into the table
insert into public.threemileloops
select 	runid,
	idvallist,
	dateval,
	finalspeed,
	cast(finaltimecounter as time) as finaltimecounter,
	lat,
	lon,
	case
		when finalspeed between 0 and 2 then 1
		when finalspeed between 2 and 3.7 then 2
		when finalspeed between 3.7 and 4.4 then 3
		when finalspeed between 4.4 and 7 then 4
		when finalspeed > 7 then 5
		else 1
	end as speedcat,
	geom 
from public.rbr_AllRuns_2016_Points
where runid in (48,50,68,89,102,107,135,323,201,205,211,223,233,
		235,237,240,242,248,253,214,69,78,55,32,36,45 )
order by runid, idvallist;

