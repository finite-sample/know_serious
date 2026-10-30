** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **
**									    	**								
**  Partisan Inference Analyses			
**  Last Edited: 4/07/2013 by GS		
**  Analyses: KN 2004 Hier off common subset
**											
** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  **
 
* Set Library Location for finding survwgt (Leave it for GS)
	sysdir set PLUS "\\files\dept\WWS\Research\MPRIOR\stata\"
	* ssc install gllamm

	* 2004 subset
		*keep if time==0 & pid7 ~= 4  
		*gllamm tri_dv pay, i(caseid) link(ologit)
		
	* taking out poor
		use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
			
		* Fixing Bushref (as KN 2004 debt bushref is 1)
			gen nbushref = r_bushref
			replace nbushref = 1 if mod(_n+2, 5) == 0
			
		* Subset
			keep if pollid==2004 & time==0 & pid7~=4
			drop tri_dv1 tri_dv2 tri_dv3 tri_dv4 tri_dv5 tri_dv10 pct_dv1 pct_dv2 pct_dv3 pct_dv4 pct_dv5 pct_dv10 raw_dv1 raw_dv2 raw_dv3 raw_dv4 raw_dv5 raw_dv10
			*drop tri_dv1 tri_dv2 tri_dv3 tri_dv4 tri_dv5 pct_dv1 pct_dv2 pct_dv3 pct_dv4 pct_dv5 raw_dv1 raw_dv2 raw_dv3 raw_dv4 raw_dv5 
			
		* Reshape
			reshape long tri_dv pct_dv raw_dv, i(caseid)
		
		* for item level r.e.
			gen seq = mod(_n-1,4) + 1
			
		* for item level f.e
			gen seq1=1 if seq==1
			replace seq1=0 if seq~=1
				
			gen seq2=1 if seq==2
			replace seq2=0 if seq~=2
				
			gen seq3=1 if seq==3
			replace seq3=0 if seq~=3
	
			gen seq4=1 if seq==4
			replace seq4=0 if seq~=4
			
		* Percentile 
			gllamm pct_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4, i(caseid)
			reg pct_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4, cluster (caseid)
		* raw
			gllamm raw_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4, i(caseid)
			reg raw_dv pay pid3b payXpid3b seq1 seq2 seq3 seq4, cluster (caseid)
		
		* Running Models
			* Dummy Model
				gllamm tri_dv pay stdem strep wkdem wkrep lnrep payXstdem payXstrep payXwkdem payXwkrep payXlnrep, i(caseid) link(ologit) 
			
			* pid3 (pg. 18)
				gllamm tri_dv pay pid3b payXpid3b, i(caseid) link(ologit) adapt
			
			* Bartels' PID Reg. (pg. 50)
				gllamm tri_dv pay strpid leanpid weakpid payXstrpid  payXweakpid payXleanpid, i(caseid) link(ologit)
				
				* With Markus lean
				gllamm tri_dv pay strpid mleanpid weakpid payXstrpid  payXweakpid payXmleanpid, i(caseid) link(ologit)	
		
			* PID 7 (without bushref) (pg. 17)
				gllamm tri_dv pay pid7 payXpid7, i(caseid) link(ologit) 

			* PID 7 with bushref
				gllamm tri_dv pay pid7 payXpid7 nbushref, i(caseid) link(ologit) 
			
		* mlogit (no real individual level clustering)
			gllamm tri_dv pay pid3b payXpid3b, i(caseid) link(mlogit) basecategory(0)
			mlogit tri_dv pay pid3b payXpid3b, base(0)
				
			* Exploring item level
				* Using fixed effects via ologit
					ologit tri_dv pay pid3b payXpid3b i.seq, cluster(caseid)
					*mlogit tri_dv pay pid3b payXpid3b i.seq, cluster(caseid) base(0)
					
				* with item level random effects only 			
					gllamm tri_dv pay pid3b payXpid3b, i(seq) link(ologit)
				
				* with item level fixed effects
					gllamm tri_dv pay pid3b payXpid3b seq1 seq2 seq3, i(caseid) link(ologit)
					* gllamm tri_dv pay pid3b payXpid3b seq1 seq2 seq3, i(caseid) link(mlogit)
					
				* item level re (something funky happens so investigate)
					gllamm tri_dv pay pid3b payXpid3b, i(seq caseid) link(ologit) 
				
			* Education, PK, Polint pg. 24, 25
				* Create some vars
					gen pid3bXedu = pid3b*ppeducat
					gen payXpid3bXedu = pay*pid3b*ppeducat
					gen pid3bXpk = pid3b*kn_tote
					gen payXpid3bXpk = pay*pid3b*kn_tote
				
				* Add edu
					gllamm tri_dv pay pid3b ppeducat payXpid3b payXedu pid3bXedu payXpid3bXedu, i(caseid) link(ologit)
			
				* Add kn_tote
					gllamm tri_dv pay pid7 kn_tote payXpid7 payXpk pid7Xpk payXpid7Xpk, i(caseid) link(ologit)
					gllamm tri_dv pay pid3b kn_tote payXpid3b payXpk pid3bXpk payXpid3bXpk, i(caseid) link(ologit)
					
				* Add polint
					gllamm tri_dv pay pid7 polint payXpid7 payXint pid7Xint payXpid7Xint, i(caseid) link(ologit)
			
				* The full monty
					gllamm tri_dv pay pid7 ppeducat kn_tote polint payXpid7 pid7Xpk pid7Xedu payXedu payXpk payXpid7Xedu payXpid7Xpk payXpid7Xint, i(caseid) link(ologit)
			
			* Subsets
				* Whites only, pg. 20
					use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
					keep if pollid==2004 & time==0 & pid7~=4
					drop tri_dv1 tri_dv2 tri_dv3 tri_dv4 tri_dv5 tri_dv10
					keep if white==1
					reshape long tri_dv, i(caseid)
					gllamm tri_dv pay pid3b payXpid3b, i(caseid) link(ologit) 
					
				* Rs only (if you subset on whites, it works even better)
					use "H:\PartisanInferencePaper\data\KN0408.hier.merge.dta", clear
					keep if pollid==2004 & time==0 & pid7~=4
					drop tri_dv1 tri_dv2 tri_dv3 tri_dv4 tri_dv5 tri_dv10
					keep if pid7 < 4
					*keep if pid7 < 4 & white==1
					reshape long tri_dv, i(caseid)
					gllamm tri_dv pay, i(caseid) link(ologit)
				

