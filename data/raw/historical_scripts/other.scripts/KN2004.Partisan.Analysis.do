** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ **
**									    	**
**  KN 2004								
**  Partisan Inference Analyses			
**  Last Edited: 2/19/2013 by GS		
**  Analyses: Tri, Ordered, Regress, Percentile 
**            Robust, Quantile, SUR,
**			  Hierarchical
**											**
** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **


* Set Library Location for finding survwgt (Leave it for GS)
	sysdir set PLUS "\\files\dept\WWS\Research\MPRIOR\stata\"

	* ssc install gllamm
	
* Load data
	use "H:\PartisanInferencePaper\data\KN2004.recoded.dta", clear

	* for Quantile Regression
		gen payXpid7 = pay*pid7new
		gen payXpid3 = pay*pid3
		set seed 1210

*** cheat sheet
***	correct ans: unemploy (5), debt (7.5), estate (5), poor (12.5), unins (15.6)

*** Analyses

*** People on average/median over-estimate (overestimate on all except debt)
		sum dev_unempl dev_unins dev_debt dev_poor dev_estate, d
		sum tri_unempl tri_unins tri_debt tri_poor tri_estate

	* Q13: Unemployment rate. 
	***   tricho., ordered: no result; when pid7 > 4, ord., ranksum gives .16
	***   p=.14/.15 for signed diff. but see not below on truncated DV 
	***   when pid7 < 4; tri, ordered, and regress show increasing gap b/w strong and weak Rs
	***   quantile for 75th percentile
	**************************************************************************************************************	
		* Tri
			* oprobit
				oprobit tri_unempl pay##c.pid7 if time==0 & pid7~=4 
				oprobit tri_unempl pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)			
				oprobit tri_unempl i.pay##c.pid7 if time==0 & pid7 < 4
				oprobit tri_unempl i.pay##c.pid3 if time==0 & pid7~=4
			
			* mprobit
				mprobit tri_unempl i.pay##c.pid7 if time==0 & pid7~=4, base(0)
				mprobit tri_unempl i.pay##c.pid3 if time==0 & pid7~=4, base(0)
				
		* All ordered
			oprobit dev_unempl i.pay##c.pid7 if time==0 & pid7~=4 
			oprobit dev_unempl i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)

			oprobit dev_unempl i.pay if time==0 & pid7 > 4
			
			oprobit dev_unempl i.pay##c.pid7 if time==0 & pid7 < 4
		
		* For truncated DV Regress and Oprobit give the same ans.
			regress dev_unempl pay##c.pid7 if time==0 & pid7 ~= 4 & dev_unempl < 9
			oprobit dev_unempl pay##c.pid7 if time==0 & pid7 ~= 4 & dev_unempl < 9
			
		* Regress
			regress dev_unempl i.pay##c.pid7 if time==0 & pid7~=4
			regress dev_unempl i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)

		* Kruskal-Wallis
			kwallis dev_unempl if time==0 & pid7 > 4, by(pay)
			kwallis dev_unempl if time==0 & pid7 < 4, by(pay)
			
		* Quantile
			sqreg dev_unempl pay pid7 payXpid7 if time==0  & pid7~=4, q(.25 .5 .75) reps(100)
			sqreg dev_unempl pay pid7 payXpid7 if time==0  & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1), , q(.25 .5 .75)  reps(100)
			sqreg dev_unempl pay pid3 payXpid3 if time==0  & pid7~=4
			
			sqreg dev_unempl pay if time==0  & pid7 < 4, q(.25 .5 .75) reps(100)
			sqreg dev_unempl pay if time==0  & pid7 > 4, q(.25 .5 .75) reps(100)
			
			iqreg dev_unempl pay pid7 payXpid7 if time==0  & pid7~=4, q(.25 .75) reps(100)
			
	* Q14: Estate Tax
	****   main effect of incentive but interaction always insig. (tri, ordered, regress) 
	***    tri, ordered etc. works for pid7 < 4 (works for R)
	***    tri, ordered, and even regress works for pid7 < 4; argument: reducing gap b/w strong and weak partisans
	**************************************************************************************************************	
		* Tri
			oprobit tri_estate i.pay##c.pid7 if time==0 & pid7~=4
			oprobit tri_estate i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
			
			oprobit tri_estate i.pay if time==0 & pid7< 4
			oprobit tri_estate i.pay##c.pid7 if time==0 & pid7< 4
			
		* All ordered
			oprobit dev_estate i.pay##c.pid7 if time==0 & pid7~=4
			oprobit dev_estate i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
			
			oprobit dev_estate i.pay if time==0 & pid7< 4
			oprobit dev_estate i.pay##c.pid7 if time==0 & pid7< 4
			
		* Regress
			regress dev_estate i.pay##c.pid7 if time==0 & pid7~=4
			regress dev_estate i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
			
		* Quantile
			sqreg dev_estate pay pid7 payXpid7 if time==0  & pid7~=4, q(.5) reps(1000)
			sqreg dev_estate pay pid7 payXpid7 if time==0  & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1), q(.5)  reps(1000)
			
			* R only
			sqreg dev_estate pay if time==0  & pid7 < 4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1), q(.5)  reps(1000)
			
			iqreg dev_estate pay pid7 payXpid7 if time==0  & pid7~=4, q(.5 .75) reps(100)
		
	* Q16: Debt
	****   works for tricho and ordered; signed diff (marginally)
	***    tri, ordered, and even regress (marginal) works for pid7 < 4; argument: reducing gap b/w strong and weak partisans
	**************************************************************************************************************
		* Tri	
			* oprobit
				oprobit tri_debt i.pay##c.pid7 if time==0 & pid7~=4 
				oprobit tri_debt i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
				oprobit tri_unempl i.pay##c.pid7 if time==0 & pid7 < 4
				oprobit tri_debt i.pay##c.pid3 if time==0 & pid7~=4
				
			* mprobit
				mprobit tri_debt i.pay##c.pid7 if time==0 & pid7~=4, base(0)
				mprobit tri_debt i.pay##c.pid3 if time==0 & pid7~=4, base(0)
			
		* All ordered
			oprobit dev_debt i.pay##c.pid7 if time==0 & pid7~=4 
			oprobit dev_debt i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
		
			oprobit dev_unempl i.pay##c.pid7 if time==0 & pid7 < 4
			
		* Regress
			regress dev_debt i.pay##c.pid7 if time==0 & pid7~=4 
			regress dev_debt i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
		
		* Quantile
			sqreg dev_debt pay pid7 payXpid7 if time==0  & pid7~=4, q(.25 .5 .75) reps(100)
			sqreg dev_debt pay pid7 payXpid7 if time==0  & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1), , q(.25 .5 .75)  reps(100)
			sqreg dev_debt pay pid3 payXpid3 if time==0  & pid7~=4
			
			iqreg dev_debt pay pid7 payXpid7 if time==0  & pid7~=4, q(.25 .75) reps(100)

	* Q15: Uninsured Americans
	****	nothing here; tricho works for pid7 < 4 (as above)
	*******************************************************************
		* Tri (also tried tri_unins1, tri_unins2, tri_unins4)
			* oprobit
				oprobit tri_unins i.pay##c.pid7 if time==0 & pid7~=4 
				oprobit tri_unins i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
				oprobit tri_unins i.pay##c.pid3 if time==0 & pid7~=4
			
			* mprobit
				mprobit tri_unins i.pay##c.pid7 if time==0 & pid7~=4, base(0)
				mprobit tri_unins i.pay##c.pid3 if time==0 & pid7~=4, base(0)
			
		* All ordered
			oprobit dev_unins i.pay##c.pid7 if time==0 & pid7~=4 
			oprobit dev_unins i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
		
		* Regress (with/without robust s.e.s)
			regress dev_unins i.pay##c.pid7 if time==0 & pid7~=4 
			regress dev_unins i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
		
		* Regressing percentile scores
			regress pct_unins i.pay##c.pid7new if time==0 & pid7~=4 
			
		* Robust Regression
			rreg dev_unins i.pay##c.pid7 if time==0  & pid7~=4 
			rreg dev_unins i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
			
		* Quantile
			sqreg dev_unins pay pid7 payXpid7 if time==0  & pid7~=4, q(.25 .5 .75) reps(100)
			sqreg dev_unins pay pid7 payXpid7 if time==0  & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1), , q(.25 .5 .75)  reps(100)
	 	
			iqreg dev_unins pay pid7 payXpid7 if time==0  & pid7~=4, q(.25 .75) reps(100)
		
	* Q18: Poverty
	****	wrong dir: main effect for tricho in all; interaction works fine for ordered, and signed diff;
	****	interaction with white works
	******************************************************************************
		* Tri (also tried: tri_poor1, tri_poor2, tri_poorp)
			* probit
				oprobit tri_poor i.pay##c.pid7 if time==0 & pid7~=4 
				oprobit tri_poor i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
				oprobit tri_poor i.pay##c.pid3 if time==0 & pid7~=4
				
			* mprobit
				mprobit tri_poor i.pay##c.pid7 if time==0 & pid7~=4, base(0)
				mprobit tri_poor i.pay##c.pid3 if time==0 & pid7~=4, base(0)
			
			* R's reduce estimates
			oprobit tri_poor i.pay if time==0 & pid7 < 4
		
			oprobit tri_poor i.pay##c.white if time==0
			
			
		* All ordered
		*	oprobit dev_poor i.pay##c.pid7 if time==0 & pid7~=4 
		*	oprobit dev_poor i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
			
		*	oprobit dev_poor i.pay##c.white if time==0
		
		* Regress
			regress dev_poor i.pay##c.pid7 if time==0  & pid7~=4 
			regress dev_poor i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
			
			regress dev_poor i.pay##c.white if time==0
		
		* Regressing percentile scores
			regress pct_poor i.pay##c.pid7new if time==0 & pid7~=4 
			
		* Constrain to Whites only (both change in the same direction)
			rreg dev_poor i.pay if time==0 & pid7 < 4 & white==1
			rreg dev_poor i.pay if time==0 & pid7 > 4 & white==1
			
		* Robust Regression
			rreg dev_poor i.pay##c.pid7 if time==0  & pid7~=4 
			rreg dev_poor i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
			
			rreg dev_poor i.pay##c.white if time==0
		
		* Kruskal-Wallis
			kwallis dev_poor if time==0 & pid7 > 4, by(pay)
			kwallis dev_poor if time==0 & pid7 < 4, by(pay)
			
		* Quantile
			sqreg dev_poor pay pid7 payXpid7 if time==0  & pid7~=4, q(.25 .5 .75) reps(100)
			sqreg dev_poor pay pid7 payXpid7 if time==0  & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1), , q(.25 .5 .75)  reps(100)
			
			iqreg dev_poor pay pid7 payXpid7 if time==0  & pid7~=4, q(.25 .75) reps(100)

	*** Seemingly Unrelared Regression
	**********************************************	
		sureg (dev_unempl i.pay##c.pid7) (dev_estate i.pay##c.pid7)  (dev_debt i.pay##c.pid7) (dev_unins i.pay##c.pid7) (dev_poor i.pay##c.pid7)  if time==0  & pid7~=4, corr
		sureg (dev_unempl i.pay##c.pid3) (dev_estate i.pay##c.pid3)  (dev_debt i.pay##c.pid3) (dev_unins i.pay##c.pid3) if time==0  & pid7~=4, corr
		
	*** Hierarchical Model
	*** Works for Republicans (pay inc. estimates) if you take out poor
	**********************************************************************
	* flip tri_estate
	gen tri_estater= .
	replace tri_estater=1 if tri_estate==2
	replace tri_estater=2 if tri_estate==1
	label define estatel 1 Great 2 Cor
	label val tri_estater estatel 
	
	keep caseid tri_unempl tri_estate tri_estater tri_debt tri_unins tri_poor pay pid7 payXpid7 pid7new time voteint pid3a pid3a payXpid3
	keep if time==0  & pid7~=4
	rename tri_unempl  tri_dv1
	rename tri_estater tri_dv2
	rename tri_debt    tri_dv3
	rename tri_unins   tri_dv4
	*rename tri_poor    tri_dv5
	
	reshape long tri_dv, i(caseid)
	 
	 * Analyses
		gllamm tri_dv pay pid3 payXpid3, i(caseid) link(ologit) 
		gllamm tri_dv pay pid3 payXpid3, i(caseid) link(mlogit) 
		
		keep if time==0  & pid7 < 4
		gllamm tri_dv pay, i(caseid) link(ologit)
	
	
*** Stop Here -- Don't include Kerry item
*************************************************
	
	* Q17: Kerry tax cut
		*** main effect on tri, ordered; nothing works on interaction
		*** tri, ordered, regress work for pid7 < 4
		********************************************************
		* Tri 
			oprobit tri_kerry i.pay##c.pid7 if time==0 & pid7~=4 
			oprobit tri_kerry i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
		
			oprobit tri_kerry i.pay if time==0 & pid7 < 4
			
		* All ordered
			oprobit dev_kerry i.pay##c.pid7 if time==0 & pid7~=4 
			oprobit dev_kerry i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
		
			oprobit dev_kerry i.pay if time==0 & pid7 < 4
			
		* Regress
			regress dev_kerry i.pay##c.pid7 if time==0  & pid7~=4 
			regress dev_kerry i.pay##c.pid7 if time==0 & pid7~=4 & ~(voteint==0 & pid3a==3) & ~(voteint==1 & pid3a==3) & ~(voteint==3 & pid3a==1)& ~(voteint==4 & pid3a==1)
										