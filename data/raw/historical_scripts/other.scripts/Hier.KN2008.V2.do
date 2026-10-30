** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **
**									    	**								
**  Partisan Inference Analyses			
**  Last Edited: 4/14/2013 by GS		
**  Analyses: KN 2008 Hier/From Cmn. Subset
**											
** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **		

* Set Library Location for finding survwgt (Leave it for GS)
	sysdir set PLUS "\\files\dept\WWS\Research\MPRIOR\stata\"
	* ssc install gllamm

* Notes
	* 2008 subset
		*keep if pid_app==1 | pid_app==4 | pid_app==.
		
	* Some gllamm tips
		* do adaptive quadrature: use option adapt 
		* for exponentiated coefficients: after the comma, add the word 'eform'
		* to store estimates of a model: after the running the model, enter the following command: estimates store model1
		* to restore estimates: estimates restore model1
		* to compare two models: lrtest model1 model2
		*************************************************************
		
* Load and reshape
	use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
	keep if pollid==2008 & (pid_app==1 | pid_app==4)
	drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10 pct_dv6 pct_dv7 pct_dv8 pct_dv9 pct_dv10 raw_dv6 raw_dv7 raw_dv8 raw_dv9 raw_dv10
	reshape long tri_dv pct_dv raw_dv t_l, i(caseid)
	
	* for item level r.e.
		gen seq = mod(_n-1,5) + 1
	
	* for item level f.e
		gen seq1=1 if seq==1
		replace seq1=0 if seq~=1
			
		gen seq2=1 if seq==2
		replace seq2=0 if seq~=2
			
		gen seq3=1 if seq==3
		replace seq3=0 if seq~=3
			
		gen seq4=1 if seq==4
		replace seq4=0 if seq~=4
	
	* Some recodes
		gen rd1Xpid7new = rd1*pid7new
		gen rd2Xpid7new = rd2*pid7new
		
		recode rd 2 3 =1, gen(incentive)
		gen incXpid3b = incentive*pid3b
		
		gen incXnewpk  		 = incentive*newpk
		gen incXpid3bXnewpk  = pid3b*incentive*newpk
		gen pid3bXnewpk		 = pid3b*newpk
				
		gen newpkSQ = newpk^2
		gen pid3bXnewpkSQ 	  = pid3b*newpkSQ
		gen incXnewpkSQ 	  = incentive*newpkSQ
		gen incXpid3bXnewpkSQ = incentive*pid3bXnewpkSQ
		
		gen newpk4 = newpk - 4
		gen incXnewpk4  		 = incentive*newpk4
		gen incXpid3bXnewpk4  	 = pid3b*incentive*newpk4
		gen pid3bXnewpk4		 = pid3b*newpk4
				
		gen newpk4SQ = newpk4^2
		gen pid3bXnewpk4SQ 	  = pid3b*newpk4SQ
		gen incXnewpk4SQ 	  = incentive*newpk4SQ
		gen incXpid3bXnewpk4SQ = incentive*pid3bXnewpk4SQ
		
		gen r_bushrefXpid3b	  	= r_bushref*pid3b 
		gen rd1Xr_bushref     	= rd1*r_bushref
		gen rd2Xr_bushref     	= rd2*r_bushref
		gen incXr_bushref     	= incentive*r_bushref
		gen rd1Xr_bushrefXpid3b = rd1*r_bushref*pid3b
		gen rd2Xr_bushrefXpid3b = rd2*r_bushref*pid3b
		gen incXr_bushrefXpid3b = incentive*r_bushref*pid3b
		
	
	* Percentile 
		gllamm pct_dv rd1 rd2 pid3b rd1Xpid3b  rd2Xpid3b seq1 seq2 seq3 seq4, i(caseid)
		reg pct_dv rd1 rd2 pid3b rd1Xpid3b  rd2Xpid3b seq1 seq2 seq3 seq4, cluster (caseid)
		
	* raw
		gllamm raw_dv rd1 rd2 pid3b rd1Xpid3b  rd2Xpid3b seq1 seq2 seq3 seq4, i(caseid)
		reg raw_dv rd1 rd2 pid3b rd1Xpid3b  rd2Xpid3b seq1 seq2 seq3 seq4, cluster (caseid)

	* New Table 1: Model 2
		gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b  seq1 seq2 seq3 seq4, i(caseid) link(ologit)
	
	* New Table 2: Model 5
		gllamm tri_dv rd1 rd2 pid7new  rd1Xpid7new rd2Xpid7new  seq1 seq2 seq3 seq4,  i(caseid) link(ologit)

	
		* Plot Figure
		*********************************
			* Change folder
				cd "H:\PartisanInferencePaper\figs\"
				
				*keep if tri_dv!=.
			* Raw Probabilities
				egen probg0 = mean(tri_dv > 0), by(pid3b rd)
				egen probg1 = mean(tri_dv > 1), by(pid3b rd)
							
			* Pred. Probabilities
				gllapred mprobg0, mu marginal above(0)
				gllapred mprobg1, mu marginal above(1)
						
				gen pr0 = 1 - mprobg0
				gen pr1 = mprobg0 - mprobg1
				
				egen mprobg11 = mean(mprobg1), by(pid3b rd)
				
				label define rdl 0 "Control" 1 "Accuracy Appeal" 2 "Monetary Incentive"	
				label val rd rdl
				
				* Predicted Bar
				twoway  (bar mprobg1 pid3b if pid3b==0,  color("230 120 120") barw(.8)) ///
						(bar mprobg1 pid3b if pid3b==1,  color("120 120 230") barw(.8)), ///
						by(rd, legend(off) note("") cols(3)  bgcolor(white) plotregion(lcolor(none) lwidth(zero) ilcolor(none) style(none) color(white)) graphregion(color(white)))  ///
						yscale(range(.35, .6)) ///
						ylabel(,nogrid) ///
						xscale(range(0, 1.1)) ///
						xlabel(0 "Republican" 1 "Democrat") ///
						xlabel(0 "Republican" 1 "Democrat") ///
						xtitle("Partisan self-identification") ///
						ytitle("Pr(Overestimation)")
						graph export OverPredictByCond08Bar.png, height(1500) replace
	
				* Figure 2 (based off Model 6) 
				* Raw Plus Predicted Point
				twoway  (scatter mprobg11 pid3b if pid3b==0,  color("230 120 120")  msize(2)) ///
						(scatter mprobg11 pid3b if pid3b==1,  color("120 120 230")  msize(2)) ///
						(scatter probg1  pid3b if pid3b==0,  color("230 120 120")  msize(2) msymbol(Oh)) ///
						(scatter probg1  pid3b if pid3b==1,  color("120 120 230")  msize(2) msymbol(Oh)), ///
						by(rd, note("") cols(3)  bgcolor(white) plotregion(lcolor(none) lwidth(zero) ilcolor(none) style(none) color(white)) graphregion(color(white)))  ///
						yscale(range(.35, .6)) ///
						ylabel(,nogrid) ///
						xscale(range(-.1, 1.3)) ///
						legend(pos(3) col(2) order(1 3) lab(1 "Predicted") lab(3 "Raw")) ///
						xlabel(0 "Republican" 1 "Democrat") ///
						xlabel(0 "Republican" 1 "Democrat") ///
						xtitle("Partisan self-identification") ///
						ytitle("Pr(Overestimation)")
						graph export OverPredictByCond08RawPlusPredPt.png, height(1500) replace
	
*  --------- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  --------- *
*  --------- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --------- *
* Knowledge		

	* Table 2	
	* With Item level fixed-effects
		* Table 2: Model 1			
			gllamm tri_dv rd2 rd1 r_bushref pid3b rd2Xpid3b rd1Xpid3b r_bushrefXpid3b rd2Xr_bushref rd1Xr_bushref rd2Xr_bushrefXpid3b rd1Xr_bushrefXpid3b seq1 seq2 seq3 seq4, i(caseid) link(ologit)
			reg pct_dv rd2 rd1 r_bushref pid3b rd2Xpid3b rd1Xpid3b r_bushrefXpid3b rd2Xr_bushref rd1Xr_bushref rd2Xr_bushrefXpid3b rd1Xr_bushrefXpid3b seq1 seq2 seq3 seq4, cluster(caseid)
			ologit tri_dv rd2 rd1 r_bushref pid3b rd2Xpid3b rd1Xpid3b r_bushrefXpid3b rd2Xr_bushref rd1Xr_bushref rd2Xr_bushrefXpid3b rd1Xr_bushrefXpid3b seq1 seq2 seq3 seq4, cluster(caseid)
		
		* Table 2: Model 2
			gllamm tri_dv incentive r_bushref pid3b incXpid3b r_bushrefXpid3b incXr_bushref incXr_bushrefXpid3b seq1 seq2 seq3 seq4, i(caseid) link(ologit)
			reg pct_dv incentive r_bushref pid3b incXpid3b r_bushrefXpid3b incXr_bushref incXr_bushrefXpid3b seq1 seq2 seq3 seq4, cluster(caseid)
		
		* Table 2: Model 3
			drop if newpk <1 & pid3b==0 & rd==0
			reg pct_dv incentive pid3b newpk newpkSQ incXpid3b pid3bXnewpk pid3bXnewpkSQ incXnewpk incXnewpkSQ incXpid3bXnewpk incXpid3bXnewpkSQ seq1 seq2 seq3 seq4, cluster(caseid)
			gllamm tri_dv incentive pid3b newpk newpkSQ incXpid3b pid3bXnewpk pid3bXnewpkSQ incXnewpk incXnewpkSQ incXpid3bXnewpk incXpid3bXnewpkSQ seq1 seq2 seq3 seq4, i(caseid) link(ologit)
			gllamm tri_dv incentive pid3b newpk4 newpk4SQ incXpid3b pid3bXnewpk4 pid3bXnewpk4SQ incXnewpk4 incXnewpk4SQ incXpid3bXnewpk4 incXpid3bXnewpk4SQ seq1 seq2 seq3 seq4, i(caseid) link(ologit)
			
	* Knowledge Figure
	******************************

			* Change folder
				cd "H:\PartisanInferencePaper\figs\"
					
			* Raw Probabilities
				egen probg0 = mean(tri_dv > 0), by(pid3b rd)
				egen probg1 = mean(tri_dv > 1), by(pid3b rd)
								
			* Pred. Probabilities
				gllapred mprobg0, mu marginal above(0)
				gllapred mprobg1, mu marginal above(1)
				
					
				gen pr0 = 1 - mprobg0
				gen pr1 = mprobg0 - mprobg1
					
				label define incentivel 0 "Control" 1 "Incentive"	
				label val incentive incentivel
					
				bysort newpk rd pid3b:  gen ups1 = _n
				egen mprobg11 = mean(mprobg1), by(pid3b pay newpk)
				
		
			* Predicted Lowess
				twoway  (lowess  mprobg11  newpk if pid3b==1 & rd==0, lpattern(dash)  bw(.5) lw(med) lcol("100 100 210") scheme(s1color)) ///
						(line  mprobg11  newpk if pid3b==0 & rd==0, lpattern(solid) lw(med) lcol("210 100 100")) ///
						(lowess  mprobg11  newpk if pid3b==1 & rd==1, lpattern(dash)  bw(.6) lw(thick) lcol("100 100 210")) ///
						(lowess  mprobg11  newpk if pid3b==0 & rd==1, lpattern(solid)  bw(.6) lw(thick) lcol("210 100 100")), ///
						ylabel(.2[.1].7) xlabel(0[2]13) xscale(range(0, 13)) yscale(range(.2, .65))  ///
						ytitle("P(Overestimation)")     xtitle("General Political Knowledge") ///
						legend(cols(2) lab(1 "Control: Dem.") lab(2 "Control: Rep.") lab(3 "Incentive: Dem.") lab(4 "Incentive: Rep.")) 
						
						graph export knowpred.png, height(3000) replace
									
			
			* More Knowledge Figures
			* NOT USED
			* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			* Plot Raw
				* Lowess
					recode tri_dv 0/1=0 2=1, gen(probg1)
					recode tri_dv 0 2=0 1=1, gen(probcor)
					*egen probg1 = mean(tri_dv > 1), by(pid3b incentive newpk)
							
					* Change folder
					cd "H:\PartisanInferencePaper\figs\"
			
						twoway  (lowess  probg1  newpk if pid3b==1 & rd==0, lpattern(solid) lcol("100 100 210") scheme(s1color)) ///
								(lowess  probg1  newpk if pid3b==0 & rd==0, lpattern(solid) lcol("210 100 100")) ///
								(lowess  probg1  newpk if pid3b==1 & rd==1, lpattern(dash) lcol("100 100 210")) ///
								(lowess  probg1  newpk if pid3b==0 & rd==1, lpattern(dash) lcol("210 100 100")), ///
								ylabel(.2[.1].7) xlabel(0[2]13) xscale(range(0, 13)) yscale(range(.2, .65))  ///
								t2title("Control Versus Accuracy Reminder") ytitle("P(Overestimation)") xtitle("General Political Knowledge") ///
								legend(cols(2) lab(1 "Ctrl: Dem.") lab(2 "Ctrl: Rep.") lab(3 "Verbal: Dem.") lab(4 "Verbal: Rep.")) 
								graph export verbalknow.png, height(1500) replace
									
						twoway (lowess  probg1 newpk0_13 if pid3b==1 & rd==0, lpattern(solid) lcol("100 100 210") scheme(s1color)) ///
								(lowess  probg1 newpk0_13 if pid3b==0 & rd==0, lpattern(solid) lcol("210 100 100")) ///
								(lowess probg1 newpk0_13 if pid3b==1 & rd==2, lpattern(dash) lcol("100 100 210")) ///
								(lowess probg1 newpk0_13 if pid3b==0 & rd==2, lpattern(dash) lcol("210 100 100")), ///
								ylabel(.2[.1].7) xlabel(0[2]13) xscale(range(0, 13)) yscale(range(.2, .65))  ///
								t2title("Control Versus Monetary Incentives") ytitle("P(Overestimation)") xtitle("General Political Knowledge") ///
								legend(cols(2) lab(1 "Ctrl: Dem.") lab(2 "Ctrl: Rep.") lab(3 "$: Dem.") lab(4 "$: Rep.")) 
								graph export moneyknow.png, height(1500) replace

						twoway (lowess  probg1 newpk0_13 if pid3b==1 & incentive==0, lpattern(dash) lw(med) lcol("100 100 210") scheme(s1color)) ///
								(lowess  probg1 newpk0_13 if newpk0_13>1 & pid3b==0 & incentive==0, lpattern(solid) lw(med) lcol("210 100 100")) ///
								(lowess probg1 newpk0_13 if pid3b==1 & incentive==1, lpattern(dash) lw(thick) lcol("100 100 210")) ///
								(lowess probg1 newpk0_13 if pid3b==0 & incentive==1, lpattern(solid) lw(thick) lcol("210 100 100")), ///
								ylabel(.2[.1].7) xlabel(0[2]13) xscale(range(0, 13)) yscale(range(.2, .65))  ///
								ytitle("P(Overestimation)") xtitle("General Political Knowledge") ///
								legend(cols(2) lab(1 "Control: Dem.") lab(2 "Control: Rep.") lab(3 "Incentive: Dem.") lab(4 "Incentive: Rep."))
								graph export incentiveknow.png, height(3000) replace
									
						twoway (lowess  probcor newpk0_13 if pid3b==1 & incentive==0, lpattern(dash) lw(med) lcol("100 100 210") scheme(s1color)) ///
								(lowess  probcor newpk0_13 if newpk0_13>1 & pid3b==0 & incentive==0, lpattern(solid) lw(med) lcol("210 100 100")) ///
								(lowess probcor newpk0_13 if pid3b==1 & incentive==1, lpattern(dash) lw(thick) lcol("100 100 210")) ///
								(lowess probcor newpk0_13 if pid3b==0 & incentive==1, lpattern(solid) lw(thick) lcol("210 100 100")), ///
								ylabel(.1[.1].6) xlabel(0[2]13) xscale(range(0, 13)) yscale(range(.1, .55))  ///
								ytitle("P(Correct)") xtitle("General Political Knowledge") ///
								legend(cols(2) lab(1 "Control: Dem.") lab(2 "Control: Rep.") lab(3 "Incentive: Dem.") lab(4 "Incentive: Rep."))
								graph export incentivecorr.png, height(3000) replace
		

*  --------- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  --------- *
*  --------- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --------- *
* BushRef
		
	* Bushref Interact
				use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
				keep if pollid==2008 & (pid_app==1 | pid_app==4)
				drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
				reshape long tri_dv, i(caseid)
				
				gen r_bushrefXpid3b	  	= r_bushref*pid3b 
				gen rd1Xr_bushref     	= rd1*r_bushref
				gen rd2Xr_bushref     	= rd2*r_bushref
				gen rd1Xr_bushrefXpid3b = rd1*r_bushref*pid3b
				gen rd2Xr_bushrefXpid3b = rd2*r_bushref*pid3b
				
				gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b, i(caseid) link(ologit)
				estimates store model1
				
				gllamm tri_dv rd1 rd2 pid3b r_bushref rd1Xpid3b rd2Xpid3b r_bushrefXpid3b rd1Xr_bushref rd2Xr_bushref rd1Xr_bushrefXpid3b rd2Xr_bushrefXpid3b, i(caseid) link(ologit)
				estimates store model2
				
				* Dichotomous
					use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
					keep if pollid==2008 & (pid_app==1 | pid_app==4)
					drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
					reshape long tri_dv, i(caseid)
					
					recode rd 2 3 =1, gen(incentive)
					gen incXpid3b = incentive*pid3b
					gen bushrefXpid3b = r_bushref*pid3b
					gen bushrefXinc = incentive*r_bushref
					gen bushrefXincXpid3b = incentive*r_bushref*pid3b
					
					gllamm tri_dv incentive pid3b incXpid3b, i(caseid) link(ologit)
					estimates store model1
					
					gllamm tri_dv incentive pid3b r_bushref bushrefXpid3b bushrefXinc incXpid3b bushrefXincXpid3b, i(caseid) link(ologit)
					estimates store model2
					
					lrtest model1 model2
				
			* by r_bushref==1
			*****************************************
				* Load data, subset, and reshape
				use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
				keep if pollid==2008 & (pid_app==1 | pid_app==4)
				drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
				reshape long tri_dv, i(caseid)
			
					keep if r_bushref==1
			
			* pg. 12
				gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7 r_PIDloc, i(caseid) link(ologit)
				
				
				* Graph Both Verbal and Pay Bushref 1
				********************************
				* Change folder
					cd "H:\PartisanInferencePaper\figs\"
		
					* Run gllamm
						*gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7, i(caseid) link(ologit)
						gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b seq1 seq2 seq3 seq4, i(caseid) link(ologit)
					
					* Raw Probabilities
						egen probg0 = mean(tri_dv > 0), by(pid3b rd)
						egen probg1 = mean(tri_dv > 1), by(pid3b rd)
						
					* Pred. Probabilities
						gllapred mprobg0, mu marginal above(0)
						gllapred mprobg1, mu marginal above(1)
						
						egen mprobg11 = mean(mprobg1), by(pid3b pay)
						
						* sum mprobg1 if pid3b==1 & rd1==0 & rd2==0
						* Control: PID3b==1: .58; PID3b==0: .35
						* Verbal: PID3b==1: .54; PID3b==0: .36
						* Mon.: PID3b==1: .54; PID3b==0: .41

						gen pr0 = 1 - mprobg0
						gen pr1 = mprobg0 - mprobg1
				
						label define rdl 0 "Control" 1 "Accuracy Appeal" 2 "Monetary Incentive"	
						label val rd rdl
					
					* Raw Bar
					twoway  (bar probg1 pid3b if pid3b==0,  color("230 120 120") barw(.8)) ///
						(bar probg1 pid3b if pid3b==1, color("120 120 230") barw(.8)), ///
						by(rd, legend(off) note("") cols(3)    bgcolor(white) plotregion(lcolor(none) lwidth(zero) ilcolor(none) style(none) color(white)) graphregion(color(white)))  ///
						yscale(range(.35, .6)) ///
						ylabel(,nogrid) ///
						xscale(range(0, 1.1)) ///
						ylab(.25(0.1).65, nogrid) ///
						xlabel(0 "Republican" 1 "Democrat") ///
						xlabel(0 "Republican" 1 "Democrat") ///
						xtitle("Partisan self-identification") ///
						ytitle("Pr(Overestimation)")
						graph export OverPredictByCond08Bushref1RawBar.png, height(1500) replace
						
					* Bar
					twoway (bar mprobg1 pid3b if pid3b==0,  color("230 120 120") barw(.8)) ///
							(bar mprobg1 pid3b if pid3b==1, color("120 120 230") barw(.8)), ///
							by(rd, legend(off) note("") cols(3)   bgcolor(white) plotregion(lcolor(none) lwidth(zero) ilcolor(none) style(none) color(white)) graphregion(color(white)))  ///
							yscale(range(.35, .6)) ///
							ylabel(,nogrid) ///
							xscale(range(0, 1.1)) ///
							xlabel(0 "Republican" 1 "Democrat") ///
							xlabel(0 "Republican" 1 "Democrat") ///
							xtitle("Partisan self-identification") ///
							ytitle("Pr(Overestimation)")
							graph export OverPredictByCond08Bushref1Bar.png, height(1500) replace
						
						
					
					* Two conditions
						* Load data, subset, and reshape
						use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
						keep if pollid==2008 & (pid_app==1 | pid_app==4)
						drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
						reshape long tri_dv, i(caseid)
						
						* for item level r.e.
						gen seq = mod(_n-1,5) + 1
	
						* for item level f.e
							gen seq1=1 if seq==1
							replace seq1=0 if seq~=1
								
							gen seq2=1 if seq==2
							replace seq2=0 if seq~=2
								
							gen seq3=1 if seq==3
							replace seq3=0 if seq~=3
								
							gen seq4=1 if seq==4
							replace seq4=0 if seq~=4
	
	
	
						keep if r_bushref==1
						
						recode rd 2 3 =1, gen(incentive)
						gen incXpid3b = incentive*pid3b
						gllamm tri_dv incentive pid3b incXpid3b seq1 seq2 seq3 seq4, i(caseid) link(ologit)
						
						* Raw Probabilities
						egen probg0 = mean(tri_dv > 0), by(pid3b incentive)
						egen probg1 = mean(tri_dv > 1), by(pid3b incentive)
					
						* Pred. Probabilities
						gllapred mprobg0, mu marginal above(0)
						gllapred mprobg1, mu marginal above(1)
						
						egen mprobg11 = mean(mprobg1), by(pid3b pay)
						
						* sum mprobg1 if pid3b==1 & incentive==0
						* Control: PID3b==1: .58; PID3b==0: .36
						* Incentive: PID3b==1: .54; PID3b==0: .38

						
						gen pr0 = 1 - mprobg0
						gen pr1 = mprobg0 - mprobg1
						
						label define incentivel 0 "Control" 1 "Incentive"	
						label val incentive incentivel
						
						* Predicted Bar
						twoway  (bar mprobg1 pid3b if pid3b==0,  color("230 120 120") barw(.8)) ///
							(bar mprobg1 pid3b if pid3b==1, color("120 120 230") barw(.8)), ///
							by(incentive, legend(off) note("") cols(3)  bgcolor(white) plotregion(lcolor(none) lwidth(zero) ilcolor(none) style(none) color(white)) graphregion(color(white)))  ///
							yscale(range(.35, .6)) ///
							ylabel(,nogrid) ///
							xscale(range(0, 1.1)) ///
							xlabel(0 "Republican" 1 "Democrat") ///
							xlabel(0 "Republican" 1 "Democrat") ///
							xtitle("Partisan self-identification") ///
							ytitle("Pr(Overestimation)")
							graph export OverPredictBy2Cond08Bushref1Bar.png, height(1500) replace
				
				
						* Raw Plus Predicted Point
						twoway  (scatter mprobg11 pid3b if pid3b==0,  color("230 120 120")  msize(2)) ///
						(scatter mprobg11 pid3b if pid3b==1,  color("120 120 230")  msize(2)) ///
						(scatter probg1  pid3b if pid3b==0,  color("230 120 120")  msize(2) msymbol(Oh)) ///
						(scatter probg1  pid3b if pid3b==1,  color("120 120 230")  msize(2) msymbol(Oh)), ///
						by(incentive, note("") cols(3)  bgcolor(white) plotregion(lcolor(none) lwidth(zero) ilcolor(none) style(none) color(white)) graphregion(color(white)))  ///
						yscale(range(.35, .6)) ///
						ylabel(,nogrid) ///
						xscale(range(-.1, 1.3)) ///
						legend(pos(3) col(2) order(1 3) lab(1 "Predicted") lab(3 "Raw")) ///
						xlabel(0 "Republican" 1 "Democrat") ///
						xlabel(0 "Republican" 1 "Democrat") ///
						xtitle("Partisan self-identification") ///
						ytitle("Pr(Overestimation)")
						graph export OverPredictBy2Cond08Bushref1RawPlusPredPt.png, height(1500) replace
						
						*** Ignore for now
						***************************
						* Raw Probs. also plotted (not happy with poor fit of the model)						
						twoway(line mprobg1 pid7 if rd1==0 & rd2==0, sort lpatt(solid)) ///
							 (line mprobg1 pid7 if rd1==1, sort lpatt(dot)) ///
							 (line mprobg1 pid7 if rd2==1, sort lpatt(dash)), ///
							 legend(order(1 "Control" 2 "Verbal" 3 "Pay") size(medium) rows(1)) ///
							 xlabel(1 "Str. R" 7 "Str. D") ///
							 xtitle("Partisan self-identification") ///
							 ytitle("Probability of over-estimation") ///
							 title("2008 Bush Reference Only: Verbal, Pay, and Control") ///
							 bgcolor(white) plotregion(fcolor(white)) graphregion(fcolor(white))
							 graph export OverPredictByCond08Bushref1.png, height(1500) replace
							 
						* Raw Probs. also plotted (not happy with poor fit of the model)
						twoway(line pr0 pid7 if rd1==0 & rd2==0, sort lpatt(solid)) ///
							  (line  pr0 pid7 if rd1==1, sort lpatt(dot)) ///
							  (line  pr0 pid7 if rd2==1, sort lpatt(dash)), ///
							  legend(order(1 "Control" 2 "Verbal" 3 "Pay")  size(medium) rows(1)) ///
							  xlabel(1 "Str. R" 7 "Str. D") ///
							  xtitle("Partisan self-identification") ///
							  ytitle("Probability of under-estimation") ///
							  title("2008 Bush Reference Only: Verbal, Pay, and Control") ///
							  bgcolor(white) plotregion(fcolor(white)) graphregion(fcolor(white))
							  graph export UnderPredictByCond08Bushref1.png, height(1500) replace
			
			* by r_bushref==0
			******************************
				use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
				keep if pollid==2008 & (pid_app==1 | pid_app==4)
				drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
				reshape long tri_dv, i(caseid)
				
				* for item level r.e.
						gen seq = mod(_n-1,5) + 1
	
						* for item level f.e
							gen seq1=1 if seq==1
							replace seq1=0 if seq~=1
								
							gen seq2=1 if seq==2
							replace seq2=0 if seq~=2
								
							gen seq3=1 if seq==3
							replace seq3=0 if seq~=3
								
							gen seq4=1 if seq==4
							replace seq4=0 if seq~=4
	
	
				keep if r_bushref==0
				
			* pg. 13
				gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7 r_PIDloc, i(caseid) link(ologit)
			
			* Change folder
				cd "H:\PartisanInferencePaper\figs\"
	
				* Run gllamm
					*gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7, i(caseid) link(ologit)
					gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b, i(caseid) link(ologit)
				
				* Raw Probabilities
					egen probg0 = mean(tri_dv > 0), by(pid3b rd)
					egen probg1 = mean(tri_dv > 1), by(pid3b rd)
					
					tab probg1 pid3b if pid3b==0
					tab probg1 pid3b if pid3b==1
				
					* probg
					* sum probg1 if pid3b==1 & rd1==0 & rd2==0
					* Control: PID3b==1: .52; PID3b==0: .36; Diff. .16
					* Verbal: PID3b==1: .53; PID3b==0: .45; Diff. .08
					* Mon.: PID3b==1: .50; PID3b==0: .45; Diff. .06
					
				* Pred. Probabilities (model fits the probabilities very well)
					gllapred mprobg0, mu marginal above(0)
					gllapred mprobg1, mu marginal above(1)
				
					egen mprobg11 = mean(mprobg1), by(pid3b pay)
					
					gen pr0 = 1 - mprobg0
					gen pr1 = mprobg0 - mprobg1
			
					label define rdl 0 "Control" 1 "Accuracy Appeal" 2 "Monetary Incentive"	
					label val rd rdl
					
					* sum mprobg1 if pid3b==1 & rd1==0 & rd2==0
					* Control: PID3b==1: .52; PID3b==0: .36
					* Verbal: PID3b==1: .52; PID3b==0: .46
					* Mon.: PID3b==1: .50; PID3b==0: .45
					
				* Raw Bar
				twoway  (bar probg1 pid3b if pid3b==0,  color("230 120 120") barw(.8)) ///
					(bar probg1 pid3b if pid3b==1, color("120 120 230") barw(.8)), ///
					by(rd, legend(off) note("") cols(3)   bgcolor(white) plotregion(lcolor(none) lwidth(zero) ilcolor(none) style(none) color(white)) graphregion(color(white)))  ///
					yscale(range(.35, .6)) ///
					ylabel(,nogrid) ///
					xscale(range(0, 1.1)) ///
					xlabel(0 "Republican" 1 "Democrat") ///
					xlabel(0 "Republican" 1 "Democrat") ///
					xtitle("Partisan self-identification") ///
					ytitle("Pr(Overestimation)")
					graph export OverPredictByCond08Bushref0RawBar.png, height(1500) replace
					
				
				* Bar
				twoway  (bar mprobg1 pid3b if pid3b==0,  color("230 120 120") barw(.8)) ///
					(bar mprobg1 pid3b if pid3b==1, color("120 120 230") barw(.8)), ///
					by(rd, legend(off) note("") cols(3)   bgcolor(white) plotregion(lcolor(none) lwidth(zero) ilcolor(none) style(none) color(white)) graphregion(color(white)))  ///
					yscale(range(.35, .6)) ///
					ylabel(,nogrid) ///
					xscale(range(0, 1.1)) ///
					xlabel(0 "Republican" 1 "Democrat") ///
					xlabel(0 "Republican" 1 "Democrat") ///
					xtitle("Partisan self-identification") ///
					ytitle("Pr(Overestimation)")  graphregion(color(white)) bgcolor(white)
					graph export OverPredictByCond08Bushref0Bar.png, height(1500) replace
					

				* Two conditions
					* Load data, subset, and reshape
						use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
						keep if pollid==2008 & (pid_app==1 | pid_app==4)
						drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
						reshape long tri_dv, i(caseid)
						
						* for item level r.e.
						gen seq = mod(_n-1,5) + 1
	
						* for item level f.e
							gen seq1=1 if seq==1
							replace seq1=0 if seq~=1
								
							gen seq2=1 if seq==2
							replace seq2=0 if seq~=2
								
							gen seq3=1 if seq==3
							replace seq3=0 if seq~=3
								
							gen seq4=1 if seq==4
							replace seq4=0 if seq~=4
	
	
	
						keep if r_bushref==0
						
						recode rd 2 3 =1, gen(incentive)
						gen incXpid3b = incentive*pid3b
						gllamm tri_dv incentive pid3b incXpid3b seq1 seq2 seq3 seq4, i(caseid) link(ologit)
						
						* Raw Probabilities
						egen probg0 = mean(tri_dv > 0), by(pid3b incentive)
						egen probg1 = mean(tri_dv > 1), by(pid3b incentive)
					
						* Pred. Probabilities
						gllapred mprobg0, mu marginal above(0)
						gllapred mprobg1, mu marginal above(1)
						
						egen mprobg11 = mean(mprobg1), by(pid3b pay)
						* sum mprobg1 if pid3b==1 & incentive==0
						* Control: PID3b==1: .58; PID3b==0: .36
						* Incentive: PID3b==1: .54; PID3b==0: .38
						
						gen pr0 = 1 - mprobg0
						gen pr1 = mprobg0 - mprobg1
						
						label define incentivel 0 "Control" 1 "Incentive"	
						label val incentive incentivel
						
						* Predicted Bar
						twoway  (bar mprobg1 pid3b if pid3b==0,  color("230 120 120") barw(.8)) ///
							(bar mprobg1 pid3b if pid3b==1, color("120 120 230") barw(.8)), ///
							by(incentive, legend(off) note("") cols(3)  bgcolor(white) plotregion(lcolor(none) lwidth(zero) ilcolor(none) style(none) color(white)) graphregion(color(white)))  ///
							yscale(range(.35, .6)) ///
							ylabel(,nogrid) ///
							xscale(range(0, 1.1)) ///
							xlabel(0 "Republican" 1 "Democrat") ///
							xlabel(0 "Republican" 1 "Democrat") ///
							xtitle("Partisan self-identification") ///
							ytitle("Pr(Overestimation)")
							graph export OverPredictBy2Cond08Bushref0Bar.png, height(1500) replace
							
						* Raw Plus Predicted Point
						twoway  (scatter mprobg11 pid3b if pid3b==0,  color("230 120 120")  msize(2)) ///
						(scatter mprobg11 pid3b if pid3b==1,  color("120 120 230")  msize(2)) ///
						(scatter probg1  pid3b if pid3b==0,  color("230 120 120")  msize(2) msymbol(Oh)) ///
						(scatter probg1  pid3b if pid3b==1,  color("120 120 230")  msize(2) msymbol(Oh)), ///
						by(incentive, note("") cols(3)  bgcolor(white) plotregion(lcolor(none) lwidth(zero) ilcolor(none) style(none) color(white)) graphregion(color(white)))  ///
						yscale(range(.35, .6)) ///
						ylabel(,nogrid) ///
						xscale(range(-.1, 1.3)) ///
						legend(pos(3) col(2) order(1 3) lab(1 "Predicted") lab(3 "Raw")) ///
						xlabel(0 "Republican" 1 "Democrat") ///
						xlabel(0 "Republican" 1 "Democrat") ///
						xtitle("Partisan self-identification") ///
						ytitle("Pr(Overestimation)")
						graph export OverPredictBy2Cond08Bushref0RawPlusPredPt.png, height(1500) replace
*  --------- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  --------- *
*  --------- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --------- *
* Robustness Checks/Appendix	

* Dealing with time
		use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
		keep if pollid==2008 & (pid_app==1 | pid_app==4)
		drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
		reshape long tri_dv t_l, i(caseid)
		
		*gen tri_cor = tri_dv==1
		*xtmixed tri_cor rd1 rd2 t_l rd1#c.t_l rd2#c.t_l || caseid:
		
		* for item level r.e.
		gen seq = mod(_n-1,5) + 1
	
	* for item level f.e
		gen seq1=1 if seq==1
		replace seq1=0 if seq~=1
			
		gen seq2=1 if seq==2
		replace seq2=0 if seq~=2
			
		gen seq3=1 if seq==3
		replace seq3=0 if seq~=3
			
		gen seq4=1 if seq==4
		replace seq4=0 if seq~=4
	
	* Some recodes
		gen rd1Xpid7new = rd1*pid7new
		gen rd2Xpid7new = rd2*pid7new
		
		recode rd 2 3 =1, gen(incentive)
		gen incXpid3b = incentive*pid3b
		
		gen incXnewpk  		 = incentive*newpk
		gen incXpid3bXnewpk  = pid3b*incentive*newpk
		gen pid3bXnewpk		 = pid3b*newpk
						
		gen newpkSQ = newpk^2
		gen pid3bXnewpkSQ 	  = pid3b*newpkSQ
		gen incXnewpkSQ 	  = incentive*newpkSQ
		gen incXpid3bXnewpkSQ = incentive*pid3bXnewpkSQ
										
		gen r_bushrefXpid3b	  	= r_bushref*pid3b 
		gen rd1Xr_bushref     	= rd1*r_bushref
		gen rd2Xr_bushref     	= rd2*r_bushref
		gen incXr_bushref     	= incentive*r_bushref
		gen rd1Xr_bushrefXpid3b = rd1*r_bushref*pid3b
		gen rd2Xr_bushrefXpid3b = rd2*r_bushref*pid3b
		gen incXr_bushrefXpid3b = incentive*r_bushref*pid3b
		
		* Table B1: With timers
			*keep if t_l < 90
			*gllamm tri_dv rd2 rd1 pid3b rd2Xpid3b rd1Xpid3b seq1 seq2 seq3 seq4, i(caseid) link(ologit)
			
			keep if t_l < 60
			gllamm tri_dv rd2 rd1 pid3b rd2Xpid3b rd1Xpid3b seq1 seq2 seq3 seq4, i(caseid) link(ologit)
			
			keep if t_l < 45
			gllamm tri_dv rd2 rd1 pid3b rd2Xpid3b rd1Xpid3b seq1 seq2 seq3 seq4, i(caseid) link(ologit)
		
			keep if t_l < 40
			gllamm tri_dv rd2 rd1 pid3b rd2Xpid3b rd1Xpid3b seq1 seq2 seq3 seq4, i(caseid) link(ologit)
		
			keep if t_l < 30
			gllamm tri_dv rd2 rd1 pid3b rd2Xpid3b rd1Xpid3b seq1 seq2 seq3 seq4, i(caseid) link(ologit)
		
		* Total time (3 minutes), 90 per q
			use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
			keep if pollid==2008 & (pid_app==1 | pid_app==4)  
			drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
			reshape long tri_dv t_l, i(caseid)
			keep if t_l < 90 & tot_time < 300
	
			gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b, i(caseid) link(ologit)
		
			keep if t_l < 60 & tot_time < 225
	
			gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b, i(caseid) link(ologit)
			
			keep if t_l < 45 & tot_time < 150
	
			gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b, i(caseid) link(ologit)
			
		* Hi-speed/No hi-speed interact
			gen pid3bXnohispeed = pid3b*nohispeed
			gen rd1Xnohispeed	= rd1*nohispeed
			gen rd2Xnohispeed	= rd2*nohispeed
			gen rd1Xpid3bXnohispeed = pid3b*rd1*nohispeed
			gen rd2Xpid3bXnohispeed = pid3b*rd2*nohispeed
			
			keep if nohispeed~=.
			gllamm tri_dv nohispeed rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b, i(caseid) link(ologit)
			estimates store model1
			
			gllamm tri_dv rd1 rd2 nohispeed pid3b pid3bXnohispeed rd1Xnohispeed rd2Xnohispeed rd1Xpid3b rd2Xpid3b rd1Xpid3bXnohispeed rd2Xpid3bXnohispeed, i(caseid) link(ologit)
			estimates store model2
			
			lrtest model1 model2 
			
			* No hispeed
				use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
				keep if pollid==2008 & (pid_app==1 | pid_app==4) & nohispeed==1
				drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
				reshape long tri_dv t_l, i(caseid)
		
				gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b, i(caseid) link(ologit)
				
			* hispeed
				use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
				keep if pollid==2008 & (pid_app==1 | pid_app==4) & nohispeed==0
				drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
				reshape long tri_dv t_l, i(caseid)
		
				gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b, i(caseid) link(ologit)
			
		* Alone/Not Alone
			use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
			keep if pollid==2008 & (pid_app==1 | pid_app==4)
			drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
			reshape long tri_dv t_l, i(caseid)
				
			gen pid3bXalone = pid3b*alone
			gen rd1Xalone	= rd1*alone
			gen rd2Xalone	= rd2*alone
			gen rd1Xpid3bXalone = pid3b*rd1*alone
			gen rd2Xpid3bXalone = pid3b*rd2*alone
			
			keep if alone~=.
			gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b, i(caseid) link(ologit)
			estimates store model1
			
			gllamm tri_dv rd1 rd2 alone pid3b pid3bXalone rd1Xalone rd2Xalone rd1Xpid3b rd2Xpid3b rd1Xpid3bXalone rd2Xpid3bXalone, i(caseid) link(ologit)
			estimates store model2
			
			lrtest model1 model2 
			
			* Alone
				use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
				keep if pollid==2008 & (pid_app==1 | pid_app==4) & alone==1
				drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
				reshape long tri_dv t_l, i(caseid)
		
				gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b, i(caseid) link(ologit)
				
			* Not Alone
				use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
				keep if pollid==2008 & (pid_app==1 | pid_app==4) & alone==0
				drop tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10
				reshape long tri_dv t_l, i(caseid)
		
				gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b, i(caseid) link(ologit)

*  --------- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  --------- *
*  --------- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --------- *

* Mlogit and item level

		* Appendix C: mlogit
			gllamm tri_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4, i(caseid) link(mlogit) basecategory(1)
			gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b, i(caseid) link(mlogit) basecategory(1)
			gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b  rd2Xpid3b,  i(caseid) link(mlogit)		
		
		* Exploring item level
			* Using fixed effects via ologit
				ologit tri_dv pay pid3b payXpid3b i.seq, cluster(caseid)
			
			* with item level random effects only 			
				gllamm tri_dv pay pid3b payXpid3b, i(seq) link(ologit)
			
			* with item level fixed effects
				gllamm tri_dv pay pid7 payXpid7 seq1 seq2 seq3 seq4, i(caseid) link(ologit)
