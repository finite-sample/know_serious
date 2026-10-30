/*2008 study: 1,633 observations total*/
use "/Users/kabirkhanna/Dropbox/Political Reasoning Group/Partisan Bias Project/Stata Files/merged.dta", clear

/*Run "KK Partisan Bias Code Aug 2012" recodes*/
run "/Users/kabirkhanna/Dropbox/Political Reasoning Group/Partisan Bias Project/Stata Files/KK Partisan Bias Recode Section.do"

/*Percentages for chart 1-31-13*/
tab pid_app tri_debt if rd == 0, row
tab pid_app tri_unempl2 if rd == 0, row
tab pid_app tri_health2 if rd == 0, row
tab pid_app tri_gasr_corr_st if rd == 0, row
tab pid_app tri_estate if rd == 0, row

tab pid_app tri_debt if rd == 2, row
tab pid_app tri_unempl2 if rd == 2, row
tab pid_app tri_health2 if rd == 2, row
tab pid_app tri_gasr_corr_st if rd == 2, row
tab pid_app tri_estate if rd == 2, row

/*Vary correct answer window*/
recode l5r 3.25/3.29=1 0/3.24=0 3.299/100=2, gen(tri_gasr_23) /*23.52 percent correct*/
recode l5r 3.22/3.32=1 0/3.21=0 3.33/100=2, gen(tri_gasr_33) /*32.53 percent correct*/
recode l5r 3.19/3.35=1 0/3.18=0 3.36/100=2, gen(tri_gasr_43) /*45.03 percent correct*/
gen tri_gasr_08 = tri_gasr_33 /*32.53 percent correct*/
recode l5r 3.17/3.37=1 0/3.16=0 3.38/100=2, gen(tri_gasr_pay) /*46.30 percent correct*/
recode l5r 2.943/3.597=1 0/2.942=0 3.598/100=2, gen(tri_gasr_10) /*84.07 percent correct*/

recode l2 4.6/5=1 0/4.5=0 5.1/100=2, gen(tri_unempl_23) /*21.53 percent correct*/
recode l2 4.2/5.4=1 0/4.1=0 5.5/100=2, gen(tri_unempl_33) /*33.51 percent correct*/
recode l2 3.9/5.7=1 0/3.8=0 5.8/100=2, gen(tri_unempl_43) /*43.27 percent correct*/
recode l2 4.3/5.3=1 0/4.2=0 5.4/100=2, gen(tri_unempl_08) /*31.49 percent correct*/
recode l2 3.8/5.8=1 0/3.7=0 5.9/100=2, gen(tri_unempl_pay) /*44.82 percent correct*/
recode l2 4.32/5.28=1 0/4.31=0 5.29/100=2, gen(tri_unempl_10) /*29.48 percent correct*/

recode l3 14/17.6=1 0/13.9=0 17.7/100=2, gen(tri_health_23) /*24.09 percent correct*/
recode l3 12.6/19=1 0/12.5=0 19.1/100=2, gen(tri_health_33) /*33.40 percent correct*/
recode l3 11.7/19.9=1 0/11.6=0 20/100=2, gen(tri_health_43) /*36.03 percent correct*/
recode l3 14.8/16.8=1 0/14.7=0 16.9/100=2, gen(tri_health_08) /*15.18 percent correct*/
gen tri_health_pay = tri_health_08 /*15.18 percent correct*/
recode l3 14.22/17.38=1 0/14.21=0 17.39/100=2, gen(tri_health_10) /*19.43 percent correct*/

/*Non-response*/
tab h1c l1 if complete == . & r_PIDloc == 0 & rd == 0, miss /*1 dropped out*/
tab h1c l1 if complete == . & r_PIDloc == 0 & rd == 1, miss /*3 dropped out*/
tab h1c l1 if complete == . & r_PIDloc == 0 & rd == 2, miss /*1 dropped out*/

tab k3a l1 if complete == . & r_PIDloc == 1 & rd == 0, miss /*1 dropped out*/
tab k3a l1 if complete == . & r_PIDloc == 1 & rd == 1, miss /*1 dropped out*/
tab k3a l1 if complete == . & r_PIDloc == 1 & rd == 2, miss /*1 dropped out*/

/*Calculate point estimates (mean if closed-ended and median if open-ended)*/
mean debt_num if rd != 1 & (pid_app == 1 | pid_app == 4), over (rd pid_app)
mean estate_num if rd != 1 & (pid_app == 1 | pid_app == 4), over (rd pid_app)

summ l2 if l2 >= 0 & pid_app == 1 & rd == 0, d
summ l2 if l2 >= 0 & pid_app == 4 & rd == 0, d
summ l2 if l2 >= 0 & pid_app == 1 & rd == 2, d
summ l2 if l2 >= 0 & pid_app == 4 & rd == 2, d

summ l3 if l3 >= 0 & pid_app == 1 & rd == 0, d
summ l3 if l3 >= 0 & pid_app == 4 & rd == 0, d
summ l3 if l3 >= 0 & pid_app == 1 & rd == 2, d
summ l3 if l3 >= 0 & pid_app == 4 & rd == 2, d

summ l5r if l5r >= 0 & pid_app == 1 & rd == 0, d
summ l5r if l5r >= 0 & pid_app == 4 & rd == 0, d
summ l5r if l5r >= 0 & pid_app == 1 & rd == 2, d
summ l5r if l5r >= 0 & pid_app == 4 & rd == 2, d


/*Calculate point estimates for NO BUSH REF (mean if closed-ended and median if open-ended)*/
mean debt_num if r_bushref == 0 & rd != 1 & (pid_app == 1 | pid_app == 4), over (rd pid_app)
mean estate_num if r_bushref == 0 & rd != 1 & (pid_app == 1 | pid_app == 4), over (rd pid_app )

summ l2 if l2 >= 0 & r_bushref == 0 & pid_app == 1 & rd == 0, d
summ l2 if l2 >= 0 & r_bushref == 0 & pid_app == 4 & rd == 0, d
summ l2 if l2 >= 0 & r_bushref == 0 & pid_app == 1 & rd == 2, d
summ l2 if l2 >= 0 & r_bushref == 0 & pid_app == 4 & rd == 2, d

summ l3 if l3 >= 0 & r_bushref == 0 & pid_app == 1 & rd == 0, d
summ l3 if l3 >= 0 & r_bushref == 0 & pid_app == 4 & rd == 0, d
summ l3 if l3 >= 0 & r_bushref == 0 & pid_app == 1 & rd == 2, d
summ l3 if l3 >= 0 & r_bushref == 0 & pid_app == 4 & rd == 2, d

summ l5r if l5r >= 0 & r_bushref == 0 & pid_app == 1 & rd == 0, d
summ l5r if l5r >= 0 & r_bushref == 0 & pid_app == 4 & rd == 0, d
summ l5r if l5r >= 0 & r_bushref == 0 & pid_app == 1 & rd == 2, d
summ l5r if l5r >= 0 & r_bushref == 0 & pid_app == 4 & rd == 2, d







/*2004*/
use "/Users/kabirkhanna/Dropbox/Political Reasoning Group/Partisan Bias Project/Stata Files/PriorLupia20004.surveydata.dta", clear
/*Run "KK Re-Analysis 2004 Data Aug 2012" recodes*/
run "/Users/kabirkhanna/Dropbox/Political Reasoning Group/Partisan Bias Project/Stata Files/KK 2004 Recode Section.do"


tab pid3a tri_debt if time == 0 & pay == 0, row
tab pid3a tri_unempl if time == 0 & pay == 0, row
tab pid3a tri_unins if time == 0 & pay == 0, row
tab pid3a tri_poor if time == 0 & pay == 0, row
tab pid3a tri_estate if time == 0 & pay == 0, row

tab pid3a tri_debt if time == 0 & pay == 1, row
tab pid3a tri_unempl if time == 0 & pay == 1, row
tab pid3a tri_unins if time == 0 & pay == 1, row
tab pid3a tri_poor if time == 0 & pay == 1, row
tab pid3a tri_estate if time == 0 & pay == 1, row


/*Vary correct answer window*/
recode q15 6.6/24.6=1 0/6.5=0 24.7/1110=2 -1 -2=., gen(tri_health_23) /*20.68 percent correct*/
recode q15 2/29.2=1 0/1.9=0 29.3/1110=2 -1 -2=., gen(tri_health_33) /*32.51 percent correct*/
recode q15 0/31.2=1 31.3/1110=2 -1 -2=., gen(tri_health_43) /*41.02 percent correct*/
recode q15 12.6/18.6=1 0/12.5=0 18.7/1110=2 -1 -2=., gen(tri_health_08) /*6.98 percent correct*/
gen tri_health_pay = tri_health_08
recode q15 14.04/17.16=1 0/14.03=0 17.17/1110=2 -1 -2=., gen(tri_health_10) /*5.87 percent correct*/

recode q18 0/6.4=0 6.5/18.5=1 18.6/100=2 -1 -2=., gen(tri_poor_23) /*23.72 percent correct*/
recode q18 0/4.4=0 4.5/20.5=1 20.6/100=2 -1 -2=., gen(tri_poor_33) /*36.82 percent correct*/
recode q18 0/0.4=0 0.5/24.5=1 24.6/100=2 -1 -2=., gen(tri_poor_43) /*40.99 percent correct*/
recode q18 9.5/15.5=1 0/9.4=0 15.6/100=2 -1 -2=., gen(tri_poor_08) /*17.35 percent correct*/
gen tri_poor_pay = tri_poor_08
recode q18 11.25/13.75=1 0/11.24=0 13.76/100=2 -1 -2=., gen(tri_poor_10) /*4.34 percent correct*/


/*GS Method?*/
drop temp temp_rec
gen temp = abs(q15 - 15.6) if q15 >= 0
recode temp 0/13.6=1 13.7/1110 =0, gen(temp_rec)
tab temp_rec


/*Try alternate correct answer windows for Uninsured 2004 and Poverty 2004*/
tab pid3a tri_health_23 if time == 0 & pay == 0, row
tab pid3a tri_health_23 if time == 0 & pay == 1, row
tab pid3a tri_poor_23 if time == 0 & pay == 0, row
tab pid3a tri_poor_23 if time == 0 & pay == 1, row

tab pid3a tri_health_33 if time == 0 & pay == 0, row
tab pid3a tri_health_33 if time == 0 & pay == 1, row
tab pid3a tri_poor_33 if time == 0 & pay == 0, row
tab pid3a tri_poor_33 if time == 0 & pay == 1, row

tab pid3a tri_health_10 if time == 0 & pay == 0, row
tab pid3a tri_health_10 if time == 0 & pay == 1, row
tab pid3a tri_poor_10 if time == 0 & pay == 0, row
tab pid3a tri_poor_10 if time == 0 & pay == 1, row


/*Examine distribution of raw data for Debt 2004*/
tab q16 pid3a if pid3a !=2 & time == 0 & q16 > 0 & pay == 0, col
tab q16 pid3a if pid3a !=2 & time == 0 & q16 > 0 & pay == 1, col


/*Calculate point estimates (mean if closed-ended and median if open-ended)*/
mean dev_unempl if q13 > 0 & pid3a != 2 & time == 0, over(pay pid3a) /*Unemployed 04*/
mean dev_estate if q14 > 0 & pid3a != 2 & time == 0, over(pay pid3a) /*Estate 04*/
mean dev_debt if q16 > 0 & pid3a != 2 & time == 0, over(pay pid3a) /*Debt 04*/

summ q15 if q15 > 0 & pid3a != 2 & pid3a == 3 & time == 0 & pay == 0, d /*Uninsured 04*/
summ q15 if q15 > 0 & pid3a != 2 & pid3a == 1 & time == 0 & pay == 0, d /*Uninsured 04*/
summ q15 if q15 > 0 & pid3a != 2 & pid3a == 3 & time == 0 & pay == 1, d /*Uninsured 04*/
summ q15 if q15 > 0 & pid3a != 2 & pid3a == 1 & time == 0 & pay == 1, d /*Uninsured 04*/

summ q18 if q18 > 0 & pid3a != 2 & pid3a == 3 & time == 0 & pay == 0, d /*Poverty 04*/
summ q18 if q18 > 0 & pid3a != 2 & pid3a == 1 & time == 0 & pay == 0, d /*Poverty 04*/
summ q18 if q18 > 0 & pid3a != 2 & pid3a == 3 & time == 0 & pay == 1, d /*Poverty 04*/
summ q18 if q18 > 0 & pid3a != 2 & pid3a == 1 & time == 0 & pay == 1, d /*Poverty 04*/






/*ANES 2004*/
clear
use "/Users/kabirkhanna/Dropbox/Political Reasoning Group/Partisan Bias Project/ANES 2004 Data/anes2004TSdta/anes2004TS.dta"

tab V043026 /*Bush approval economy (binary)*/
tab V043114 /*party id*/
tab V043115 /*party lean*/

gen pid3 = .
replace pid3 = 1 if V043114 == 1 | V043115 == 1
replace pid3 = 2 if V043114 == 3 & V043115 == 3
replace pid3 = 3 if V043114 == 2 | V043115 == 5

tab V043026 pid3 if V043026 != 8 & V043026 != 9, col /*79.79% of Reps approve (20.21% disapprove), and 10.59% of Dems approve (89.41% disapprove)*/






/*Analyze 2004/2008 Hierarchical Dataset 2-22-13*/
use "/Users/kabirkhanna/Dropbox/Political Reasoning Group/Partisan Bias Project/Stata Files/KN0408.hier.merge.33.dta", clear

*Look at % correct for knowledge items by RD condition
tab pay tri_dv6 if pollid == 2004, row
tab pay tri_dv7 if pollid == 2004, row
tab pay tri_dv8 if pollid == 2004, row
tab pay tri_dv9 if pollid == 2004, row
tab pay tri_dv10 if pollid == 2004, row

tab rd tri_dv1 if pollid == 2008, row
tab rd tri_dv2 if pollid == 2008, row
tab rd tri_dv3 if pollid == 2008, row
tab rd tri_dv4 if pollid == 2008, row
tab rd tri_dv5 if pollid == 2008, row


*Look at median RT for knowledge items by RD condition
summ t_l1 if pollid == 2008 & rd == 0, d
summ t_l1 if pollid == 2008 & rd == 2, d
summ t_l2 if pollid == 2008 & rd == 0, d
summ t_l2 if pollid == 2008 & rd == 2, d
summ t_l3 if pollid == 2008 & rd == 0, d
summ t_l3 if pollid == 2008 & rd == 2, d
summ t_l4 if pollid == 2008 & rd == 0, d
summ t_l4 if pollid == 2008 & rd == 2, d
summ t_l5 if pollid == 2008 & rd == 0, d
summ t_l5 if pollid == 2008 & rd == 2, d


egen nmiss08 = rmiss(tri_dv1 tri_dv2 tri_dv3 tri_dv4 tri_dv5) if pollid == 2008
mvpatterns tri_dv1 tri_dv2 tri_dv3 tri_dv4 tri_dv5 if pollid == 2008
*81 missing on all five items
*13 missing on tri_dv3 only, 13 missing on tri_dv4 only, 7 missing on tri_dv1 only
*4 or fewer missing on every other possible combination (of two or more items missing)

egen nmiss04 = rmiss(tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10) if pollid == 2004
mvpatterns tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10 if pollid == 2004
*353 missing on all five items
*32 missing on tri_dv8 only, 10 missing on tri_dv9 only, 9 missing on tri_dv10 only
*5 or fewer missing on every other possible combination (of two or more items missing)


/*Rerun model using various RT cut-points, e.g. 30 s, 45 s, 60 s*/
use "/Users/kabirkhanna/Dropbox/Political Reasoning Group/Partisan Bias Project/Stata Files/KN0408.hier.merge.33.dta", clear
keep if pollid==2008 & (pid_app==1 | pid_app==4)
drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
reshape long tri_dv t_l t_disp, i(caseid) /*t_l is the new name for response time*/
			
gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7 r_bushref r_PIDloc, i(caseid) link(ologit)
gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7 r_bushref r_PIDloc if t_l <= 15, i(caseid) link(ologit)
gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7 r_bushref r_PIDloc if t_l <= 30, i(caseid) link(ologit)
gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7 r_bushref r_PIDloc if t_l <= 45, i(caseid) link(ologit)
gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7 r_bushref r_PIDloc if t_l <= 60, i(caseid) link(ologit)

gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7 r_bushref r_PIDloc if t_l > 15 & t_l <= 20, i(caseid) link(ologit) /*crisp monetary effect even with n = 818*/
gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7 r_bushref r_PIDloc if t_l > 45 & t_l <= 60, i(caseid) link(ologit) /*coefficients in wrong direction but n.s.*/


*Do most slow responses come from small number of respondents? Not really
tab caseid t_l if t_l > 90
tab caseid t_l if t_l > 100


*What is going on with 21 originally excluded (> 100 s)?
use "/Users/kabirkhanna/Dropbox/Political Reasoning Group/Partisan Bias Project/Stata Files/KN0408.hier.merge.33.dta", clear
keep if pollid==2008 & (pid_app==1 | pid_app==4)
drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10

gen flag = .
replace flag = 1 if t_l3 > 100

reshape long tri_dv t_l t_disp, i(caseid) /*t_l is the new name for response time*/

tab rd t_l if t_l > 100
tab tri_dv rd if t_l > 100 & pid_app == 1, col /*Noisy data among Dems*/
tab tri_dv rd if t_l > 100 & pid_app == 4, col /*Expected pattern among Reps*/

gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7 r_bushref r_PIDloc if t_l <= 100, i(caseid) link(ologit) /*crisp results*/

/*14 slow responders on l3*/
tab tri_dv rd if flag == 1 & pid_app == 1, col /*Mon increases overestimation among Dems - unexpected*/
tab tri_dv rd if flag == 1 & pid_app == 4, col /*Mon increases overestimation among Reps - expected*/



/*Check 2004 total interview time 2-22-13*/
use "/Users/kabirkhanna/Dropbox/Political Reasoning Group/Partisan Bias Project/Stata Files/PriorLupia20004.surveydata.dta", clear
/*Run "KK Re-Analysis 2004 Data Aug 2012" recodes*/
run "/Users/kabirkhanna/Dropbox/Political Reasoning Group/Partisan Bias Project/Stata Files/KK 2004 Recode Section.do"

summ int_dur, d /*median interview time of 13 min*/
tab int_dur
histogram int_dur if int_dur <= 60

*1.00 percent of interviews were 4.80 min (4:48) or less 
*1.99 percent of interviews were 5.28 min (5:17) or less
*4.15 percent of interviews were 6.00 min (6:00) or less
*4.98 percent of interviews were 6.30 min (6:18) or less


/*Re-run joint mode excluding very short interview times 2-22-13*/
use "/Users/kabirkhanna/Dropbox/Political Reasoning Group/Partisan Bias Project/Stata Files/KN0408.hier.merge.33.dta", clear

gen flag1 = .
replace flag1 = 1 if int_dur <= 4.80

gen flag2 = .
replace flag2 = 1 if int_dur <= 5.28

gen flag3 = .
replace flag3 = 1 if int_dur <= 6.00

gen flag4 = .
replace flag4 = 1 if int_dur <= 6.30

reshape long tri_dv t_l t_disp, i(caseid) /*t_l is the new name for response time*/

* Fixing Bushref (as KN 2004 debt bushref is 1)
gen nbushref = r_bushref
replace nbushref = 1 if mod(_n+2, 10) == 0
replace nbushref = 0 if _n < 8
replace nbushref = 0 if _n == 9 | _n == 10
			  
keep if (time ==0 | time ==.) & pid7~=4 & (pid_app==1 | pid_app==4 | pid_app==.) & (rd1~=1)

gllamm tri_dv pay pid7 payXpid7, i(caseid pollid) link(ologit) 
gllamm tri_dv pay pid7 payXpid7 if flag1 != 1, i(caseid pollid) link(ologit) 
gllamm tri_dv pay pid7 payXpid7 if flag2 != 1, i(caseid pollid) link(ologit) 
gllamm tri_dv pay pid7 payXpid7 if flag3 != 1, i(caseid pollid) link(ologit) 
gllamm tri_dv pay pid7 payXpid7 if flag4 != 1, i(caseid pollid) link(ologit) 



/*Plot % overestimaing (pooling DVs) by instruction screen completion time in 2008*/
use "/Users/kabirkhanna/Dropbox/Political Reasoning Group/Partisan Bias Project/Stata Files/KN0408.hier.merge.33.dta", clear
keep if pollid==2008 & (pid_app==1 | pid_app==4)
drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
reshape long tri_dv t_l t_disp, i(caseid) /*t_l is the new name for response time*/

tab t_disp, miss
/*5th percentile of screen completion time is 5 seconds (long format, i.e. pooling rd conditions)*/
/*95th percentile of screen completion time is 70 seconds (long format, i.e. pooling rd conditions)*/

gen t_disp1 = t_disp if rd == 0
gen t_disp2 = t_disp if rd == 1
gen t_disp3 = t_disp if rd == 2

*gen tri_con = tri_dv if rd == 0
*gen tri_ver = tri_dv if rd == 1
*gen tri_mon = tri_dv if rd == 2


/*Lowess smoothed graphs*/
lowess tri_dv t_disp if t_disp <= 240 & rd == 0, nograph gen(tri_con)
lowess tri_dv t_disp if t_disp <= 240 & rd == 1, nograph gen(tri_ver)
lowess tri_dv t_disp if t_disp <= 240 & rd == 2, nograph gen(tri_mon)

scatter tri_con tri_ver tri_mon t_disp if t_disp <= 120, legend(size(medsmall))


*Percent Overestimating by Screen Completion Time (Instructions)
egen probg1 = mean(tri_dv > 1), by(pid3 rd t_disp)

twoway  (lowess probg1 t_disp if pid3 == 3 & rd == 0 & t_disp <= 90, lpattern(dot) lcol(blue) scheme(s1color)) ///
		(lowess probg1 t_disp if pid3 == 1 & rd == 0 & t_disp <= 90, lpattern(dot) lcol(red)) ///
		(lowess probg1 t_disp if pid3 == 3 & rd == 1 & t_disp <= 90, lpattern(dash) lcol(blue)) ///
		(lowess probg1 t_disp if pid3 == 1 & rd == 1 & t_disp <= 90, lpattern(dash) lcol(red)) ///
		(lowess probg1 t_disp if pid3 == 3 & rd == 2 & t_disp <= 90, lcol(blue)) ///
		(lowess probg1 t_disp if pid3 == 1 & rd == 2 & t_disp <= 90, lcol(red)), ///
ylabel(0[.1].8) xscale(range(0, 90)) yscale(range(0, .8))  t2title("Overestimation vs. Screen Completion Time by Party ID and Condition (2008)") ytitle("P(Overestimation)") xtitle("Screen Completion Time (Seconds)") legend(cols(2) lab(1 "Control: Dems") lab(2 "Control: Reps") lab(3 "Verbal: Dems") lab(4 "Verbal: Reps") lab(5 "Monetary: Dems") lab(6 "Monetary: Reps"))




egen probg1_dem = mean(tri_dv > 1) if pid3 == 1, by(rd t_disp)
egen probg1_rep = mean(tri_dv > 1) if pid3 == 3, by(rd t_disp)
