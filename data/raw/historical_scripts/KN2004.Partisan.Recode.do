** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **
**
**  KN 2004
**  Partisan Inference Recode
**  Last Edited: 4/01/2013 by GS
**											
** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **

* Load data
	use "H:\PartisanInferencePaper\data\PriorLupia2004\PriorLupia20004.surveydata.dta", clear
	
	* Hispeed
		recode inet_sp 2=0 0 1=1, gen(nohispeed)
	
	 * Lone adult
		recode others 0=1 1/2=0, gen(alone)
				
	* Time and Pay
		recode ex_group (2 4=1) (1 3=0), gen(time)
		recode ex_group (3 4=1) (1 2=0), gen(pay)
		gen timeXpay = time*pay

	* Tri Label
		label define trir 1 "Cor" 0 "Less" 2 "Great"	
	
	* Q12: Not included: Taxes in US compared to Europe
		tab  ek1_euro  ex_group, nof col
		recode q12 -2 -1=. 1=3 2=1 3=2, gen(q12a)
		
	* Q13: Unemployment rate
		tab  ek2_empl  ex_group, nof col
		recode q13 (5=3) (4=5) (3=7) (2=9) (1=11) (-1=.) (-2=.), gen(q13a)
		recode q13 (-2=.), gen(q13b)
		replace q13b = round(uniform()*5-.5)+1 if q13b==-1
		recode q13b (5=3) (4=5) (3=7) (2=9) (1=11)
		gen q13_devsq=-abs(q13a-5)^2
		
		recode q13 5=0 4=1 1/3=2 -2 -1=., gen(tri_unempl)
		label val  tri_unempl trir
		
		recode q13 (5=3) (4=5) (3=7) (2=9) (1=11) (-1=.) (-2=.), gen(dev_unempl)
		
	* Q14: Estate Tax	
		tab  ek3_esta  ex_group, nof col
		recode q14 (5=5) (4=25) (3=50) (2=75) (1=95) (-1=.) (-2=.), gen(q14a)
		recode q14 (-1=.) (-2=.), gen(q14b)
		replace q14b = round(uniform()*5-.5)+1 if q14==-1
		recode q14b (5=5) (4=25) (3=50) (2=75) (1=95)
			
		recode q14 (5=5) (4=25) (3=50) (2=75) (1=95) (-1=.) (-2=.), gen(dev_estate)
		
		recode dev_estate 5=1 25/95=2, gen(tri_estate)
		label val  tri_estate trir
		
	* Q16: Debt
		tab  ek5_debt  ex_group, nof col
		bysort pid3: tab  ek5_debt  ex_group, col
		bysort pid3a: tab  q16  ex_group if q16~=-2, col

		recode q16 1=3.5 2=4.5 3=5.5 4=6.5 5=7.5 6=8.5 7=9.5 -1 -2=., gen(q16a)
		gen q16b = q16a
		replace q16b = round(uniform()*7-.5)+3.5 if q16==-1
		
		recode q16 5=1 6 7=2 1/4=0 -2 -1=., gen(tri_debt)
		label val  tri_debt trir
		recode q16 1=3.5 2=4.5 3=5.5 4=6.5 5=7.5 6=8.5 7=9.5 -1 -2=., gen(dev_debt)
		
	* Q15: Uninsured Americans
		tab  ek4_hea1  ex_group, nof col
		bysort pid3: tab  ek4_heal  ex_group, col

		recode q15 0/15.5=0 15.6=1 15.7/100=2 101/2000=3 -2=., gen(ek4_hea_dir)
		bysort pid3: tab  ek4_hea_dir  ex_group, col
	
		recode q15 (-1 770 1110=.) (-2=.), gen(q15a)
		gen q15b = q15a
		replace q15b = round(uniform()*101-.5) if (q15==-1 | q15==770 | q15==1110)
			
		recode q15 (-1 770 1110=.) (-2=.), gen(dev_unins)
		* tricho
			* based on AJPS
			* recode l3 13.8/17.8=1 0/13.7 =0 17.9/100 =2, gen(tri_health)
				recode q15 0/9.5=0 9.6/21.6=1 21.7/100=2 101/2000 -2 -1 =., gen(tri_unins)
				label val  tri_unins trir
			
			* based on 2008 (+-1, +-2, +-4)
				recode q15 0/11.5=0 11.6/19.6=1 19.7/100=2 101/2000 -1 -2=., gen(tri_unins4)
				label val  tri_unins4 trir
				
				recode q15 0/13.5=0 13.6/17.6=1 17.7/100=2 101/2000 -1 -2=., gen(tri_unins2)
				label val  tri_unins2 trir
				
				recode q15 0/14.5=0 14.6/16.6=1 16.7/100=2 101/2000 -1 -2=., gen(tri_unins1)
				label val  tri_unins1 trir
			
			* Payout
				recode q15 0/12.59=0 12.6/18.6=1 18.61/100=2 101/2000 -1 -2=., gen(tri_unins_payout)
				label val tri_unins_payout trir
			
			* Recode by 23% 
				recode q15 0/6.59=0 6.6/24.6=1 24.61/100=2 101/2000 -2 -1 =., gen(tri_unins23)
				label val  tri_unins23 trir
			
			* Recode by 33%
				recode q15 0/1.99=0 2/29.2=1 29.21/100=2 101/2000 -2 -1 =., gen(tri_unins33)
				label val  tri_unins33 trir
			
			* Recode by +/- 10%
				recode q15 0/14.03=0 14.04/17.16=1 17.17/100=2 101/2000 -2 -1 =., gen(tri_unins10)
				label val  tri_unins10 trir
						
	* Q18: Poverty
		tab  ek7_poor  ex_group, nof col
		bysort pid3: tab  ek7_poor  ex_group, col

		recode q18 0/12.4=0 12.5=1 12.6/100=2 -2=., gen(ek7_poor_dir)
		bysort pid3: tab  ek7_poor_dir  ex_group, col

		recode q18 (-1=.) (-2=.), gen(q18a)
		gen q18b = q18a
		replace q18b = round(uniform()*101-.5) if q18a==-1
		
		recode q18 (-1=.) (-2=.), gen(dev_poor)
		
		* Based on AJPS
			recode q18 0/6.4=0 6.5/18.5=1 18.6/100=2 -1 -2=., gen(tri_poor)
			label val  tri_poor trir
			
		* Based on 2008 (+-1 and +-2)
			recode q18 0/10.4=0 10.5/14.5=1 14.6/100=2 -1 -2=., gen(tri_poor2)
			label val  tri_poor2 trir

			recode q18 0/11.4=0 11.5/13.5=1 13.6/100=2 -1 -2=., gen(tri_poor1)
			label val  tri_poor1 trir

		* Point Estimate
			recode q18 0/12.4=0 12.5=1 12.6/100=2   -1 -2=., gen(tri_poorp)
			label val tri_poorp trir
		
		* Payout
			recode q18 0/9.49=0 9.5/15.5=1 15.51/100=2 -1 -2=., gen(tri_poor_payout)
			label val tri_poor_payout trir
			
		* Recode by 23% 
			recode q18 0/6.49=0 6.5/18.5=1 18.51/100=2 -1 -2=., gen(tri_poor23)
			label val  tri_poor23 trir
			
		* Recode by 33% 
			recode q18 0/4.49=0 4.5/20.5=1 20.51/100=2 -1 -2=., gen(tri_poor33)
			label val  tri_poor33 trir
			
		* Recode by +/-10% 
			recode q18 0/11.24=0 11.25/13.75=1 13.76/100=2 -1 -2=., gen(tri_poor10)
			label val  tri_poor10 trir
		
		* Percentile coding
			egen n = count(q13a)
			egen rank_unempl  = rank(q13a) 
			gen  pct_unempl   = (rank_unempl - .5)/n
			drop n
			
			gen q14r = -1*q14a
			egen n = count(q14r)
			egen rank_estate  = rank(q14r) 
			gen  pct_estate   = (rank_estate - .5)/n
			drop n
			
			egen n = count(q16a)
			egen rank_debt  = rank(q16a) 
			gen  pct_debt   = (rank_debt - .5)/n
			drop n
			
			recode q15 -1 -2=. , gen(q15na)
			egen n = count(q15na)
			egen rank_unins  = rank(q15na) 
			gen  pct_unins    = (rank_unins - .5)/n
			drop n
			
			recode q18 -1 -2=. , gen(q18na)
			egen n = count(q18na)
			egen rank_poor  = rank(q18na) 
			gen  pct_poor   = (rank_poor - .5)/n
			drop n

		* Raw coding
			gen raw_unempl	= (q13a -3)/8
			gen raw_estate	= ((5 - q14a)/90) + 1
			gen raw_debt	= (q16a -3.5)/6
			recode q15na 101/1110=., gen(q15nar)
			gen raw_uninsr	= (q15nar)/100
			gen raw_poor	= q18na/99
			
*** Stop Here -- Don't include Kerry item
	
	* Q17: Kerry tax cut
		tab  ek6_tax  ex_group, nof col
		bysort pid3: tab  ek6_tax  ex_group, col
		bysort pid3a: tab  q17  ex_group if q17~=-1, col

		recode q17 (5=500) (4=200) (3=150) (2=100) (1=50) (-1 -2=.), gen(q17a)
		recode q17 (-2=.), gen(q17b)
		replace q17b = round(uniform()*5-.5)+1 if q17==-1
		recode q17b (5=500) (4=200) (3=150) (2=100) (1=50) (-1 -2=.)
		
		recode q17 (5=500) (4=200) (3=150) (2=100) (1=50) (-1 -2=.), gen(dev_kerry)
		recode dev_kerry 200=1 500=2 50/150=0, gen(tri_kerry)
		

********************************************************************
		
		* Political Interest
			recode polint 0 1=0 2 3=1, gen (polint2)
			recode polint 0 1=0 2=1 3=2, gen (polint3)
			recode q4 -2=. -1 3 4=0 2=1 1=2, gen (polint3_ms)
			recode q4 -2=. -1 4=0 3=1 2=2 1=4, gen (polint4_ms)
			recode polint3_ms 0 2=0 1=1, gen (polint3_ms_md)
			recode polint3_ms 0 1=0 2=1, gen (polint3_ms_hi)
		
		* Political Knowledge on other items
			recode pk1_ter2 6=1 4 8=.5 2=.25 0 1 3 5 7 9/45=0, gen(info1)
			recode pk2_sen2 51=1 52/59=.5 60/80=.25 81/999=0 0/25=0 26/50=.25, gen(info2)
			gen info = info1 + info2 + pk3_2000 + pk6_veto
			recode info 0/1.75=0 2/4=1, gen(infod)
			replace infod=0 if info==2 & ex_group==3
			replace infod=. if ex_group==2
			replace infod=. if ex_group==4
			
		* Voted
			recode q1 -2=. -1 1 2 3=0 4=1, gen (voted02_ms)
		
		* PID
			recode pid3 1=1 2 3=0, gen(rep)
			recode pid3 1 2=0 3=1, gen(dem)
			recode pid3 1 3=0 2=1, gen(ind)
						
			recode pid7 7=1 1/6=0, gen(stdem)
			recode pid7 1=1 2/7=0, gen(strep)
			recode pid7 6=1 2/5=0 7=0, gen(wkdem)
			recode pid7 2=1 3/7=0 1=0, gen(wkrep)
			recode pid7 3=1 4/7=0 1/2=0, gen(lnrep)
			
			recode pid7 1=0 7=0 2/6=1, gen(stind)
			recode pid7 5/7=0 1/3=0 4=1, gen(ind1)
			recode pid7 5/7=1 1/4=0, gen(dem1)
			recode pid7 1/3=1 4/7=0, gen(rep1)
			
			recode pid7 1=0 2=1 3=1 4=. 5=2 6=2 7=3, gen(pid5)

			recode pid7 1 7=3 2 6=2 3 5=1 4=0., gen(pidstr)
			/*Recode PID7 to be from 0-6*/
			gen pid7new = pid7 - 1
		
		* Bartels PID
			gen strpid = pid7
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
			
			
		* Demographics		
			* Education
				recode edu 1 2=0 3=1 4=2 5 6=3, gen (edu4)
				recode edu 1 2=0 3 4 5 6=1, gen (hs_plus)
				recode edu 1 2=0 3=1 4 5 6=0, gen (hs_only)
				recode edu 1 2 3=0 4=1 5 6=0, gen (some_college)
				recode edu 1 2 3 4=0 5 6=1, gen (college_degree)
			
			* same coding as KN 2008 (less than HS, HS, Some college, BS or above)
			*recode ppeduc 1 2 =1 3=2 4 5 =3 6 7 8 9= 4, gen(ppeducatr)
				
			* Age
				recode ppagect4 1/3=0 4=1, gen(senior)
				recode ppagect4 1=1 2/4=0, gen(young)	
				recode age 18/34=1 35/100=0, gen(age18_34)
				recode age 18/34=0 35/44=1 45/100=0, gen(age35_44)
				recode age 18/44=0 45/59=1 60/100=0, gen(age45_59)
				recode age 18/59=0 60/100=1, gen(age60_)
				recode age 18/34=1 35/59=2 60/100=3, gen(age3)
				recode age 18/34=1 35/44=2 45/59=3 60/100=4, gen(age4)

				recode female 0=1 1=0, gen(male)
				recode others 0=0 1 2=1, gen(others1)
				recode income 1/7=1 8/10=2 11/13=3 14/19=4, gen(income4)
				recode white 0=1 1=0, gen(minority)
				recode pprent 1=1 2/3=0, gen(homeown)
			
			* Internet and Computer
				recode inet .=0 0=0 1=1, gen(inet_ms)
				recode inet_sp 0 1=0 2=1, gen(broadb)
				recode inet_sp 0=0 1=1 2=0, gen(dialup)
				recode q24 -2 -1=. 1=0 2/6=1, gen(ownscomp)
		
			* Children
				gen children = ppt01 + ppt25 + ppt612 + ppt1317
				drop child
				recode children 0=0 1/7=1, gen (child)
				recode children 0=0 1=1 2=2 3/7=3, gen (children3)
		
			* Employed
				replace employ=1 if ppwork==4

				recode cu30offp -2=0 7=1 6=2 5=3 4=4 3=5 2=6 1=7 -1=., gen(ecom)
				recode ecom 0=0 1/3=1 4/7=2, gen(ecom3)
				recode mbr_pane 0/11=0 12/43=1 44/60=2, gen(tenure3)

			* tripk
				gen tripk = .
							 
* Save file
	save "H:\PartisanInferencePaper\data\KN2004.recoded.dta", replace
