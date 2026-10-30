** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **
**									    	**								
**  Partisan Inference Analyses			
**  Last Edited: 4/18/2013 by GS		
**  Analyses: Hierarchical Joint
**											
** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **
 
* Set Library Location for finding survwgt/gllamm (Leave it for GS)
	sysdir set PLUS "\\files\dept\WWS\Research\MPRIOR\stata\"
	* ssc install gllamm

* Estimation Notes
********************
	* Some gllamm tips
		* to do adaptive quadrature: use option adapt. specify # of quadrature points using nip()
		* for exponentiated coefficients: after the comma, add the word 'eform'; it also gets you 95% CI
		* to store estimates of a model: after the running the model, enter the following command: estimates store model1
		* to restore estimates: estimates restore model1
		* to compare two models: lrtest model1 model2
		
	* 2008 subset
		*keep if pid_app==1 | pid_app==4 | pid_app==.

	* 2004 subset
		*keep if time==0 & pid7 ~= 4  
		
* Using all DVS including Poor
************************************
	use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
	reshape long tri_dv pct_dv raw_dv t_l, i(caseid)
		
	
	* Fixing Bushref (as KN 2004 debt bushref is 1)
		gen nbushref = r_bushref
		replace nbushref = 1 if mod(_n+2, 10) == 0
		replace nbushref = 0 if _n < 8
		replace nbushref = 0 if _n == 9 | _n == 10
	
	* Create one new
		gen payXpid7new = pay*pid7new
		
	* For item level effects
		gen seq = mod(_n-1,10) + 1
	
	* for item level f.e
		gen seq1=1 if seq==1
		replace seq1=0 if seq~=1
					
		gen seq2=1 if seq==2
		replace seq2=0 if seq~=2
					
		gen seq3=1 if seq==3
		replace seq3=0 if seq~=3
					
		gen seq4=1 if seq==4
		replace seq4=0 if seq~=4
		
		gen seq5=1 if seq==5
		replace seq5=0 if seq~=5
		
		gen seq6=1 if seq==6
		replace seq6=0 if seq~=6
		
		gen seq7=1 if seq==7
		replace seq7=0 if seq~=7
					
		gen seq8=1 if seq==8
		replace seq8=0 if seq~=8
					
		gen seq9=1 if seq==9
		replace seq9=0 if seq~=9
								
					
	* Subset
		keep if (time ==0 | time ==.) & pid7~=4 & (pid_app==1 | pid_app==4 | pid_app==.) & (rd1~=1)
		keep if tri_dv~=. & pid3b~=. & pay~=.
		
	**************************************
		* New Table 1/2 (col 1)
			* with item level fixed effects (pollid not really needed, var going to be zero)
				gllamm tri_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, i(caseid) link(ologit)
				*gllamm tri_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, i(caseid pollid) link(ologit)		
				
			* New Table 2 (col 7)
				gllamm tri_dv pay pid7new payXpid7new seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, i(caseid) link(ologit)
				
				* lrtest and wald for equality 
					gen incXstrpid = pay*strpid
					gen incXpid3bXstrpid = pay*pid3b*strpid
					gen incXweakpid = pay*weakpid
					gen incXpid3bXweakpid = pay*pid3b*weakpid
					gen pid3bXstrpid = pid3b*strpid
					
						
					gllamm tri_dv pay stdem strep wkdem wkrep lnrep payXpid3b  seq1 seq2 seq3 seq4, i(caseid) link(ologit)
					estimates store m1
					gllamm tri_dv pay stdem strep wkdem wkrep lnrep payXstdem payXstrep payXwkdem payXwkrep payXlnrep seq1 seq2 seq3 seq4, i(caseid) link(ologit)
					estimates store m2
					lrtest m1 m2
		
				
					* replication of #s in the paper
					*gllamm tri_dv pay pid3b payXpid3b, i(caseid) link(ologit)
					*estimates store m1
					*gllamm tri_dv pay strpid weakpid pid3bXstrpid incXstrpid incXweakpid incXpid3bXstrpid incXpid3bXweakpid, i(caseid) link(ologit)
					*estimates store m2
					*lrtest m1 m2
		
		* Percentile 
			gllamm pct_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, i(caseid)
			reg pct_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, cluster (caseid)
		
		* Raw
			gllamm raw_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, i(caseid)
			reg raw_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, cluster (caseid)
		
		* No Item level fe
			gllamm tri_dv pay pid7 payXpid7, i(caseid pollid) link(ologit) adapt
			gllamm tri_dv pay pid3b payXpid3b, i(caseid pollid) link(ologit) adapt
			
			* Graphing it
			* Change folder
				cd "H:\PartisanInferencePaper\figs\"
				
				* Raw Probabilities
					egen probg0 = mean(tri_dv > 0), by(pid3b pay)
					egen probg1 = mean(tri_dv > 1), by(pid3b pay)
					
				* Pred. Probabilities
					gllapred mprobg0, mu marginal above(0)
					gllapred mprobg1, mu marginal above(1)
					
					egen mprobg11 = mean(mprobg1), by(pid3b pay)
					
					tab mprobg11 if pid3b==1 & rd==0
					tab mprobg11 if pid3b==0 & rd==0
					*.15
					tab mprobg11 if pid3b==1 & pay==1
					tab mprobg11 if pid3b==0 & pay==1
					*.07
					
					label define payl 0 "Control" 1 "Monetary Incentive"	
					label val pay payl
				
					* Predicted Point Plus Text
					twoway  (scatter mprobg11  pid3b if pid3b==0,  color("230 120 120")  msize(2)) ///
							(scatter mprobg11  pid3b if pid3b==1,  color("120 120 230")  msize(2)), ///
							by(pay, note("")  cols(2)  legend(off) bgcolor(white) plotregion(lcolor(none) lwidth(zero) ilcolor(none) style(none) color(white)) graphregion(color(white))) /// 
							yscale(range(.35, .6)) ///
							ylabel(,nogrid) ///
							xscale(range(-.1, 1.3)) ///
							xlabel(0 "Republican" 1 "Democrat") ///
							xlabel(0 "Republican" 1 "Democrat") ///
							xtitle("Partisan self-identification") ///
							ytitle("Pr(Overestimation)") ///
							text(.49 .8 "Partisan Gap = ",    `format'  placement(9) )
							
							graph export OverPredictBy2CondJointPredPtTxt.png, height(1500) replace
						
										
		* Appendix C: mlogit
		* some identification issues - see the condition #
			gllamm tri_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, i(caseid) link(mlogit)
			mlogit tri_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, base(0) cluster(caseid)
			
		* Exploring item level
		* We are already smoothing over items about equally etc. 
		* In fact it doesn't net us anything.
			* Using fixed effects via ologit
				ologit tri_dv pay pid3b payXpid3b i.seq, cluster(caseid)
			
			* with item level random effects only 			
				gllamm tri_dv pay pid3b payXpid3b, i(seq) link(ologit)
				gllamm tri_dv pay pid3b payXpid3b, i(seq pollid) link(ologit)
				*gllamm tri_dv pay pid3b payXpid3b pollid, i(seq caseid) link(ologit)
			
			* Table 1 (col 1)
			* with item level fixed effects (pollid not really needed, var going to be zero)
				gllamm tri_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, i(caseid) link(ologit)
				*gllamm tri_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, i(caseid pollid) link(ologit)
			* Table 1 (col 2)
				gllamm tri_dv pay pid7new payXpid7new seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, i(caseid) link(ologit)
		
		* Exploring time
			* Hi-speed/No hi-speed interact
				use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
				reshape long tri_dv pct_dv raw_dv t_l, i(caseid)
				* For item level effects
					gen seq = mod(_n-1,10) + 1
				
				* for item level f.e
					gen seq1=1 if seq==1
					replace seq1=0 if seq~=1
								
					gen seq2=1 if seq==2
					replace seq2=0 if seq~=2
								
					gen seq3=1 if seq==3
					replace seq3=0 if seq~=3
								
					gen seq4=1 if seq==4
					replace seq4=0 if seq~=4
					
					gen seq5=1 if seq==5
					replace seq5=0 if seq~=5
					
					gen seq6=1 if seq==6
					replace seq6=0 if seq~=6
					
					gen seq7=1 if seq==7
					replace seq7=0 if seq~=7
								
					gen seq8=1 if seq==8
					replace seq8=0 if seq~=8
								
					gen seq9=1 if seq==9
					replace seq9=0 if seq~=9
											
					
			* Subset
				keep if (time ==0 | time ==.) & pid7~=4 & (pid_app==1 | pid_app==4 | pid_app==.) & (rd1~=1)
				keep if tri_dv~=. & pid3b~=. & pay~=.
				
				gen pid3bXnohispeed = pid3b*nohispeed
				gen payXnohispeed	= pay*nohispeed
				gen payXpid3bXnohispeed = pid3b*pay*nohispeed
				
				keep if nohispeed~=.
				gllamm tri_dv pay nohispeed pid3b payXpid3b seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, i(caseid) link(ologit)
				estimates store model1
				
				gllamm tri_dv pay nohispeed pid3b pid3bXnohispeed payXnohispeed payXpid3b payXpid3bXnohispeed seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9, i(caseid) link(ologit)
				estimates store model2
				
				lrtest model1 model2 
				
				* no hispeed
				use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
				keep if (time ==0 | time ==.) & pid7~=4 & (pid_app==1 | pid_app==4 | pid_app==.) & (rd1~=1) & nohispeed==1
				reshape long tri_dv t_l, i(caseid)
				gllamm tri_dv pay pid3b payXpid3b, i(caseid pollid) link(ologit) 
				
				* hispeed
				use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
				keep if (time ==0 | time ==.) & pid7~=4 & (pid_app==1 | pid_app==4 | pid_app==.) & (rd1~=1) & nohispeed==0
				reshape long tri_dv t_l, i(caseid)
				gllamm tri_dv pay pid3b payXpid3b, i(caseid pollid) link(ologit) 
			
			* Alone/Not Alone
				use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
				keep if (time ==0 | time ==.) & pid7~=4 & (pid_app==1 | pid_app==4 | pid_app==.) & (rd1~=1)
				reshape long tri_dv t_l, i(caseid pollid)
				
				gen pid3bXalone = pid3b*alone
				gen payXalone	= pay*alone
				gen payXpid3bXalone= pid3b*pay*alone
				
				keep if nohispeed~=.
				gllamm tri_dv pay pid3b payXpid3b, i(caseid pollid) link(ologit)
				estimates store model1
				
				gllamm tri_dv pay alone pid3b pid3bXalone payXalone payXpid3b payXpid3bXalone, i(caseid pollid) link(ologit)
				estimates store model2
				
				lrtest model1 model2 
			
				* alone
					use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
					keep if (time ==0 | time ==.) & pid7~=4 & (pid_app==1 | pid_app==4 | pid_app==.) & (rd1~=1) & alone==1
					reshape long tri_dv t_l, i(caseid)
					gllamm tri_dv pay pid3b payXpid3b, i(caseid pollid) link(ologit) 
					
				* not alone
					use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
					keep if (time ==0 | time ==.) & pid7~=4 & (pid_app==1 | pid_app==4 | pid_app==.) & (rd1~=1) & alone==0
					reshape long tri_dv t_l, i(caseid)
					gllamm tri_dv pay pid3b payXpid3b, i(caseid pollid) link(ologit) 
				
		
