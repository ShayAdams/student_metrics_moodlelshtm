************
*EPM201 Student engagement assessment
*Study Guide Metrics - 2021
*SS Nov 2021
************

cd "D:\LSHTM Teaching\DL\Study Design\Study Materials\Student Engagement - metrics\2021\"
*Part 1: Session 1 (Identifying a research gap)

clear all
import delimited "D:\LSHTM Teaching\DL\Study Design\Study Materials\Student Engagement - metrics\2021\session_1_2020.csv", varnames(1) 

drop affecteduser eventcontext origin

replace time=trim(time)
replace time = subinstr(time, ",", "",.)

generate accesstime = clock(time, "DM20Yhm")
move accesstime time
format accesstime %tc


generate accessdate = date(time, "DM20Yhm")
move accessdate time
format accessdate %td

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

encode eventname, gen(action)
move action eventname
gen viewed=1 if action>1 & action<5
gen submitted=1 if action==5
gen complete=1 if action==1

gen status_=1 if viewed==1
replace status_=2 if submitted==1
replace status_=3 if complete==1
bysort stud_id: egen status=max(status_)
drop status_ viewed submitted complete
move status eventname
label define status 1"viewed only" 2"viewed+submitted" 3"marked complete"
label values status status

label var accesstime "time accessed on this date"
label var accessdate "date content accessed"
label var stud_id "unique identifier - user"
label var minacces "first date of access"
label var maxacces "final date of access"
label var accessperiod "period content accessed (days)"
label var totalaccess "total number of visits"
label var status "level of completion"

label data
label data "Raw student access metrics for H5P Session 1 (Research Gaps) EPM201 2021"
save session_one_2021_all, replace


use session_one_2021_all, clear
drop if strpos(userfullname, "seyi") | strpos(userfullname, "friend-du") | strpos(userfullname, "gallagher")
collapse (count) totalaccess, by(stud_id minacces maxacces accessperiod status)

label var totalaccess "total visits to this course"

gen month=month(minacces)
gen start_course=1 if minacc<td(01jun2021)
replace start_course=0 if start_course==.
label define yesno 0"started > exams" 1"started < exams"
label values start_c yesno
label var start_cour "started this course before exams?"
label define month 1"Jan" 2"Feb" 3"Mar" 4"Apr" 5"May" 6"Jun" 7"Jul" 8"Aug" 9"Sept" 10"Oct" 11"Nov" 12"Dec"
label values month month
recode status (1=1 "viewed only") (2/3=2 "submited/complete"), gen(status_2cat) label(status2)

sort stud_id
label data
label data "Summarised student access metrics for H5P Session 1 (Research Gaps) EPM201 2021"
save session_one_2021_summary, replace



*Part 1.1: Assess access session 1
use session_one_2021_summary, clear
summ accessperiod, det
summ totalaccess, det
tab start_cour status, row

bysort start_cour: sum totalaccess, det
bysort status: sum totalaccess, det
bysort start_cour: sum totalaccess, det

set scheme white_tableau

graph box totalaccess, over(status)  asyvars  ///
ytitle(total times accessed session)  title(Session 1: Develop a research question - Completion stats, size(small)) name("session1a", replace)
graph export "session1a_metrics", as(png) name("session1a") replace

graph box totalaccess, over(start_course)  asyvars  ///
ytitle(total times accessed session)  title(Session 1: Develop a research question - Initiation stats, size(small)) name("session1b", replace)
graph export "session1b_metrics", as(png) name("session1b") replace

graph box totalaccess, over(start_course)  over(status_2cat) asyvars  ///
ytitle(total times accessed session)  title(Session 1: Develop a research question - Initiation/Completion, size(small)) name("session1c", replace)
graph export "session1c_metrics", as(png) name("session1c") replace


graph bar (mean) status , over (start_cour) ///
ylabel(0 .2 "20%" .4 "40" .6 "60%" .7 "70%" .8 "80%")  ytitle(percent of students) ///
title(`: var label start_cour')  /// 
bar(1, lwidth(vvthick)) bar(2, lwidth(vvthick))

*Part 1.2 All data

use session_one_2021_all, clear
