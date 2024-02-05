************
*Code to assess Moodle Student engagement on Moodle
*MSc Epidemiology (DL) LSHTM
*SS Jan 2024
************

// First download the 20XX log file for the module from Moodle and save. 
// Can download all logged entries (all) for that year or for selected components of Moodle page
cd "G:\D\LSHTM Teaching\DL\Study Design\Student Engagement - metrics\2023"
local raw "G:\D\LSHTM Teaching\DL\Study Design\Student Engagement - metrics\raw"

global section all // for all logs, or can be by moodle feature
global year 2023

*Part 1: Import Logs

clear all
import delimited "`raw'\all_activity_$year", varnames(1) bindquote(strict) 

drop description ipaddress origin

replace time=trim(time)
replace time = subinstr(time, ",", "",.)

generate accesstime = clock(time, "DM20Yhm")
move accesstime time
format accesstime %tc

generate accessdate = date(time, "DM20Yhm")
move accessdate time
format accessdate %td

// identify students from tutors: as of Jan 2023 student always full capitals, tutors first letter cap only
gen student=1 if ustrregexm(userfullname, "[A-Z][A-Z]")
replace student=0 if student==.
drop if userfullname=="-"
move student userfullname

// now students are tagged reformat all names lower case for easy use going forward
replace userfullname=lower(userfullname)
encode userfullname, gen(stud_id)
move stud_id userfullname
drop time

bysort stud_id: egen minacces=min(accessdate)
bysort stud_id: egen maxacces=max(accessdate)
move minacces stud_id
move maxacces stud_id
format minacces maxacces %td
gen accessperiod=maxacces-minacces

gen totalaccess=1

replace eventname=lower(eventname)
encode eventname, gen(action)
move action eventname

// only useful for specific-activity sessions:
gen viewed=1 if strpos(eventname, "view") | strpos(eventname, "search")
gen submitted=1 if strpos(eventname, "submit")
gen complete=1 if strpos(eventname, "complet") | strpos(eventname, "grad")
gen posted_interact=1 if strpos(eventname, "post") | strpos(eventname, "start") ///
 | strpos(eventname, "discuss")  | strpos(eventname, "add")  | strpos(eventname, "delete") ///
 | strpos(eventname, "downloa") | strpos(eventname, "create")

gen status_=1 if viewed==1
replace status_=2 if submitted==1 | posted_interact==1
replace status_=3 if complete==1
bysort stud_id: egen status=max(status_)
drop status_ viewed submitted complete posted_interact
move status eventname
label define status 1"viewed only" 2"interacted" 3"completed 1+activity"
label values status status

gen critique_1=1 if strpos(eventcontext, "Critiquing the Evidence")
gen studdesign_1=1 if strpos(eventcontext, "Quiz on the fundamentals")
gen field_1=1 if strpos(eventcontext, " Sampling")
gen analysis_1=1 if strpos(eventcontext, "Checklist for methods of analysis")
gen budget_1=1 if strpos(eventcontext, "Budget")

gen critique_d=1 if critique_1==1 & status==3
gen studdesign_d=1 if studdesign_1==1 & status==3
gen field_d=1 if field_1 ==1 & status==3
gen analysis_d=1 if  analysis_1==1 & status==3
gen budget_d=1 if budget_1==1 & status==3

for var critique_1-budget_1: bysort stud_id (X): replace X=X[1] if missing(X)
for var critique_d-budget_d: bysort stud_id (X): replace X=X[1] if missing(X)



label var accesstime "time accessed on this date"
label var accessdate "date content accessed"
label var stud_id "unique identifier - user"
label var minacces "first date of access"
label var maxacces "final date of access"
label var accessperiod "period content accessed (days)"
label var totalaccess "total number of visits"
label var status "level of completion"
label var student "student or tutor"
label var critique_1 "accessed session 1 - critique literature"
label var studdesign_1 "accessed session 2 - study designs"
label var field_1 "accessed session 3/4 - fieldwork"
label var analysis_1 "accessed session 5 - analysis"
label var budget_1 "accessed session 6 - budget"
label var critique_d "completed session 1 - critique literature"
label var studdesign_d "completed session 2 - study designs"
label var field_d "completed session 3/4 - fieldwork"
label var analysis_d "completed session 5 - analysis"
label var budget_d "completed session 6 - budget"

label data
label data "Raw Moodle user access metrics - $section EPM201 $year"
save "$section - $year", replace


use "$section - $year", clear
drop if student==0
collapse (count) totalaccess, by(stud_id minacces maxacces accessperiod status critique_1- budget_d)
count

label var totalaccess "total visits to this course"

gen month=month(minacces)
gen start_course=1 if minacc<td(01jun$year)
replace start_course=0 if start_course==.
label define yesno 0"started after" 1"started before"
label values start_c yesno
label var start_cour "started this course before exams?"

gen start2_course=1 if minacc<td(15april$year)
replace start2_course=0 if start2_course==.
label values start2_course yesno
label var start2_course "started this course before outline due?"
move start2_course start_cour

tab start2_course
tab start_course

for var critique_1-budget_d: replace X=0 if X==.
egen completed_all=rowtotal(critique_d studdesign_d field_d analysis_d budget_d)
label var completed_all "completed all 5 or fewer sessions"



label define month 1"Jan" 2"Feb" 3"Mar" 4"Apr" 5"May" 6"Jun" 7"Jul" 8"Aug" 9"Sept" 10"Oct" 11"Nov" 12"Dec"
label values month month
label var month "month first accessed"
recode status (1=1 "viewed only") (2/3=2 "interacted"), gen(status_2cat) label(status2)

sort stud_id
label data
label data "Summarised student access metrics for $moodle_section EPM201 $year"
save "summary $moodle_section $year", replace



*Part 1.1: Assess  session 1
use "summary $moodle_section $year", clear
summ accessperiod, det
summ totalaccess, det
tab start_cour status, row
tab completed_all,m

bysort start_cour: sum totalaccess, det
bysort status: sum totalaccess, det
bysort start_cour: sum totalaccess, det

set scheme white_tableau
/*
graph box totalaccess, over(status)  asyvars  ///
ytitle(total times accessed session)  title($moodle_section - Completion stats, size(small)) name("a$moodle_section", replace)
graph export "a$moodle_section", as(png) name("a$moodle_section") replace

graph box totalaccess, over(start_course)  asyvars  ///
ytitle(total times accessed session)  title($moodle_section - Initiation stats, size(small)) name("b$moodle_section", replace)
graph export "metrics_b$moodle_section", as(png) name("b$moodle_section") replace

graph box totalaccess, over(start_course)  over(status_2cat) asyvars  ///
ytitle(total times accessed session)  title($moodle_section - Initiation/Completion, size(small)) name("c$moodle_section", replace)
graph export "metrics_c$moodle_section", as(png) name("c$moodle_section") replace
*/

can do below in Stata or use the numbers in excel (preferred option)
// NOT used for sessions with only the 'viewed' option for everyone
graph bar (mean) status , over (start_cour) ///
ylabel(0 .2 "20%" .4 "40%" .6 "60%"  .8 "80%" 1 "100%")  ytitle(percent of students) ///
title(`: var label start_cour')  

// used for sessions with only the 'viewed' option
graph bar (mean) start_cour , over (totalaccess) ///
ylabel(0 .2 "20%" .4 "40%" .6 "60%"  .8 "80%" 1 "100%")  ytitle(percent of students) ///
title(started course < june exams)  note(total times accessed course, size(small) pos(6))

use "summary $moodle_section $year", clear
collapse (count) accessperiod, by(month)
rename accessperiod total_students
label var total_students "total students"
line total_students month
 