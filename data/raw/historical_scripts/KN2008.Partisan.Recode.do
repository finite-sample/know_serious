** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **
**						
**	KN 2008							    	**							
**  Partisan Inference			
**  Last Edited: 4/01/2013 by GS		
**											
** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **

	* set processors 2	// for laptop
	set maxvar 10000
	set matsize 6400
	set mem 2g

	* cd "H:\PartisanInferencePaper\"								// for GS
	* cd "h:\public_Aram\Gaurav\PartisanPK\"						// for MP office

	* Load data
		* use "Gaurav\merged.dta", clear				// for MP; skip merging
		use "H:\PartisanInferencePaper\data\merged.dta", clear	
	
	**************
	* Loading, Merging etc.
	*************************************************
	
	* Set Library Location for finding survwgt (Leave it for GS)
		sysdir set PLUS "\\files\dept\WWS\Research\MPRIOR\stata\"
	
	* Load Data, Run Recode
		use "H:\KnowledgeNetworksSurvey2008\data\kn2008_survey.dta", clear
		do  "H:\KnowledgeNetworksSurvey2008\KN2008visual.recoding.do"
		
		* save "Gaurav\temp.dta", replace 							// for MP
		save "H:\PartisanInferencePaper\data\KN2008 and Gas\temp.dta", replace
		
	* merge in gas price data		
	* Load gas price data, sort and save
		*use "Gaurav\KN2008.gasprice.dta", clear						// for MP
		use "H:\PartisanInferencePaper\data\KN2008 and Gas\gasprice2.dta"			
	
	* Merge Data
		*merge 1:1 caseid using "Gaurav\temp.dta"					// for MP
		*save "Gaurav\merged.dta", replace							// for MP
		
		merge 1:1 caseid using "H:\PartisanInferencePaper\data\KN2008 and Gas\temp.dta"
		save "H:\PartisanInferencePaper\data\merged.dta", replace

	* Use Merged Data
		* use "Gaurav\merged.dta", clear							// for MP
		use "H:\PartisanInferencePaper\data\merged.dta", clear
	***************************************************
	
*_______________________________________________________________________________
	
		* New pk score
			recode kn_snmaj 1=.25 2=.50 3=.75 4=1, gen(kn_snmajr)
			gen newpk = kn_blck1 + kn_blck2 + kn_blck3a + kn_snmajr
		
		* Hispeed Internet or Not
			recode cu07serv -2 -1=. 2/6=0 1=1, gen(nohispeed)
            replace nohispeed = 1 if ppnet==0 & nohispeed==.

		* HH Size
			 * some married people have a hhsize of 1, also see 18 and over
			 tab pphhsize ppmarit
			 tab ppt18ov ppmarit
			 * Lone adult
				recode ppt18ov 2/7=0, gen(alone)
			 
		* Gas price variables: avgprice, stateprice
		* Low variance conditions
		sum stateprice
		generate gas_dis_st = abs(l5 - stateprice)
		generate gas_dis_nat = abs(l5 - 3.27)

		* Bush approve ra, k3a, m1_1
			replace k3a = m1_1 if k3a==.
			gen approve = 4-k3a 
			recode k3a 1=1 2=1 3=0 4 =0, gen(approved)
			label define approved 1 Approve 0 Disapprove
			label val approved approved
			
			gen disapp = 3-approve
			gen disappd = 1-approved
				
		* L section 
		/*
		 * Time
		 * recode t_l1 0/2=0 3/70=1 71/300=-1, gen(l1_tflag)
		 *  recode t_l2 0/2=0 3/70=1 71/800=-1, gen(l2_tflag)
		 * recode t_l3 0/2=0 3/70=1 71/4000=-1, gen(l3_tflag)
		 * recode t_l4 0/2=0 3/70=1 71/300=-1, gen(l4_tflag)
		 * recode t_l5 0/2=0 3/70=1 71/700=-1, gen(l5_tflag)
		 
		 * Dummy Coding
		 * Missing coded 0
		 * recode l1 5=1 1 2 3 4 6 7 .=0 if l1_tflag~=., gen(kn_debt)
		 * recode l2 3.8/5.8=1 0/3.7 5.9/100 . =0 if l2_tflag~=., gen(kn_unempl)
		 * recode l3 13.8/17.8=1 0/13.7 17.9/100 . =0 if l3_tflag~=., gen(kn_health)
		 * recode l4 1=1 2 3 4 5 .=0 if l4_tflag~=., gen(kn_estate)
		*/
		
		* Gas 
			*Taking out negative value from gas and the one superhuge value
				replace l5 =. if l5 < 0
				replace l5 =. if l5 > 500
				
			* Adjusting for decimals where greater than 100
				gen l5r = l5
				replace l5r = l5/100 if l5 >= 100
					gen templ5diffr = l5 - l5r		// check if difference is predicted by treatment
					reg templ5diffr i.rd r_bushref r_PIDloc
					reg templ5diffr i.rd##i.r_bushref##i.r_PIDloc
		
		* Giving people credit based on decimal errors in gas
			gen temp2 = l5 > 100
			gen temp3 = l3 > 50
			gen temp4 = l2 > 33
						
			bysort temp2: tab temp3 temp4
			
		* number of times R used decimal point
			gen temp5dec = (l5 ~= round(l5))
			gen temp3dec = (l3 ~= round(l3))
			gen temp2dec = (l2 ~= round(l2))
			egen tempdec = rsum(temp?dec)
		
		* Gas had escaped Dummy coding
				recode l5 3.17/3.37=1 0/3.16 3.38/20 .=0 if l5_tflag~=., gen(kn_gas)
				replace kn_gas = 0 if kn_gas > 1 | kn_gas < 0
			
		* Unemployment - Alternate codings (giving people credit)
			* Based on gas errors
				gen l2s = l2
				replace l2s = l2/10 if l5 > 100 & l2 > 33
					gen templ2diffs = l2 - l2s		// check if difference is predicted by treatment
					reg templ2diffs i.rd r_bushref r_PIDloc
					reg templ2diffs i.rd##i.r_bushref##i.r_PIDloc
			
			* Ceiling
				recode  l2 34/100 = 34, gen(l2ceil)
			
			* Dividing more numbers over 33 by 10, setting rest to 33
				gen  l2r = l2
				replace l2r = l2/10 if l5 > 100 & l2r > 33
				replace l2r = l2/10 if l3 > 49 & l2r > 33
				replace l2r = l2/10 if l2r > 33 & tempdec==0
				replace l2r = 33 if l2r > 33 & l2r~=.
					gen templ2diffr = l2 - l2r
					reg templ2diffr i.rd r_bushref r_PIDloc
					reg templ2diffr i.rd##i.r_bushref##i.r_PIDloc
										
	
		 * Uninsured
			* Ceiling
				recode  l3 30/100 = 30, gen(l3ceil)
				
			* Gas Based coding
				gen l3s = l3
				replace l3s = l3/10 if l5 > 100 & l3 > 49
					gen templ3diffs = l3 - l3s		// check if difference is predicted by treatment
					reg templ3diffs i.rd r_bushref r_PIDloc
					reg templ3diffs i.rd##i.r_bushref##i.r_PIDloc
		
			* Dividing more numbers over 49 by 10, setting rest to 33
				gen  l3r = l3
				replace l3r=l3/10 if l5 > 100 & l3r > 49
				replace l3r=l3/10 if l3r > 49 & l2 > 33
				replace l3r=l3/10 if l3r > 49 & tempdec==0
				replace l3r=49 if l3r > 49 & l3r~=.
					gen templ3diffr = l3 - l3r

		** Recode tri_health so that correct answer range is +/- 1 percentage point (as per codebook)
			recode l3 14.8/16.8=1 0/14.7=0 16.9/100=2, gen(tri_health2)
			label val  tri_health2 tri
						reg templ3diffr i.rd r_bushref r_PIDloc
						reg templ3diffr i.rd##i.r_bushref##i.r_PIDloc
									
		* Numerical Coding of closed-ended
		* Following is not needed for rgrsn as we are just doing intercept diff. 		
			recode l1 1=5.5 2=6.5 3=7.5 4=8.5 5=9.5 6=10.5 7=11.5, gen(debt_num)
			recode l4 1=5 2=25 3=50 4=75 5=95, gen(estate_num)

		* Absolute Distance from correct
			generate dis_unempl = abs(l2 - 4.8)  		
			generate dis_health = abs(l3 - 15.8) 		
			generate dis_gas 	= abs(l5 - 3.27)
			generate dis_debt   = abs(9.5 - debt_num)  		
			generate dis_estate = abs(5 - estate_num)

	* Percentile coding
			egen n = count(debt_num)
			egen rank_debt  = rank(debt_num) 
			gen pct_debt    = (rank_debt - .5)/n
			drop n
			
			egen n = count(l2)
			egen rank_unempl  = rank(l2) 
			gen pct_unempl     = (rank_unempl - .5)/n
			drop n
			
			egen n = count(l5)
			egen rank_gas  = rank(l5) 
			gen pct_gas     = (rank_gas - .5)/n
			drop n
			
			egen n = count(l3)
			egen rank_health  = rank(l3) 
			gen pct_health     = (rank_health - .5)/n
			drop n
			
			gen estate_numr = -1*estate_num
			egen n = count(estate_numr)
			egen rank_estate  = rank(estate_numr) 
			gen pct_estate     = (rank_estate - .5)/n
			drop n
		
		* Raw coding
			gen raw_debt	= (debt_num - 5.5)/6
			gen raw_unempl	= l2/100
			gen raw_gas	    = (l5r)/66
			gen raw_health	= (l3)/100
			gen raw_estate	= ((5 - estate_num)/90) + 1
				
	* Worse that base rate, base rate, or greater than base rate
		* Define a label 
			label define trir 1 "Base" 0 "Less" 2 "Great"	
			
			recode l1 1=0 2 3 4 5 6 7 = 2,gen(tri_debtr)
			label val  tri_debtr trir
			
			* Estate tax had no base rate
			
			recode l2 4.6/4.8=1 0/4.6 = 0 4.8/100 = 2, gen(tri_unemplr)
			label val  tri_unemplr trir
			
			recode l3 14.0/14.2=1 0/14.0 =0 14.2/100 =2, gen(tri_healthr)
			label val  tri_healthr trir
			
			recode l5 1.47/1.51=1 0/1.47 = 0 1.51/20 = 2, gen(tri_gasr)
			replace tri_gasr = 2 if tri_gasr > 1
			replace tri_gasr = 0 if tri_gasr < 0
			label val  tri_gasr trir
			
	* Trichotomous coding: Less, Correct, Greater
		* Define a label 
			label define tri 1 "Cor" 0 "Less" 2 "Great"	
			
			recode l1 5=1 1 2 3 4 = 0 6 7 = 2,gen(tri_debt)
			label val  tri_debt tri
			
			recode l4 1=1 2 3 4 5=2,gen(tri_estate)
			label val  tri_estate tri
			
			* Unemployment
				recode l2 3.8/5.8=1 0/3.7 = 0 5.9/100 = 2, gen(tri_unempl)
				label val  tri_unempl tri
			
				** Recode tri_unempl so that correct answer range is +/- .5 percentage point (to reduce % correct)
					recode l2 4.3/5.3=1 0/4.2=0 5.4/100=2, gen(tri_unempl2)
					label val  tri_unempl2 tri
					
				** Payout recode
					recode l2 3.8/5.8=1 0/3.7=0 5.9/100=2, gen(tri_unempl_payout)
					label val  tri_unempl2 tri
					
				** 23% recode
					recode l2 4.6/5.0=1 0/4.5=0 5.1/100=2, gen(tri_unempl23)
					label val  tri_unempl23 tri
				
				** 33% recode
					recode l2 4.2/5.4=1 0/4.19=0 5.41/100=2, gen(tri_unempl33)
					label val  tri_unempl33 tri
				
				** +/-10% recode
					recode l2 4.32/5.28=1 0/4.31=0 5.29/100=2, gen(tri_unempl10)
					label val  tri_unempl10 tri
		
			* Uninsured
				recode l3 13.8/17.8=1 0/13.7 =0 17.9/100 =2, gen(tri_health)
				label val  tri_health tri
				
				** 23% recode
					recode l3 13.59/17=1 0/13.5=0 17.01/100=2, gen(tri_health23)
					label val  tri_health23 tri
				
				** 33% recode
					recode l3 12.6/19=1 0/12.59=0 19.01/100=2, gen(tri_health33)
					label val  tri_health33 tri
					
				** +/-10% recode
					recode l3 14.22/17.38=1 0/14.21=0 17.39/100=2, gen(tri_health10)
					label val  tri_health10 tri
			
			* Gas
				recode l5 3.17/3.37=1 0/3.16 = 0 3.38/20 = 2, gen(tri_gas)
				replace tri_gas = 2 if tri_gas > 1
				replace tri_gas = 0 if tri_gas < 0
				label val  tri_gas tri
				
				* Trichotomous coding such that ~30% of sample within CORRECT answer range
					recode l5r 3.22/3.32=1 0/3.21 = 0 3.33/100 = 2, gen(tri_gasr_corr_st) /*33% correct*/
					label val  tri_gasr_corr_st tri
				
				* Payout coding
					recode l5r 3.17/3.37=1 0/3.16 = 0 3.38/100 = 2, gen(tri_gas_payout)
					label val  tri_gasr_corr_st tri
			
				** 23% recode
					recode l5r 3.25/3.29=1 0/3.24=0 3.3/100=2, gen(tri_gas23)
					label val  tri_gas23 tri
					
				** 33% recode
					recode l5r 3.22/3.32=1 0/3.21=0 3.33/100=2, gen(tri_gas33)
					label val  tri_gas33 tri
					
				** 10% recode
					recode l5r 2.943/3.597=1 0/2.942=0 3.598/100=2, gen(tri_gas10)
					label val  tri_gas23 tri
			
		* Create PID Dummies
			tabulate pid3, generate(pidum)
			recode pid7 1/3=1 4=2 5/7=3, gen(pid3a)
			
			recode pid7 7=1 1/6=0, gen(stdem)
			recode pid7 1=1 2/7=0, gen(strep)
			recode pid7 6=1 2/5=0 7=0, gen(wkdem)
			recode pid7 2=1 3/7=0 1=0, gen(wkrep)
			recode pid7 3=1 4/7=0 1/2=0, gen(lnrep)
			
		* Bartels PID
			gen strpid 	   = pid7
			replace strpid = .   if pid7==4
			replace strpid = 1   if pid7==7
			replace strpid = -1  if pid7==1
			replace strpid = 0   if pid7==2 | pid7==3 | pid7==5 | pid7==6
			
			gen weakpid = pid7
			replace weakpid = .  if pid7==4
			replace weakpid = -1 if pid7==2
			replace weakpid =  1 if pid7==6
			replace weakpid = 0  if pid7==1 | pid7==3 | pid7==5 | pid7==7
			
			gen leanpid = pid7
			replace leanpid = .  if pid7==4
			replace leanpid = -1 if pid7==3
			replace leanpid =  1 if pid7==5
			replace leanpid = 0  if pid7==1 | pid7==2 | pid7==6 | pid7==7
			
			* Markus lean pid
			gen mleanpid = pid7
			replace mleanpid = .  if pid7==4
			replace mleanpid = 1  if pid7==3
			replace mleanpid = 0  if pid7==1 | pid7==2 | pid7==5 | pid7==6 | pid7==7
			
			** New PID3 variable including independent leaners as partisans **
			gen pid3lean = .
			replace pid3lean = 1 if pid7 < 4
			replace pid3lean = 2 if pid7 == 4
			replace pid3lean = 3 if pid7 > 4 & pid7 <= 7
			label val pid3lean pid3

			/*Recode PID7 to be from 0-6*/
			gen pid7new = pid7 - 1
			
		* create Dem_ConB, Ind_ConB, Rep_ConB, Rep_ProB,  (drop all others)
			gen pid_app = 1 if pid3a==3 & approved==0
			replace pid_app = 2 if pid3a==2 & approved==0
			replace pid_app = 3 if pid3a==1 & approved==0
			replace pid_app = 4 if pid3a==1 & approved==1
				label define pid_app 1 "Dem, disapproves Bush" 2 "Pure Ind, disapproves Bush" 3 "Rep, disapproves Bush" 4 "Rep, approves Bush"
				label val pid_app pid_app

	* Bush Ref and Bush Loc Interaction
	gen refloc = 2 if r_bushref==1 & r_PIDloc==1 
	replace refloc =  1 if ((r_bushref ==0 & r_PIDloc ==1) | (r_bushref ==1 & r_PIDloc ==0))
	replace refloc =  0 if r_bushref ==0 & r_PIDloc ==0
		label define refloc 2 "Double Bush" 1 "Single Bush" 0 "No Bush"
		label val refloc refloc
	
	*Interacting num/voc/know with treatments
		gen knowloc  = kn_gen*r_PIDloc
		gen numloc   = num*r_PIDloc						 
		gen vocloc   = voc*r_PIDloc
		
		gen knowref  = kn_gen*r_bushref
		gen numref   = num*r_bushref				 
		gen vocref   = voc*r_bushref
		
		gen knowrefloc  = kn_gen*refloc
		gen numrefloc   = num*refloc					 
		gen vocrefloc   = voc*refloc
		
		gen knowrd	    = kn_gen*(rd==2)
		gen numrd  	 	= num*(rd==2)				 
		gen vocrd   	= voc*(rd==2)

** Create numerical skills scale from 0 to 3 **
	gen h1a_test = 0
	gen h1b_test = 0
	gen h1c_test = 0

	replace h1a_test = 1 if h1a == 500
	replace h1b_test = 1 if h1b == 10
	replace h1c_test = 1 if h1c == 20

	gen num_scale = h1a_test + h1b_test + h1c_test
	tab num_scale

** Construct vocabulary scale **
	gen n1_1_test = 0
	replace n1_1_test = 1 if n1_1 == 4

	gen n1_3_test = 0
	replace n1_3_test = 1 if n1_3 == 5

	gen n1_5_test = 0
	replace n1_5_test = 1 if n1_5 == 1

	gen n2_1_test = 0
	replace n2_1_test = 1 if n2_1 == 3

	gen n2_2_test = 0
	replace n2_2_test = 1 if n2_2 == 2

	gen n2_3_test = 0
	replace n2_3_test = 1 if n2_3 == 4

	gen n2_4_test = 0
	replace n2_4_test = 1 if n2_4 == 4

	gen n2_5_test = 0
	replace n2_5_test = 1 if n2_5 == 1

	gen vocab_scale = n1_1_test + n1_3_test + n1_5_test + n2_1_test + n2_2_test + n2_3_test + n2_4_test + n2_5_test
	tab vocab_scale

*** Cable Knowledge
*** Multiple things happening: 
	* Names, Pictures, Names and Pictures
		* IF RM=1: show names
		* IF RM=2: show pictures
		* IF RM=3: show names AND pictures

	* Diff. Anchors
		* IF RL=1:
		* [randomize order]
		* John Roberts, Joe Scarborough, Sanjay Gupta, Bill Hemmer

		* IF RL=2:
		* [randomize order]
		* Sean Hannity, Jack Cafferty, Christine Romans, Shepard Smith
		
		gen cablepk = anch_roberts + anch_scarb + anch_gupta + anch_hemmer
		replace cablepk = anch_hannity + anch_cafferty + anch_romans + anch_smith if rl==2
		
		tab cablepk rl
		tab cablepk rm
		
 *General Knowledge by trichotomize
 	gen tripk = kn_tote
	replace tripk = 0 if kn_tote <=7
	replace tripk = .5 if kn_tote <= 11 & kn_tote > 7
	replace tripk = 1 if kn_tote > 11

* Save file
	save "H:\PartisanInferencePaper\data\KN2008.merged.recoded.dta", replace
