/*
  script: runanomalies.sql
  
  purpose: script to test GPS anomalies in the runBENrun data
  
  instructions: run the script

*/


select  i.runid,
	i.dateval,
	count(*) as TotalPoints, 
	count(distinct p.finaltimecounter) as TotalDistinctTimePoints, 
	(count(*)-count(distinct p.finaltimecounter)) as PercentPoints,
	cast(i.rundist as float)  as RunDist,
	case
	    when count(distinct p.finaltimecounter) < count(*) then 'Bad GPS'
	    when count(distinct p.finaltimecounter) > count(*) then 'Huh?'
	    when count(distinct p.finaltimecounter) = count(*) then 'Good GPS'
	else 'Unknown'
	end as GPSTest
from public.rbr_AllRuns_2016_Points p inner join public.rbr_AllRuns_2016_ID i on p.runid = i.runid
group by i.runid,i.rundist,i.dateval
order by i.runid;
