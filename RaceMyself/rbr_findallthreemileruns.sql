--All three mile runs in 2016
select  runid, 
	dateval, 
	runtype, 
	rundist, 
	runtime,
	avgpacepermile,
	fastestmile,
	fastestmilemarker
from public.rbr_AllRuns_2016_ID 
where round((cast(rundist  as decimal(16,2))),0) = 3 and runtype != 'Intervals'
