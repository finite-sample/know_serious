** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **
**									    	**
**  KN 2008								
**  Partisan Inference Analyses			
**  Last Edited: 2/19/2013 by GS		
**  Analyses: Tri, Regress, Percentile Regress, 
**			  Ord, Robust, Quantile, SUR
**			  Hierarchical
**											
**	Analyses in APSA paper
** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **

* Ordinal being removed as 
* closed-ended: trichot is kosher and it performs at least as well as ordered
* open-ended: ordinal is a bit hairy for 'continuous' variables
 
* Set Library Location for finding survwgt (Leave it for GS)
	sysdir set PLUS "\\files\dept\WWS\Research\MPRIOR\stata\"
	
	* ssc install mvprobit
	* ssc install gllamm
	* ssc install bioprobit
	
* Load data
	use "h:\PartisanInferencePaper\data\KN2008.merged.recoded.dta", clear			

* for Quantile Regression
	
		gen rdm			 = rd
		replace rdm      = . if rd==1
		
		gen rd1			 = 0
		replace rd1      = 1 if rd==1

		gen rd2			 = 0
		replace rd2      = 1 if rd==2

		gen rd1Xpid7     = c.rd*pid7new if c.rd==1
		replace rd1Xpid7 = 0 if c.rd~=1
		
		gen rd2Xpid7     = pid7new if c.rd==2
		replace rd2Xpid7 = 0 if c.rd~=2
		
		gen rd1Xr_bushref     = c.rd*r_bushref if c.rd==1
		replace rd1Xr_bushref = 0 if c.rd~=1
		
		gen rd2Xr_bushref     = r_bushref if c.rd==2
		replace rd2Xr_bushref = 0 if c.rd~=2
		
		gen rd1Xr_PIDloc     = c.rd*r_PIDloc if c.rd==1
		replace rd1Xr_PIDloc = 0 if c.rd~=1
		
		gen rd2Xr_PIDloc     = r_PIDloc if c.rd==2
		replace rd2Xr_PIDloc = 0 if c.rd~=2
		
		set seed 1210
		
*** Analyses
*** People on average/median over-estimate
		sum dis_unempl dis_health dis_gas dis_debt dis_estate, d
		sum tri_unempl tri_health tri_gas tri_debt tri_estate
		
	* People who are numerically literate overestimate less

	
	* Debt
	***  NOTHING: tri, ord, regress, ranksum, quantile don't work  
	***  For pid_app == 1 tri, ordered, regress, ranksum show gap is exacerbated b/w strong and weak partisans
	**************************************************************************************************************	
		* Tri
			oprobit tri_debt i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			oprobit tri_debt i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1
		
			* Bushref
			oprobit tri_debt i.rd##c.pid7new r_PIDloc if r_bushref==1 & (pid_app==1 | pid_app==4)
			
		* Ord
			oprobit debt_num i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			oprobit debt_num i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1
			oprobit debt_num i.rd r_PIDloc r_bushref if pid_app==4
			
		* Regress
			regress debt_num i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
		
		* Regressing percentile scores
			regress pct_debt i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			
		* Kruskal-Wallis
			kwallis debt_num if pid_app==1, by(rdm)
			kwallis debt_num if pid_app==4, by(rdm)
			
		* Quantile
			sqreg  debt_num rd1 rd2 pid7new rd1Xpid7 rd2Xpid7 r_PIDloc r_bushref if pid_app==1 | pid_app==4, q(.25 .5 .75) reps(100)
			
	* Estate
	***  wrong dir: tri (marg; incorrect in the apsa ms.), ord (sig.), regress (no) 
	***  tri, ord, ranksum for pid_app=4, works for pid_app==4
	**************************************************************************************************************	
		* Tri
			oprobit tri_estate i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			oprobit tri_estate i.rd r_PIDloc r_bushref if pid_app==4
			oprobit tri_estate i.rd##c.pid7new r_PIDloc if (pid_app==1 | pid_app==4) & r_bushref==1
			
		* Ord
			oprobit estate_num i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			oprobit estate_num i.rd r_PIDloc r_bushref if pid_app==4

		* Regress
			regress estate_num i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
		
		* Regressing percentile scores
			regress pct_estate i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			
		* Kruskal-Wallis
			kwallis estate_num if pid_app==1, by(rdm)
			kwallis estate_num if pid_app==4, by(rdm) 
			
		* Quantile
			sqreg estate rd1 rd2 pid7new rd1Xpid7 rd2Xpid7 r_PIDloc r_bushref if pid_app==1 | pid_app==4, q(.25 .5 .75) reps(100)
			
	* Uninsured
	***  tri, ord, pct, ranksum work  
	***  regress, robust (l3s marg.), sig. for R only 
	***  quantile works (median, 25th  - both sig.)
	**************************************************************************************************************	
		* Tri (tri_health tried, it works)
			oprobit tri_health i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			oprobit tri_health2 i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			oprobit tri_health2 i.rd r_PIDloc r_bushref if pid_app==4
			
		* Ord
		*	oprobit l3 i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
		
		* Regress (l3r works better, l3s marg.; For R only l3s is sig.)
			regress l3s i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			regress l3s i.rd r_PIDloc r_bushref if pid_app==4
			
		* Regressing percentile scores
			regress pct_health i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			
		* Robust
			rreg l3s i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			rreg l3s i.rd r_PIDloc r_bushref if pid_app==4
		
		* Kruskal-Wallis
			kwallis l3 if pid_app==1, by(rdm)
			kwallis l3 if pid_app==4, by(rdm) 
			
		* Quantile
			sqreg l3 rd1 rd2 pid7new rd1Xpid7 rd2Xpid7 r_PIDloc r_bushref if pid_app==1 | pid_app==4, q(.25 .5 .75) reps(100)
		
	* Gas
	***   tri, robust, Quantile (median, 75th percentile) work. 
	***   Regress doesn't work but good reasons for why that shldn't bother us. 
	***   regress works for pid_app==1; generally dem. move more; pct is marginal
	**************************************************************************************************************	
		* Tri (tried tri_gas, gives marginal)
			oprobit tri_gasr_corr_st i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
				
		* Regress
			regress l5r i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			regress l5r i.rd r_PIDloc r_bushref if pid_app==1
			
		* Regressing percentile scores
			regress pct_gas i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			
		* Robust (also tried l5r)
			rreg l5 i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
		
		* Kruskal-Wallis
			kwallis l5 if pid_app==1, by(rdm)
			kwallis l5 if pid_app==4, by(rdm) 
			
		* Quantile (also tried l5r)
			sqreg l5 rd1 rd2 pid7new rd1Xpid7 rd2Xpid7 r_PIDloc r_bushref if pid_app==1 | pid_app==4, q(.25 .5 .75) reps(100)
		
		
	* Unemp
	*** tri, ord, robust, quantile (25th and median) work. 
	*** Regression doesn't. Robust regression does.
	*** stronger for pid_app==4, than 1
	**************************************************************************************************************			
		* Tri (tried tri_unempl, works)
			oprobit tri_unempl2 i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			oprobit tri_unempl2 i.rd r_PIDloc r_bushref if pid_app==1
			oprobit tri_unempl2 i.rd r_PIDloc r_bushref if pid_app==4

		* Ord
		*	oprobit l2 i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
		
		* Regress (also tried l2r, l2s)
			regress l2 i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			
		* Regressing percentile scores
			regress pct_unemp i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			
		* Robust
			rreg l2 i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
		
		* Kruskal-Wallis
			kwallis l2 if pid_app==1, by(rdm)
			kwallis l2 if pid_app==4, by(rdm) 
			
		* Quantile
			sqreg l2 rd1 rd2 pid7new rd1Xpid7 rd2Xpid7 r_PIDloc r_bushref if pid_app==1 | pid_app==4, q(.25 .5 .75) reps(100)
		
	*** Seemingly Unrelared Regression
	*** Nothing here
	**********************************************	
		sureg (l2r i.rd##c.pid7new r_PIDloc r_bushref) (l5r i.rd##c.pid7new r_PIDloc r_bushref)  (l3r i.rd##c.pid7new r_PIDloc r_bushref) (debt_num i.rd##c.pid7new r_PIDloc r_bushref) (estate_num i.rd##c.pid7new r_PIDloc r_bushref)  if pid_app==1 | pid_app==4,corr
		sureg (pct_unemp i.rd##c.pid7new r_PIDloc r_bushref) (pct_gas i.rd##c.pid7new r_PIDloc r_bushref)  (pct_health i.rd##c.pid7new r_PIDloc r_bushref) (pct_debt i.rd##c.pid7new r_PIDloc r_bushref) (pct_estate i.rd##c.pid7new r_PIDloc r_bushref)  if pid_app==1 | pid_app==4,corr
		
		*mvprobit (tri_unempl2 rd1 rd2 pid7new rd1Xpid7 rd2Xpid7 r_PIDloc r_bushref) (tri_gasr_corr_st rd1 rd2 pid7new rd1Xpid7 rd2Xpid7 r_PIDloc r_bushref)  (tri_health2 rd1 rd2 pid7new rd1Xpid7 rd2Xpid7 r_PIDloc r_bushref) (tri_debt rd1 rd2 pid7new rd1Xpid7 rd2Xpid7 r_PIDloc r_bushref) (tri_estate rd1 rd2 pid7new rd1Xpid7 rd2Xpid7 r_PIDloc r_bushref)  if pid_app==1 | pid_app==4
		bioprobit (tri_health2 rd1 rd2 pid7new rd1Xpid7 rd2Xpid7 r_PIDloc r_bushref) (tri_debt rd1 rd2 pid7new rd1Xpid7 rd2Xpid7 r_PIDloc r_bushref)  if pid_app==1 | pid_app==4

		
	*** Hierarchical Model
	*** with percentile
	*****************************************************************
		
		gen pid3b = pid3a
		replace pid3b = 0 if pid3b==1
		replace pid3b = 1 if pid3b==3
			
		gen rd1Xpid3b     	= rd1*pid3b
		gen rd2Xpid3b      	= rd2*pid3b
				
		keep caseid pct_unemp pct_gas pct_health pct_debt pct_estate rd rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b pid_app r_bushref r_PIDloc rd1Xr_bushref rd2Xr_bushref rd1Xr_PIDloc rd2Xr_PIDloc t_l1 t_l2 t_l3 t_l4 t_l5 t_disp1 t_disp2 t_disp3
		keep if pid_app==1 | pid_app==4
		rename pct_unempl      tri_dv1
		rename pct_gas 		   tri_dv2
		rename pct_debt        tri_dv3
		rename pct_health      tri_dv4
		rename pct_estate      tri_dv5
		
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
		* gllamm (reproduces what you get from Hier.KN2008)
			gllamm tri_dv rd1 rd2 pid3b rd1Xpid3b rd2Xpid3b seq1 seq2 seq3 seq4, i(caseid)
	
	*** Hierarchical Model
	*** works (can do without tri_estate and it works then as well)
	*****************************************************************
	* flip tri_estate
	gen tri_estater= .
	replace tri_estater=1 if tri_estate==2
	replace tri_estater=2 if tri_estate==1
	label define estatel 1 Great 2 Cor
	label val tri_estater estatel 
	
	keep caseid tri_unempl2 tri_gasr_corr_st tri_health2  tri_debt tri_estate tri_estater rd rd1 rd2 pid7 rd1Xpid7 rd2Xpid7 pid_app r_bushref r_PIDloc rd1Xr_bushref rd2Xr_bushref rd1Xr_PIDloc rd2Xr_PIDloc t_l1 t_l2 t_l3 t_l4 t_l5 t_disp1 t_disp2 t_disp3
	keep if pid_app==1 | pid_app==4
	rename tri_unempl2      tri_dv1
	rename tri_gasr_corr_st tri_dv2
	rename tri_debt         tri_dv3
	rename tri_health2      tri_dv4
	rename tri_estater      tri_dv5
	
	reshape long tri_dv, i(caseid)
	 
	* gllamm (reproduces what you get from Hier.KN2008)
		gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7, i(caseid) link(ologit)
	
	* Can do a joint f-test or something with bushref and pidloc
		gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7 r_bushref r_PIDloc rd1Xr_bushref rd2Xr_bushref rd1Xr_PIDloc rd2Xr_PIDloc, i(caseid) link(ologit)
		
	* Doing it with timers
		keep if t_l1 < 90 &  t_l2 < 90 & t_l3 < 90 & t_l4 < 90 & t_l5 < 90
		gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7, i(caseid) link(ologit)
		
		keep if t_l1 < 60 &  t_l2 < 60 & t_l3 < 60 & t_l4 < 60 & t_l5 < 60
		gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7, i(caseid) link(ologit)
		
		keep if t_l1 < 45 &  t_l2 < 45 & t_l3 < 45 & t_l4 < 45 & t_l5 < 45
		gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7, i(caseid) link(ologit)
	
		keep if t_l1 < 31 &  t_l2 < 31 & t_l3 < 31 & t_l4 < 31 & t_l5 < 31
		gllamm tri_dv rd1 rd2 pid7 rd1Xpid7 rd2Xpid7, i(caseid) link(ologit)
	
* Hier
* In APSA 2012 paper 
*******************************

		** TABLE 1: ORDERED PROBIT MODEL 8-25-12 **
		oprobit tri_debt i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			test 1.rd = 2.rd
			test 1.rd#c.pid7new = 2.rd#c.pid7new
			test 1.rd 2.rd
			test 1.rd#c.pid7new  2.rd#c.pid7new

		oprobit tri_health2 i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			test 1.rd = 2.rd
			test 1.rd#c.pid7new = 2.rd#c.pid7new
			test 1.rd 2.rd
			test 1.rd#c.pid7new  2.rd#c.pid7new

		oprobit tri_unempl2 i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			test 1.rd = 2.rd
			test 1.rd#c.pid7new = 2.rd#c.pid7new
			test 1.rd 2.rd
			test 1.rd#c.pid7new  2.rd#c.pid7new

		oprobit tri_gasr_corr_st i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			test 1.rd = 2.rd
			test 1.rd#c.pid7new = 2.rd#c.pid7new
			test 1.rd 2.rd
			test 1.rd#c.pid7new  2.rd#c.pid7new

		oprobit tri_estate i.rd##c.pid7new r_PIDloc r_bushref if pid_app==1 | pid_app==4
			test 1.rd = 2.rd
			test 1.rd#c.pid7new = 2.rd#c.pid7new
			test 1.rd 2.rd
			test 1.rd#c.pid7new  2.rd#c.pid7new
	

			
			

		
