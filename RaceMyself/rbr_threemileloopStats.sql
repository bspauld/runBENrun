--Three Mile Loop Run Stats
Select  dateval as "Date",
	cast(rundist as decimal(3,2)) as "Total Distance",
	cast(runtime as time) as "Run Time",
	cast(avgpacepermile as time) as "Average Pace",
	cast(fastestmile as time) as "Fastest Mile",
	fastestmilemarker as "Fastest Mile Marker"
from public.rbr_AllRuns_2016_ID 
where runid in (48,50,68,89,102,107,135,323,201,205,211,223,233,235,240,242,248,253,214,69,78,55,32,36,45 )
order by dateval
