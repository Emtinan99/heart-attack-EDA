proc contents data=heart.heartprediction;
run;


proc print data=heart.heartprediction (obs=10);
run;

proc means data=heart.heartprediction mean median std min max;
var Age BMI Cholesterol 'Heart Rate'n Diabetes Obesity Cholesterol Triglycerides;
run;

proc freq data=heart.heartprediction;
table Sex 'Blood Pressure'n Diet Country Continent Hemisphere;
run;

proc means data=heart.heartprediction mean;
class Country;
var 'Heart Attack Risk'n;
run;

proc sgplot data=heart.heartprediction;
vbar Country / response= 'Heart Attack Risk'n stat=mean;
	xaxis label= "Country";
	yaxis label= "Heart Attack Risk";
run;

proc means data=heart.heartprediction mean;
class Sex;
var Diabetes Obesity Cholesterol Triglycerides 'Heart Attack Risk'n;
run;

proc sql;
	select 
		case when Income < 25000 then 'Low Income'
		when Income between 25000 and 74999 then 'Mid Income'
		else 'High Income' end as Income_Group,
	mean('Heart Attack Risk'n) as Avg_Heart_Attackk_Rate
from heart.heartprediction
group by Income_Group;
quit;

proc Sql;
	select
		'Family History'n as Family_History,
		mean('Heart Attack Risk'n)*100 as Heart_Attack_Risk_Risk_Percent
		from heart.heartprediction
		group by 'Family History'n;
quit;

proc means data=heart.heartprediction mean;
	class Smoking;
	variable 'Heart Attack Risk'n;
run;
	
proc means data=heart.heartprediction mean;
	class 'Alcohol Consumption'n;
	var 'Heart Attack Risk'n;
run;


proc means data=heart.heartprediction mean;
	class 'Alcohol Consumption'n Smoking;
	var 'Heart Attack Risk'n;
run;

proc means data=heart.heartprediction mean;
    class Diet;
    var 'Heart Attack Risk'n;
run;

proc sql;
    select 
        count(*) as N,
        mean('Heart Attack Risk'n) as Risk_Percentage 
    from heart.heartprediction
    where Smoking = 1
      and 'Alcohol Consumption'n = 1
      and Diet = "Unhealthy"
      and 'Family History'n = 1;
quit;



proc means data=heart.heartprediction;
class 'Stress level'n;
var 'Heart Attack Risk'n;
run;

proc sgplot data=heart.heartprediction;
	vline 'Stress Level'n / response='Heart Attack Risk'n stat=mean;
	xaxis label= "Stress Level";
	yaxis label= "Heart Attack Risk";
run;

proc means data=heart.heartprediction;
class 'Medication Use'n;
var 'Heart Attack Risk'n;
run;
proc means data=heart.heartprediction;
class 'previous Heart Problems'n;
var 'Heart Attack Risk'n;
run;

proc means data=heart.heartprediction;
class 'Physical Activity Days Per Week'n;
var 'Heart Attack Risk'n;
run;

proc sgplot data=heart.heartprediction;
	vline 'Physical Activity Days per week'n / response= 'Heart Attack Risk'n stat=mean markers;
	yaxis label = "Mean Hesart Attack Risk";
	xaxis label= "Physical Activity (Days per week)";
run;
	

data heart.binned;
    set heart.heartprediction;
    if 'Sedentary Hours Per Day'n < 2 then SedentaryGroup = '0-2 hrs';
    else if 'Sedentary Hours Per Day'n < 4 then SedentaryGroup = '2-4 hrs';
    else if 'Sedentary Hours Per Day'n < 6 then SedentaryGroup = '4-6 hrs';
    else if 'Sedentary Hours Per Day'n < 8 then SedentaryGroup = '6-8 hrs';
    else SedentaryGroup = '8+ hrs';
run;

proc means data=heart.binned mean maxdec=3;
    class SedentaryGroup;
    var 'Heart Attack Risk'n;
run;

proc sgplot data=heart.binned;
    vbar SedentaryGroup / response='Heart Attack Risk'n stat=mean;
    yaxis label="Mean Heart Attack Risk";
    xaxis label="Sedentary Hours";
run;


proc means data=heart.heartprediction;
class 'Sleep Hours Per Day'n;
var 'Heart Attack Risk'n;
run;

proc means data=heart.heartprediction;
class 'Sleep Hours Per Day'n;
var 'Heart Attack Risk'n;
run;

proc sgplot data=heart.heartprediction;
vline 'Sleep Hours Per Day'n / response= 'Heart Attack Risk'n stat=mean markers;
yaxis label='Heart Attack Risk';
xaxis label='Sleep Hours Per Day';
run;


proc sql;
	select 
		case when Cholesterol <101 then 'Healthy cholesterol level'
		else 'unhealthy' end as Cholesterol_Level,
	mean("Heart Attack Risk"n) as Avg_Heart_Attack_Risk
from heart.heartprediction
group by Cholesterol_Level;
run;

proc sql;
    create table scored as
    select *,
        ( (Smoking = 0) +
          ('Alcohol Consumption'n = 0) +
          (Diet = "Healthy") +
          ('Family History'n = 0) +
          (Sex = "Male") +
          (Country = "South Korea") +
          ('Sleep Hours Per Day'n = 8) +
          ('Physical Activity Days Per Week'n = 0) +
          ('Stress Level'n = 6) +
          ('Previous Heart Problems'n = 1)
        ) as match_score
    from heart.heartprediction;
quit;

proc sql;
    create table match_summary as
    select match_score,
           count(*) as N,
           mean('Heart Attack Risk'n) as Avg_Risk
    from scored
    group by match_score
    order by match_score;
quit;

proc sgplot data=match_summary;
    vbar match_score / response=Avg_Risk stat=mean datalabel;
    xaxis label="Number of Conditions Matched (match_score)";
    yaxis label="Average Heart Attack Risk";
    title "Heart Attack Risk vs. Number of Matched Conditions";
run;

proc sql;
    create table matched_8 as
    select *,
        /* Flag each condition with 1 (met) or 0 (not met) */
        (Smoking = 0)                            as match_smoking,
        ('Alcohol Consumption'n = 0)            as match_alcohol,
        (Diet = "Healthy")                      as match_diet,
        ('Family History'n = 0)                 as match_family_history,
        (Sex = "Male")                          as match_sex,
        (Country = "South Korea")               as match_country,
        ('Sleep Hours Per Day'n = 8)            as match_sleep,
        ('Physical Activity Days Per Week'n = 0) as match_activity,
        ('Stress Level'n = 6)                   as match_stress,
        ('Previous Heart Problems'n = 1)        as match_heart_history,

        /* Total match score */
        calculated match_smoking +
        calculated match_alcohol +
        calculated match_diet +
        calculated match_family_history +
        calculated match_sex +
        calculated match_country +
        calculated match_sleep +
        calculated match_activity +
        calculated match_stress +
        calculated match_heart_history as match_score
    from heart.heartprediction
    having match_score = 8;
quit;

proc print data=matched_8 noobs;
    var match_smoking match_alcohol match_diet match_family_history 
        match_sex match_country match_sleep match_activity 
        match_stress match_heart_history match_score 'Heart Attack Risk'n;
    title "Observations Matching 8 of 10 Conditions and Their Heart Attack Risk";
run;

