** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **
**									    	**							
**  Partisan Inference Analyses			
**  Last Edited: 4/16/2013 by GS		
**  Merge standardized set of variables 
**											
** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **
 
* Set Library Location for finding survwgt (Leave it for GS)
	sysdir set PLUS "\\files\dept\WWS\Research\MPRIOR\stata\"
	* ssc install gllamm

* Common vars for 2004 and 2008
* caseid, pollid, pay, pid7new, payXpid7, rd1Xpid7, rd2Xpid7, pid_app, time, tri_dv1.... tri_dv9, voteint, r_PIDloc r_bushref

* add to 2008: time, voteint, tri_dv6....tri_dv9
* add to 2004: rd1, rd2, rd1Xpid7, rd2Xpid7, pid_app, r_PIDloc r_bushref
* add to both: pollid

* keep caseid tri_unempl tri_estate tri_estater tri_debt tri_unins tri_poor pay pid7 payXpid7 pid7new time voteint pid3a
* keep caseid tri_unempl2 tri_gasr_corr_st tri_health2  tri_debt tri_estate tri_estater rd rd1 rd2 pid7 rd1Xpid7 rd2Xpid7 pid_app
* keep caseid tri_unempl tri_estate tri_estater tri_debt tri_unins tri_poor pay pid7 payXpid7 pid7new time voteint pid3a
	
* Note
* Use of xi for interactions: xi: gllamm tri_dv i.pay*pid7, i(caseid) link(ologit)

** 2008
*****************************************************************
			
	* Load data
		use "h:\PartisanInferencePaper\data\KN2008.merged.recoded.dta", clear	

	* There are 43 obs. for which rd etc. is missing. they cause problems with recode 
	* Note: when recoding, replace with if needs correction for missing as missing inappropriately handled by STATA
		keep if rd~=.
		
	* Time info
		* The response time variables for the 2008 knowledge items are t_l1 - t_l5. 
		* The timers for the instruction screens are t_disp1, t_disp2, and t_disp3 for control, verbal, and monetary, respectively.
		* keep t_l1 t_l2 t_l3 t_l4 t_l5 t_disp1 t_disp2 t_disp3
		* nohispeed, 
		* reshape long tri_dv t_l t_disp, i(caseid)

	* Some recodes and gens
		
		gen pollid 	     = 2008
		gen time		 = .
		gen voteint      = .

		gen rd1			 = 0
		replace rd1      = 1 if rd==1
		replace rd1		 = . if rd==.
		
		gen rd2			 = 0
		replace rd2      = 1 if rd==2
		replace rd2		 = . if rd==.
		
		gen rd1Xpid7     = c.rd*pid7new if c.rd==1
		replace rd1Xpid7 = 0 if c.rd~=1
		replace rd1Xpid7 = . if c.rd==.
		replace rd1Xpid7 = . if pid7==.
		
		gen rd2Xpid7     = pid7new if c.rd==2
		replace rd2Xpid7 = 0 if c.rd~=2
		replace rd2Xpid7 = . if c.rd==.
		replace rd2Xpid7 = . if pid7==.

		gen rd1Xr_bushref     = c.rd*r_bushref if c.rd==1
		replace rd1Xr_bushref = 0 if c.rd~=1
		
		gen rd2Xr_bushref     = r_bushref if c.rd==2
		replace rd2Xr_bushref = 0 if c.rd~=2
		
		gen rd1Xr_PIDloc     = c.rd*r_PIDloc if c.rd==1
		replace rd1Xr_PIDloc = 0 if c.rd~=1
		
		gen rd2Xr_PIDloc     = r_PIDloc if c.rd==2
		replace rd2Xr_PIDloc = 0 if c.rd~=2
		
		gen pay 		 	= rd2
		replace pay      	= . if rd==1
		replace pay      	= . if rd==.
		
		gen payXpid7      	= pay*pid7new
		gen payXpid3a 		= pay*pid3a 
		
		gen payXr_bushref   = pay*r_bushref
		gen payXr_PIDloc    = pay*r_PIDloc
		
		gen pay2 		  	= 2
		replace pay2      	= . if rd==1
		replace pay2      	= 0 if rd==0
		replace pay2      	= . if rd==.
		
		gen pay2Xpid7      	= pay2*pid7new
		gen pay2Xpid3a      = pay2*pid3a 
		
		gen pay2Xr_bushref  = pay2*r_bushref
		gen pay2Xr_PIDloc   = pay2*r_PIDloc
		
		gen kn_sum = kn_gen + kn_tote 
		
	* flip tri_estate
		gen tri_estater= .
		replace tri_estater=1 if tri_estate==2
		replace tri_estater=2 if tri_estate==1
		label define estatel 1 Cor 2 Great
		label val tri_estater estatel 
	
	* rename the tri_dvs
		* Unemployment
			*rename tri_unempl2			tri_dv1
			* Payout DV
			*rename tri_unempl_payout	tri_dv1
			* 23% DV
			*rename tri_unempl23		tri_dv1
			* 33% DV
			rename tri_unempl33		tri_dv1
			* 10 DV
			*rename tri_unempl10		tri_dv1
			
		* Gas
			*rename tri_gasr_corr_st		tri_dv2
			* Payout DV
			*rename tri_gas_payout		tri_dv2
			* 23% DV
			*rename tri_gas23	 		tri_dv2
			* 33% DV
			rename tri_gas33	 		tri_dv2
			* 10 DV
			*rename tri_gas10	 		tri_dv2
		* Uninsured
			* Payout and ms. are the same
			*rename tri_health2      	tri_dv4
			* 23% DV
			*rename tri_health23      	tri_dv4
			* 33% DV
			rename tri_health33      	tri_dv4
			* 10 DV
			*rename tri_health10      	tri_dv4
		
		*Estate and Debt
			rename tri_debt         	tri_dv3
			rename tri_estater      	tri_dv5
			
	* rename the pct_dvs
		rename pct_unempl      pct_dv1
		rename pct_gas 		   pct_dv2
		rename pct_debt        pct_dv3
		rename pct_health      pct_dv4
		rename pct_estate      pct_dv5
	
		gen  pct_dv6  =.
		gen  pct_dv7  =.
		gen  pct_dv8  =.
		gen  pct_dv9  =.
		gen  pct_dv10 =.
	
	* rename the raw_dvs
		rename raw_unempl      raw_dv1
		rename raw_gas 		   raw_dv2
		rename raw_debt        raw_dv3
		rename raw_health      raw_dv4
		rename raw_estate      raw_dv5
	
		gen  raw_dv6  =.
		gen  raw_dv7  =.
		gen  raw_dv8  =.
		gen  raw_dv9  =.
		gen  raw_dv10 =.
		
		
	* polint
	* pidstr
	* num
	* voc
	* kn_tote 
	* ppeducat
	
	* kn_tote dummy
		recode kn_tote 0/7 = 0 12/18=1 8/11 = ., gen(pkdum)
		
	* gen 2004 dvs
		label define trirh 1 "Cor" 0 "Less" 2 "Great"	
		
		gen tri_dv6 = .
		label val  tri_dv6 trirh
		gen tri_dv7 = .
		label val  tri_dv7 trirh
		gen tri_dv8 = .
		label val  tri_dv8 trirh
		gen tri_dv9 = .
		label val  tri_dv9 trirh

	* Save subset
		keep caseid pollid tri_dv1 tri_dv2 tri_dv3 tri_dv4 tri_dv5 tri_dv6 tri_dv7 tri_dv8 tri_dv9 pay pay2 time rd rd1 rd2 pid7 pid3a pid_app pid7new rd1Xpid7 rd2Xpid7 payXpid7 payXpid3a voteint r_PIDloc r_bushref payXr_bushref payXr_PIDloc pay2Xpid7 pay2Xpid3a pay2Xr_bushref pay2Xr_PIDloc white polint pidstr num voc kn_tote ppeducat pkdum cablepk kn_sum strpid weakpid leanpid stdem strep wkdem wkrep lnrep mleanpid tripk t_l1 t_l2 t_l3 t_l4 t_l5 t_disp1 t_disp2 t_disp3 nohispeed alone newpk pct_dv1 pct_dv2 pct_dv3 pct_dv4 pct_dv5 pct_dv6 pct_dv7 pct_dv8 pct_dv9 pct_dv10 raw_dv1 raw_dv2 raw_dv3 raw_dv4 raw_dv5 raw_dv6 raw_dv7 raw_dv8 raw_dv9 raw_dv10
		save "H:\PartisanInferencePaper\data\KN2008.hier.subset.dta", replace
	
* 2004	
*** Works for Republicans (pay inc. estimates) if you take out poor
**********************************************************************
	* Load data
		use "H:\PartisanInferencePaper\data\KN2004.recoded.dta", clear

	* make caseid unique (from 2008)
		replace caseid = caseid + 10000
		
	* Timers for 2008
		gen t_l1 =.
		gen t_l2 =.
		gen t_l3 =.
		gen t_l4 =. 
		gen t_l5 =. 
		gen t_disp1 =.
		gen t_disp2 =.
		gen t_disp3 =.
	
	* New pk
		gen newpk =.
		
	* recodes and gens
		gen pollid        = 2004
		gen pid_app		  = .
		gen rd			  = .
		gen rd1			  = .
		gen rd2           = .
		gen rd1Xpid7      = . 
		gen rd2Xpid7      = .
		gen r_bushref     = 0
		gen r_PIDloc      = 0
		
		recode pid7 1=1 2=0 3=0 4=. 5=0 6=0 7=1, gen(strpid2)
		
		* pid3b
		recode pid7 1 2 3=1 4 =. 5 6 7 = 0, gen(pid3b)
		
		gen payXpid7        = pay*pid7new
		gen payXpid3a       = pay*pid3a 
		gen payXr_bushref   = pay*r_bushref
		gen payXr_PIDloc    = pay*r_PIDloc

		gen pay2			 = pay
		gen pay2Xpid7        = pay*pid7new
		gen pay2Xpid3a       = pay*pid3a 
		gen pay2Xr_bushref   = pay*r_bushref
		gen pay2Xr_PIDloc    = pay*r_PIDloc
		
	* flip tri_estate
		gen tri_estater= .
		replace tri_estater=1 if tri_estate==2
		replace tri_estater=2 if tri_estate==1
		label define estatel 1 Great 2 Cor
		label val tri_estater estatel 

	* renaming the dvs
		rename tri_unempl 			tri_dv6
		rename tri_estater			tri_dv7
		rename tri_debt    			tri_dv8
		
		* Unins
		*rename tri_unins   		tri_dv9
		*Payout 
		*rename tri_unins_payout	tri_dv9
		* 23%
		*rename tri_unins23			tri_dv9
		* 33%
		rename tri_unins33			tri_dv9
		* 10
		*rename tri_unins10			tri_dv9
		
		* Poor
		*rename tri_poor    		tri_dv10
		*Payout
		*rename tri_poor_payout 	tri_dv10
		* 23%
		*rename tri_poor23 			tri_dv10
		* 33%
		rename tri_poor33 			tri_dv10
		* 10
		*rename tri_poor10 			tri_dv10
	
	* rename the pct_dvs
		rename pct_unempl      pct_dv6
		rename pct_estate 	   pct_dv7
		rename pct_debt        pct_dv8
		rename pct_unins       pct_dv9
		rename pct_poor        pct_dv10
		
	* rename the raw_dvs
		rename raw_unempl      raw_dv6
		rename raw_estate 	   raw_dv7
		rename raw_debt        raw_dv8
		rename raw_uninsr      raw_dv9
		rename raw_poor        raw_dv10
		
	* gen 2008 dvs
		gen tri_dv1 = .
		gen tri_dv2 = .
		gen tri_dv3 = .
		gen tri_dv4 = .
		gen tri_dv5 = .

		gen  pct_dv1  =.
		gen  pct_dv2  =.
		gen  pct_dv3  =.
		gen  pct_dv4  =.
		gen  pct_dv5 =.
		
		gen  raw_dv1  =.
		gen  raw_dv2  =.
		gen  raw_dv3  =.
		gen  raw_dv4  =.
		gen  raw_dv5 =.
		
	* other missing covars
		gen num = .
		gen voc = .
		gen cablepk = .
		
		* use this alone
		gen kn_tote = info
		gen kn_sum  = info
		
	* pk dummy
		recode kn_tote 0/1.5=0 2.75/4=1 1.75/2.5=.,gen(pkdum)
		
	* Save subset
		keep caseid pollid tri_dv1 tri_dv2 tri_dv3 tri_dv4 tri_dv5 tri_dv6 tri_dv7 tri_dv8 tri_dv9 tri_dv10 pay pay2 time rd rd1 rd2 pid7 pid_app pid7new pid3a payXpid3a rd1Xpid7 rd2Xpid7 payXpid7 voteint r_PIDloc r_bushref payXr_bushref payXr_PIDloc  pay2Xpid7 pay2Xpid3a pay2Xr_bushref pay2Xr_PIDloc white polint pidstr num voc kn_tote ppeducat pkdum cablepk kn_sum  strpid weakpid leanpid stdem strep wkdem wkrep lnrep  mleanpid  tripk t_l1 t_l2 t_l3 t_l4 t_l5 t_disp1 t_disp2 t_disp3  nohispeed  alone newpk pct_dv1 pct_dv2 pct_dv3 pct_dv4 pct_dv5 pct_dv6 pct_dv7 pct_dv8 pct_dv9 pct_dv10 raw_dv1 raw_dv2 raw_dv3 raw_dv4 raw_dv5 raw_dv6 raw_dv7 raw_dv8 raw_dv9 raw_dv10
		save "H:\PartisanInferencePaper\data\KN2004.hier.subset.dta", replace
	
**
** Append 2004 and 2008 data
*******************************
	* 2008
	use "H:\PartisanInferencePaper\data\KN2008.hier.subset.dta", clear
	
	append using "H:\PartisanInferencePaper\data\KN2004.hier.subset.dta"
	save "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", replace
	
	* Time
		egen tot_time = rowtotal(t_l1 t_l2 t_l3 t_l4 t_l5)
	
	* Add some vars
	* Try education, numerical, and vocab. index. and 
				* Create some vars
				egen numvoc = rmean(num voc)
				
				gen rd1Xnum         = rd1*num
				gen rd2Xnum         = rd2*num
				gen rd1Xvoc         = rd1*voc
				gen rd2Xvoc         = rd2*voc
				gen rd1Xnumvoc      = rd1*numvoc
				gen rd2Xnumvoc      = rd2*numvoc
				gen rd1Xedu		    = rd1*ppeducat
				gen rd2Xedu		    = rd2*ppeducat
				gen rd1Xpk    	    = rd1*kn_tote
				gen rd2Xpk    	    = rd2*kn_tote
				gen rd1Xpk2    	    = rd1*kn_sum
				gen rd2Xpk2    	    = rd2*kn_sum
				gen rd1Xint   	    = rd1*polint
				gen rd2Xint   	    = rd2*polint
				gen rd1Xcab   	    = rd1*cablepk
				gen rd2Xcab   	    = rd2*cablepk
				
				gen payXedu		    = pay*ppeducat
				gen payXpk    	    = pay*kn_tote
				gen payXpk2    	    = pay*kn_sum
				gen payXint   	    = pay*polint
				gen payXcab   	    = pay*cablepk
				gen payXstr   	    = pay*pidstr
				
				gen payXstdem		= pay*stdem
				gen payXstrep    	= pay*strep
				gen payXwkdem    	= pay*wkdem
				gen payXwkrep   	= pay*wkrep
				gen payXlnrep   	= pay*lnrep
				
				gen pid7Xnum        = pid7*num
				gen pid7Xvoc        = pid7*voc
				gen pid7Xnumvoc     = pid7*numvoc
				gen pid7Xppeducat   = pid7*ppeducat
				gen pid7Xpk		    = pid7*kn_tote
				gen pid7Xpk2		= pid7*kn_sum
				gen pid7Xint	    = pid7*polint
				gen pid7Xedu	    = pid7*ppeducat
				gen pid7Xcab	    = pid7*cablepk
				
				gen rd1Xpid7Xnum    = rd1*pid7*num
				gen rd2Xpid7Xnum    = rd2*pid7*num
				gen rd1Xpid7Xvoc    = rd1*pid7*voc
				gen rd2Xpid7Xvoc    = rd2*pid7*voc
				gen rd1Xpid7Xnumvoc = rd1*pid7*numvoc
				gen rd2Xpid7Xnumvoc = rd2*pid7*numvoc
				gen rd1Xpid7Xedu    = rd1*pid7*ppeducat
				gen rd2Xpid7Xedu    = rd2*pid7*ppeducat
				gen rd1Xpid7Xpk     = rd1*pid7*kn_tote
				gen rd2Xpid7Xpk     = rd2*pid7*kn_tote
				gen rd1Xpid7Xpk2    = rd1*pid7*kn_sum
				gen rd2Xpid7Xpk2    = rd2*pid7*kn_sum
				gen rd1Xpid7Xint    = rd1*pid7*polint
				gen rd2Xpid7Xint    = rd2*pid7*polint
				gen rd1Xpid7Xcab    = rd1*pid7*cablepk
				gen rd2Xpid7Xcab    = rd2*pid7*cablepk
				
				gen payXpid7Xpk     = pay*pid7*kn_tote
				gen payXpid7Xedu    = pay*pid7*ppeducat
				gen payXpid7Xint    = pay*pid7*polint
				gen payXpid7Xcab    = pay*pid7*cablepk
				
				gen pid3b = pid3a
				replace pid3b = 0 if pid3b==1
				replace pid3b = 1 if pid3b==3
				
				gen payXstrpid      = pay*strpid
				gen payXleanpid     = pay*leanpid
				gen payXmleanpid    = pay*mleanpid
				gen payXweakpid     = pay*weakpid
				
				gen payXpid3b       = pay*pid3b
				gen rd1Xpid3b     	= rd1*pid3b
				gen rd2Xpid3b      	= rd2*pid3b
				
				gen rd1Xstrpid      = rd1*strpid
				gen rd1Xleanpid     = rd1*leanpid
				gen rd1Xmleanpid    = rd1*mleanpid
				gen rd1Xweakpid     = rd1*weakpid
				
				gen rd2Xstrpid      = rd2*strpid
				gen rd2Xleanpid     = rd2*leanpid
				gen rd2Xmleanpid    = rd2*mleanpid
				gen rd2Xweakpid     = rd2*weakpid
				
	save "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", replace
	