/*******************************************************************************
		     	Article: Emergency Aid for Self-Employed in the COVID-19 
							Pandemic: A Flash in the Pan? 
							
published in: Journal of Economic Psychology, 2022, 93(102567).
authors: Joern Block, Alexander S. Kritikos, Maximilian Priem, Caroline Stiel	
affiliations: Trier University, DIW Berlin, DIW-Econ		
				
********************************************************************************
													                 
																	 Do-File 04
							
							TREATMENT EFFECTS ANALYSIS
							
		CONTENT:	Propensity Score Matching and Treatment Effects Analysis
		
		OUTLINE:	PART 1: Definitions
					PART 2: Kernel Matching
					PART 3: Heterogeneous Effects Analysis
					PART 4: Nearest Neighbor Matching (Robustness Checks)

					
--------------------------------------------------------------------------------
code authors: Maximilian Priem (DIWecon), Caroline Stiel (DIW Berlin)
version: 11-Feb-2021 (v08)
--------------------------------------------------------------------------------
	
*******************************************************************************/

* define dates and time etc.
* -------------------------- 
local date=ltrim("$S_DATE")
local date=subinstr("`date'"," ","_",2)

* start logfile
* -------------
cap log close
log using "$results\log_Matching_`date'.log", replace


/*******************************************************************************
						PART 1: Definitions
*******************************************************************************/

*================================*
* 1.1 covariates for PSM
*================================*

* main model
* ----------
global attitudes "ib2.risk_c"
global crisisdem "i.running_cost_2 ib1.Hoehe_Umsatzrueckgang_2 ib1.solvency_firm dig_vor_corona Durststrecke3" 
global sociodem "se_full_time i.gender ib3.age_cat ib2.edu_cat ib2.location_DE i.Plan_AG2b week_quest" 
global busidem "ib2.duration_se ib1.industry_nace solo_solo" 

* heterogeneity analysis
* ----------------------
global sociodem_edu "se_full_time i.gender ib3.age_cat  ib2.location_DE i.Plan_AG2b week_quest" 

* robustness checks
* -----------------
global staatl_Unt "staatl_Unt_2t6"



*======================================*
* 1.2 number of bootstrap replications
*======================================*

* bootstrap replications
* ----------------------
global reps 1999



*================================*
* 1.3 Set input and output files
*================================*

* load data
* ---------
use "$input\Datensatz_Variables_v03.dta", clear

* set output file
* ---------------
global outfile "EmergencyAid_Matching_1999reps.xlsx"



*=====================*
* 1.4 outcome variable
*=====================*

* outcome variable in main analysis
* ---------------------------------
* binary variable
global depvar survival_di2 

* outcome variable in robustness checks
* --------------------------------------
* ordinal outcome variable
* global depvar optimism



/*******************************************************************************
						PART 2: PSM & ATT for main model
*******************************************************************************/

*==============================================================================*	
* 2.1 Main model without trimming
*==============================================================================*

* prepare output file
* -------------------
putexcel set "$results/$outfile", modify sheet("Kernel Matching")
	putexcel C2 = "main model"
	putexcel C3 = "ATE"
	putexcel D3 = "ATT"
	putexcel B4 = "coef."
	putexcel B5 = "SE"
	putexcel B6 = "p-value"	
	putexcel B7 = "bs replications"
	putexcel B8 = "N matched"
	putexcel B9 = "N out of common support"
	putexcel B10 = "N total"
	putexcel B11 = "min"
	putexcel B12 = "max"

	
* do PSM Kernel matching
* ----------------------
kmatch ps Masn_e2 $sociodem $attitudes $crisisdem $busidem   ///
($depvar) if sampleT==1, ate att  pscmd(probit) ///
vce(bootstrap, rep($reps)) bwidth(cv) kernel(epan) 

* save results as matrix
* ----------------------
mat define M1=r(table)

* extract ATE, ATT
* --------------
mat M2 = M1[1,1..2]
mat list M2

* extract standard errors
* -----------------------
mat M3 = M1[2,1..2]
mat list M3

* extract p-value
* ---------------
mat M4 = M1[4,1..2]
mat list M4

* save all results as .xls
* -------------------------
putexcel set "$results/$outfile", modify sheet("Kernel Matching")
putexcel C4 = mat(M2)
putexcel C5 = mat(M3)
putexcel C6 = mat(M4)

* number of bootstrap replications
* ---------------------------------
putexcel C7= `e(N_reps)'

* number of matched observations
* ------------------------------
mat list e(_N)
mat define M5 = e(_N)
mat M5 = M5[3,1]
putexcel C8 = mat(M5) 
             
* number of observations
* ----------------------
putexcel C10= `e(N)'	
	
	
	
*==============================================================================*	
* 2.2 Main model with trimming
*==============================================================================*	

* -----------------------------------------------
* Tables 4 and 5: ATT and ATE for the main sample
* -----------------------------------------------

* clean
* -----
cap: drop _KM_* 
scalar drop _all
matrix drop _all

* prepare output file
* -------------------
putexcel set "$results/$outfile", modify sheet("Kernel Matching")
putexcel E2 = "main model with (min,max) trimming"
putexcel E3 = "ATE"
putexcel F3 = "ATT"
putexcel G2 = "main model with (min,.95) trimming"
putexcel G3 = "ATE"
putexcel H3 = "ATT"

*==============================================================================*	
* 2.2.1 Obtain trimming interval
*==============================================================================*

* run initial PSM to obtain boundaries for trimming (min/max)
* -----------------------------------------------------------
kmatch ps Masn_e2 $sociodem $attitudes $crisisdem $busidem  ///
($depvar) if sample==1 , ate att  pscmd(probit) ///
bwidth(cv) kernel(epan)  gen(_KM_)

* Propensity score distribution of treatment group
* ------------------------------------------------
sum _KM_ps if Masn_e2==1, detail 
scalar sc_min1 = r(min)
scalar sc_max1 = r(max)
		
* Propensity score distribution of control group
* ----------------------------------------------
sum _KM_ps if Masn_e2==0, detail 
scalar sc_min2 = r(min)
scalar sc_max2 = r(max)

* choose lower bound as max(min treat, min control)
* ------------------------------------------------
if ( sc_min1 < sc_min2){
	local GMps_min = sc_min2
	}
	else{
		local GMps_min = sc_min1
		}

* choose upper bound as min(max treat, max control)
* ------------------------------------------------
if ( sc_max1 < sc_max2){
	local GMps_max = sc_max1
	}
	else{
		local GMps_max = sc_max2
		}
		
* display and save trimming boundaries
* ------------------------------------
display `GMps_min'		
display `GMps_max'
		

*==============================================================================*	
* 2.2.2 Run model with trimmed PSM distribution
*==============================================================================*

* do trimmed kernel PSM matching with endogenous boundaries
* ---------------------------------------------------------		
kmatch ps Masn_e2 $sociodem $attitudes $crisisdem $busidem   ///
($depvar) if sample==1, ate att comsup(`GMps_min' `GMps_max') pscmd(probit) ///
vce(bootstrap, rep($reps)) bwidth(cv) kernel(epan)		

* loop through two different max boundaries: GMps_max and .95
* -----------------------------------------------------------
local b  E G  
foreach a of numlist  `GMps_max' 0.95  {
		gettoken left b: b 
		display "`left'" 
		display "`b'" 

		* do trimmed kernel PSM matching
		* -------------------------------	
		kmatch ps Masn_e2 $sociodem $attitudes $crisisdem $busidem  ///
		($depvar) if sample==1, ate att comsup(`GMps_min' `a') pscmd(probit) ///
		vce(bootstrap, rep($reps)) bwidth(cv) kernel(epan) 

		* save results as matrix
		* ----------------------
		mat define M1=r(table)

		* extract ATE, ATT
		* --------------
		mat M2 = M1[1,1..2]
		mat list M2

		* extract standard errors
		* -----------------------
		mat M3 = M1[2,1..2]
		mat list M3

		* extract p-value
		* ---------------
		mat M4 = M1[4,1..2]
		mat list M4
			
		* save all results as .xls
		* ------------------------ 
		putexcel set "$results/$outfile", modify sheet("Kernel Matching")
			
		putexcel `left'4= mat(M2)
		putexcel `left'5= mat(M3)
		putexcel `left'6= mat(M4)
		
		* number of bootstrap replications
		* ---------------------------------
		putexcel `left'7= `e(N_reps)'

		* number of matched observations
		* ------------------------------
		mat list e(_N)
		mat define M5 = e(_N)
		mat M5 = M5[3,1]
		putexcel `left'8 = mat(M5) 
		
		* number of observations trimmed (out of common support)
		* -------------------------------------------------------
		putexcel `left'9 = `e(N_outsup)'
        
		* number of observations
		* ----------------------
		putexcel `left'10= `e(N)'
		
		* lower and upper bound
		* ---------------------
		putexcel `left'11= `GMps_min'
		putexcel `left'12=`a'

		}

		
		
*==============================================================================*	
* 2.3 Matching quality (main model)
*==============================================================================*

*==============================================================================*
* 2.3.1 t-tests for trimmed model
*==============================================================================*

* -------------------------------------
* Table A3 (Appendix): Matching quality
* -------------------------------------

* prepare output file
* --------------------
putexcel set "$results/$outfile", modify sheet("Matching_Quality")
putexcel B2 = "Matching Quality: Kernel Matching (Min/Max Trimming)"
putexcel C3 = "Before matching"
putexcel D3 = "After matching"

* do again PSM kernel matching for trimmed model
* ----------------------------------------------
cap: drop _KM_*
kmatch ps Masn_e2 $sociodem $attitudes $crisisdem $busidem  ///
($depvar) if sample==1, ate att  pscmd(probit) ///
bwidth(cv) kernel(epan) comsup(`GMps_min' `GMps_max') gen(_KM_) //vce bootstrap nicht mit gen kompatibel 

* t-Test, standardised percentage bias
* ------------------------------------
pstest $sociodem $attitudes $crisisdem $busidem  ///
, mweight(_KM_mw) treated(Masn_e2) label both 
return list 

* save results
* ------------
putexcel set "$results/$outfile", modify sheet("Matching_Quality")
local B = r(Baft)
local B2 = r(Bbef)
local R = r(Raft)
local R2 = r(Rbef)
local M = r(medbiasaft)
local M2 = r(medbiasbef)
local P = r(r2bef)
local P2 = r(r2aft)

putexcel B17 = "Rubins B in %"
putexcel C17 = `B2'
putexcel D17 = `B'

putexcel B18 = "Rubins R"
putexcel C18 = `R2'
putexcel D18 = `R'

putexcel B14 = "Mean absolute standardized bias in %"
putexcel C14 = `M2'
putexcel D14 = `M'

putexcel B21 = "Pseudo-RSquared"
putexcel C21 = `P'
putexcel D21 = `P2'


*==============================================================================*
* 2.3.2 overlap
*==============================================================================*

* ------------------------------------
* Figure A6 (Appendix): Common support
* ------------------------------------


local ps_low `GMps_min' `GMps_min' 0
local count = 1

foreach a of numlist `GMps_max' 0.95 1 {
	cap: drop _KM_*
	gettoken ps ps_low:ps_low
	
	* do kernel PSM matching for trimmed model
	* ----------------------------------------
	kmatch ps Masn_e2 $sociodem $attitudes $crisisdem $busidem  ///
	($depvar) if sample==1, ate att comsup(`ps' `a') pscmd(probit) ///
	gen(_KM_) bwidth(cv) kernel(epan)				
	
	* draw histogram of ps density for treatment and control group
	* -------------------------------------------------------------
	cap: drop fx0
	cap: drop fx1
	cap: drop x
	cap: drop fx
	kdensity _KM_ps, nograph generate(x fx) 
	kdensity _KM_ps if Masn_e2==1, nograph generate(fx0) at(x)
	kdensity _KM_ps if Masn_e2==0, nograph generate(fx1) at(x)
	label var fx0 "treatment group"
	label var fx1 "control group"
	line fx0 fx1 x, color(black black) lpattern (2 dash) ///
	lwidth (thick thick) sort ytitle(Density, size(medlarge) margin(medium)) ///
	graphregion(color(white)) xtitle("Propensity score", size(medlarge) margin(medium)) ///
	legend(order(1 "treatment group" 2 "control group") size(medlarge)) ///
	name(common_support_`count', replace)
	graph export "$results\Overlap_`count'.png", replace
	
	display "------------------------------------------------------------------"
	display "count `count' shows the distribution for the upper trimming bound  `a'"
	display "------------------------------------------------------------------"
	display "the lower trimming bound is `ps'"
	display "------------------------------------------------------------------"
	local ++count
}



*==============================================================================*	
*						PART 3: Heterogeneous effects analysis
*==============================================================================*

*==============================================================================*	
* 3.1 Risk
*==============================================================================*

* -----------------------------
* Table 8: ATT by risk attitude
* -----------------------------

* clean
* -----
cap: drop _KM_* 
scalar drop _all
matrix drop _all


* prepare output file	
* -------------------
putexcel set "$results/$outfile", modify sheet("Risk")
putexcel C1 = "Risk (min/max trimming)"
putexcel C2 = "risk avoiding" 
putexcel E2 = "risk neutral"
putexcel G2 = "prepared to take risks"
putexcel B4 = "coef."
putexcel C3 = "ATE"
putexcel D3 = "ATT"
putexcel B5 = "SE"
putexcel B6 = "p-value"	
putexcel B7 = "bs replications"
putexcel B8 = "N matched"
putexcel B9 = "N out of common support"
putexcel B10 = "N total"
putexcel B11 = "min"
putexcel B12 = "max"

* Loop through each risk category
* -------------------------------
local cell  C E G
forvalues i =1/3 {
	gettoken left cell:cell
		
		* ----------------------------------------------------------------------
		* First step: Do kernel PSM to obtain trimming parameters for risk model
		* ----------------------------------------------------------------------
		cap: drop _KM_*
		kmatch ps Masn_e2 $sociodem $crisisdem $busidem  ($depvar) ///
		if sample==1  & risk_c==`i', ate att  pscmd(probit) ///
		bwidth(cv) kernel(epan)  gen(_KM_)

		* ps distribution treatment group
		* -------------------------------
		sum _KM_ps if Masn_e2==1, detail 
		scalar sc_min1 = r(min)
		scalar sc_max1 = r(max)
		
		* ps distribution control group
		* ------------------------------
		sum _KM_ps if Masn_e2==0, detail 
		scalar sc_min2 = r(min)
		scalar sc_max2 = r(max)
		
		* choose lower bound as max(min treat, min control)
		* ------------------------------------------------
		if ( sc_min1 < sc_min2){
			local Rps_min = sc_min2
		}
		else{
			local Rps_min = sc_min1
		}
		
		* choose upper bound as min(max treat, max control)
		* ------------------------------------------------
		if ( sc_max1 < sc_max2){
			local Rps_max = sc_max1
		}
		else{
			local Rps_max = sc_max2
		}
		
		* display trimming boundaries
		* ---------------------------
		display `Rps_min'		
		display `Rps_max'
		
		
		* ----------------------------------------------
		* Second step: kernel PSM for trimmed risk model
		* ----------------------------------------------
		kmatch ps Masn_e2 $sociodem $crisisdem $busidem  ($depvar) ///
		if sample==1 & risk_c==`i', ate att comsup(`Rps_min' `Rps_max') ///
		pscmd(probit) bwidth(cv) kernel(epan) vce(bootstrap, rep($reps))
		
			* save results as matrix
			* ----------------------
			mat define M1=r(table)
			
			* extract ATE, ATT
			* -----------------
			mat M2 = M1[1,1..2] 
			mat list M2
			
			* extract standard errors
			* -----------------------
			mat M3 = M1[2,1..2]
			mat list M3
			
			* extract p-value
			* ---------------
			mat M4 = M1[4,1..2]
			mat list M4
			
			* save all results as .xls 
			* --------------------------
			putexcel set "$results/$outfile", modify sheet("Risk")
			putexcel `left'4= mat(M2)
			putexcel `left'5= mat(M3)	
			putexcel `left'6= mat(M4)	
			
			* number of bootstrap replications
			* ---------------------------------
			putexcel `left'7= `e(N_reps)'

			* number of matched observations
			* ------------------------------
			mat list e(_N)
			mat define M5 = e(_N)
			mat M5 = M5[3,1]
			putexcel `left'8 = mat(M5)
			
			* number of observations trimmed (out of common support)
			* -------------------------------------------------------
			putexcel `left'9 = `e(N_outsup)'
        
			* number of observations
			* ----------------------
			putexcel `left'10= `e(N)'
		
			* lower and upper bound
			* ---------------------
			putexcel `left'11= `Rps_min'
			putexcel `left'12= `Rps_max'

		}
		

	

*==============================================================================*	
* 3.2 Education
*==============================================================================*

* -------------------------------
* Table 7: ATT by education level
* -------------------------------
	
* clean
* -----
cap: drop _KM_* 
scalar drop _all
matrix drop _all


* prepare output file	
* -------------------
putexcel set "$results/$outfile", modify sheet("Education")
putexcel C1 = "Education (min/max trimming)"
putexcel C2 = "no university degree" 
putexcel E2 = "university degree"
putexcel B4 = "coef."
putexcel C3 = "ATE"
putexcel D3 = "ATT"
putexcel B5 = "SE"
putexcel B6 = "p-value"	
putexcel B7 = "bs replications"
putexcel B8 = "N matched"
putexcel B9 = "N out of common support"
putexcel B10 = "N total"
putexcel B11 = "min"
putexcel B12 = "max"


* loop through each education category (with/without university degree)
* ---------------------------------------------------------------------
local cell  C E
forvalues i =0/1 {
	gettoken left cell:cell

		* ----------------------------------------------------------------------
		* First step: Kernel PSM to obtain trimming parameters for education model
		* ---------------------------------------------------------------------- 
		cap: drop _KM_*
		kmatch ps Masn_e2 $sociodem_edu $attitudes $crisisdem $busidem  ///
		($depvar) if sample==1  & edu_cat_di==`i', ate att  ///
		pscmd(probit) bwidth(cv) kernel(epan)  gen(_KM_)

		* ps distribution treatment group
		* -------------------------------
		sum _KM_ps if Masn_e2==1, detail
		scalar sc_min1 = r(min)
		scalar sc_max1 = r(max)
		
		* ps distribution control group
		* ------------------------------
		sum _KM_ps if Masn_e2==0, detail
		scalar sc_min2 = r(min)
		scalar sc_max2 = r(max)
		
		* choose lower bound as max(min treat, min control)
		* ------------------------------------------------
		if ( sc_min1 < sc_min2){
			local Eps_min = sc_min2
		}
		else{
			local Eps_min = sc_min1
		}
		
		* choose upper bound as min(max treat, max control)
		* ------------------------------------------------
		if ( sc_max1 < sc_max2){
			local Eps_max = sc_max1
		}
		else{
			local Eps_max = sc_max2
		}
		
		* display trimming boundaries
		* ---------------------------
		display `Eps_min'		
		display `Eps_max'
		
		
		* ---------------------------------------------------
		* Second step: kernel PSM for trimmed education model
		* ---------------------------------------------------
		kmatch ps Masn_e2 $sociodem_edu $attitudes $crisisdem $busidem  ///
		($depvar) if sample==1 & edu_cat_di==`i', ate att ///
		comsup(`Eps_min' `Eps_max') pscmd(probit) bwidth(cv) kernel(epan) ///
		vce(bootstrap, reps($reps))
		
			* save results as matrix
			* ----------------------
			mat define M1=r(table)
			
			* extract ATE, ATT
			* -----------------
			mat M2 = M1[1,1..2] 
			mat list M2
			
			* extract standard errors
			* -----------------------
			mat M3 = M1[2,1..2]
			mat list M3
			
			* extract p-value
			* ---------------
			mat M4 = M1[4,1..2]
			mat list M4
			
			* save all results as .xls 
			* ------------------------
			putexcel set "$results/$outfile", modify sheet("Education")
		
			putexcel `left'4= mat(M2)
			putexcel `left'5= mat(M3)	
			putexcel `left'6= mat(M4)	
			
			* number of bootstrap replications
			* --------------------------------
			putexcel `left'7= `e(N_reps)'

			* number of matched observations
			* ------------------------------
			mat list e(_N)
			mat define M5 = e(_N)
			mat M5 = M5[3,1]
			putexcel `left'8 = mat(M5)
             
			
			* number of observations trimmed (out of common support)
			* -------------------------------------------------------
			putexcel `left'9 = `e(N_outsup)'
        
			* number of observations
			* ----------------------
			putexcel `left'10= `e(N)'
		
			* lower and upper bound
			* ---------------------
			putexcel `left'11= `Eps_min'
			putexcel `left'12= `Eps_max'
	
		}		

		

*==============================================================================*	
* 3.3 Application processing speed
*==============================================================================*

* --------------------------------
* Table 9: ATT by speed of payment
* --------------------------------

* clean
* -----
cap: drop _KM_* 
scalar drop _all
matrix drop _all


* prepare output file
* -------------------
putexcel set "$results/$outfile", modify sheet("Speed")
putexcel C1 = "Application process speed (min/max trimming)"
putexcel C2 = "fast (up to 5 days)" 
putexcel E2 = "slow (more than 5 days)"
putexcel B4 = "coef."
putexcel C3 = "ATE"
putexcel D3 = "ATT"
putexcel B5 = "SE"
putexcel B6 = "p-value"	
putexcel B7 = "bs replications"
putexcel B8 = "N matched"
putexcel B9 = "N out of common support"
putexcel B10 = "N total"
putexcel B11 = "min"
putexcel B12 = "max"

* loop through all speed categories (slow/fast)
* ---------------------------------------------
local cells C E
forvalues i =1/2 {
	gettoken left cells:cells
		
		* ----------------------------------------------------------------------
		* First step: Kernel PSM to obtain trimming parameters for speed model
		* ----------------------------------------------------------------------  
		cap: drop _KM_*
		kmatch ps Masn_e2 $sociodem $attitudes $crisisdem $busidem  ///
		($depvar) if sample==1  & (Antrag_dauer==`i'| Antrag_dauer==3), ///
		ate att  pscmd(probit) bwidth(cv) kernel(epan)  gen(_KM_)

		* ps distribution treatment group
		* -------------------------------
		sum _KM_ps if Masn_e2==1, detail 
		scalar sc_min1 = r(min)
		scalar sc_max1 = r(max)
		
		* ps distribution control group
		* ------------------------------
		sum _KM_ps if Masn_e2==0, detail 
		scalar sc_min2 = r(min)
		scalar sc_max2 = r(max)
		
		* choose lower bound as max(min treat, min control)
		* ------------------------------------------------
		if ( sc_min1 < sc_min2){
			local Sps_min = sc_min2
		}
		else{
			local Sps_min = sc_min1
		}
		
		* choose upper bound as min(max treat, max control)
		* ------------------------------------------------
		if ( sc_max1 < sc_max2){
			local Sps_max = sc_max1
		}
		else{
			local Sps_max = sc_max2
		}
		
		* display trimming boundaries
		* ---------------------------
		display `Sps_min'		
		display `Sps_max'
		
		* ------------------------------------------------
		* Second step: kernel PSM for trimmed speed model
		* ------------------------------------------------
		kmatch ps Masn_e2 $sociodem $attitudes $crisisdem $busidem  ///
		($depvar) if sample==1 & (Antrag_dauer==`i'| Antrag_dauer==3), ///
		ate att comsup(`Sps_min' `Sps_max') pscmd(probit) bwidth(cv) ///
		kernel(epan) vce(bootstrap,reps($reps))
		
			* save results as matrix
			* ----------------------
			mat define M1=r(table)
			
			* extract ATE, ATT
			* -----------------
			mat M2 = M1[1,1..2] 
			mat list M2
			
			* extract standard errors
			* -----------------------
			mat M3 = M1[2,1..2]
			mat list M3
			
			* extract p-value
			* ---------------
			mat M4 = M1[4,1..2]
			mat list M4
			
			* save all results as .xls 
			* ------------------------
			putexcel set "$results/$outfile", modify sheet("Speed")
		
			putexcel `left'4= mat(M2)
			putexcel `left'5= mat(M3)	
			putexcel `left'6= mat(M4)	
			
			* number of bootstrap replications
			* ---------------------------------
			putexcel `left'7= `e(N_reps)'

			* number of matched observations
			* ------------------------------
			mat list e(_N)
			mat define M5 = e(_N)
			mat M5 = M5[3,1]
			putexcel `left'8 = mat(M5)
             
			
			* number of observations trimmed (out of common support)
			* -------------------------------------------------------
			putexcel `left'9 = `e(N_outsup)'
        
			* number of observations
			* ----------------------
			putexcel `left'10= `e(N)'
		
			* lower and upper bound
			* ---------------------
			putexcel `left'11= `Sps_min'
			putexcel `left'12= `Sps_max'
	
		}	


		
*==============================================================================*	
* 3.4 Industries
*==============================================================================*

* ------------------------
* Table 6: ATT by industry
* ------------------------

* clean
* -----
cap: drop _KM_* 
scalar drop _all
matrix drop _all


* prepare output file	
* -------------------
putexcel set "$results/$outfile", modify sheet("Industries")
putexcel C1 = "industries (Min/Max Trimming)"
putexcel C2 = "strongly affected industries" 
putexcel E2 = "others"
putexcel B4 = "coef."
putexcel C3 = "ATE"
putexcel D3 = "ATT"
putexcel E3 = "ATE"
putexcel F3 = "ATT"
putexcel B5 = "SE"
putexcel B6 = "p-value"	
putexcel B7 = "bs replications"
putexcel B8 = "N matched"
putexcel B9 = "N out of common support"
putexcel B10 = "N total"
putexcel B11 = "min"
putexcel B12 = "max"

* loop through all industry categories
* -------------------------------------
local cells C E 
forvalues i =0/1 {
	gettoken left cells:cells
		
		* ----------------------------------------------------------------------
		* First step: Kernel PSM to obtain trimming parameters for industry model
		* ----------------------------------------------------------------------  
		cap: drop _KM_*
		kmatch ps Masn_e2 $sociodem $attitudes $crisisdem $busidem  ///
		($depvar) if sample==1  & (industries_cri==`i'), ///
		ate att  pscmd(probit) bwidth(cv) kernel(epan)  gen(_KM_)

		* ps distribution treatment group
		* -------------------------------
		sum _KM_ps if Masn_e2==1, detail 
		scalar sc_min1 = r(min)
		scalar sc_max1 = r(max)
		
		* ps distribution control group
		* -----------------------------
		sum _KM_ps if Masn_e2==0, detail 
		scalar sc_min2 = r(min)
		scalar sc_max2 = r(max)
		
		* choose lower bound as max(min treat, min control)
		* ------------------------------------------------
		if ( sc_min1 < sc_min2){
			local Kps_min = sc_min2
		}
		else{
			local Kps_min = sc_min1
		}
		
		* choose upper bound as min(max treat, max control)
		* ------------------------------------------------
		if ( sc_max1 < sc_max2){
			local Kps_max = sc_max1
		}
		else{
			local Kps_max = sc_max2
		}
		
		* display trimming boundaries
		* ---------------------------
		display `Kps_min'		
		display `Kps_max'
		
		* --------------------------------------------------
		* Second step: kernel PSM for trimmed duration model
		* --------------------------------------------------
		kmatch ps Masn_e2 $sociodem $attitudes $crisisdem $busidem  ///
		($depvar) if sample==1 & (industries_cri==`i'), ///
		ate att comsup(`Kps_min' `Kps_max') pscmd(probit) bwidth(cv) ///
		kernel(epan) vce(bootstrap,reps($reps))
		
			* save results as matrix
			* ----------------------
			mat define M1=r(table)
			
			* extract ATE, ATT
			* -----------------
			mat M2 = M1[1,1..2] 
			mat list M2
			
			* extract standard errors
			* -----------------------
			mat M3 = M1[2,1..2]
			mat list M3
			
			* extract p-value
			* ---------------
			mat M4 = M1[4,1..2]
			mat list M4
			
			* save all results as .xls 
			* ------------------------
			putexcel set "$results/$outfile", modify sheet("Industries")
		
			putexcel `left'4= mat(M2)
			putexcel `left'5= mat(M3)	
			putexcel `left'6= mat(M4)	
			
			* number of bootstrap replications
			* ---------------------------------
			putexcel `left'7= `e(N_reps)'

			* number of matched observations
			* ------------------------------
			mat list e(_N)
			mat define M5 = e(_N)
			mat M5 = M5[3,1]
			putexcel `left'8 = mat(M5)
             
			
			* number of observations trimmed (out of common support)
			* -------------------------------------------------------
			putexcel `left'9 = `e(N_outsup)'
        
			* number of observations
			* ----------------------
			putexcel `left'10= `e(N)'
		
			* lower and upper bound
			* ---------------------
			putexcel `left'11= `Kps_min'
			putexcel `left'12= `Kps_max'
		}
	
	
	
*==============================================================================*	
*				PART 4: Nearest Neighbour Matching (Robustness Checks)
*==============================================================================*

* ----------------------------------------------------------------------
* Table A4: Nearest Neighbor-Matching with two neighbors and replacement
* ----------------------------------------------------------------------

*==============================================================================*
* 4.1 NN2 without trimming
*==============================================================================*

* prepare output file
* -------------------
putexcel set "$results/$outfile", modify sheet("Nearest Neighbour Matching")
putexcel C1 = "Nearest Neighbour Matching"
putexcel C2 = "NN2 (without trimming)"
putexcel E2 = "NN2 (Caliper 0.05)"
putexcel C3 = "ATE"
putexcel D3 = "ATT"
putexcel B4 = "coef."
putexcel B5 = "SE"
putexcel B6 = "p-value"	
putexcel B7 = "bs replications"
putexcel B8 = "N matched"
putexcel B9 = "N out of common support"
putexcel B10 = "N total"

* Note: since bootstrapping does not provide robust standard errors for 
* NN-matching (Abadie and Imbens, 2008), we use the 'teffects' command with SE 
* calculated according to Abadie and Imbens (2012).

* estimate ATE and ATT in a loop
* -------------------------------
local te ate atet
local cells C D  

foreach a of local te {
		gettoken left cells:cells 
    
cap: drop _KM_* 
scalar drop _all
matrix drop _all
cap noi drop OCS*

* obtain out-of sample information for number of NN-requirement
* -------------------------------------------------------------
cap noi teffects psmatch (survival_di2) (Masn_e2 $sociodem $attitudes ///
$crisisdem $busidem , probit) if sample==1, `a' nneighbor(2) osample(OCS1)

* obtain out-of sample information for number of NN-requirement
* -------------------------------------------------------------
cap noi teffects psmatch (survival_di2) (Masn_e2 $sociodem $attitudes ///
$crisisdem $busidem , probit) if sample==1 & OCS1!=1, `a' nneighbor(2) ///
osample(OCS2)

* run final estimation
* -------------------- 
cap noi teffects psmatch (survival_di2) (Masn_e2 $sociodem $attitudes ///
$crisisdem $busidem , probit) if sample==1 & OCS1!=1& OCS2!=1, `a' nneighbor(2)
			
		* save results as matrix
		* ----------------------
		mat define M1=r(table)
			
		* extract ATE
		* -----------------
		mat M2 = M1[1,1] 
		mat list M2
			
		* extract standard errors
		* -----------------------
		mat M3 = M1[2,1]
		mat list M3
			
		* extract p-value
		* ---------------
		mat M4 = M1[4,1]
		mat list M4
			
		* save all results as .xls 
		* ------------------------
		putexcel set "$results/$outfile", modify sheet("Nearest Neighbour Matching")
		
		putexcel `left'4= mat(M2)
		putexcel `left'5= mat(M3)	
		putexcel `left'6= mat(M4)	

		* number of matched observations
		* ------------------------------
		putexcel `left'10= `e(N)'

}      




*==============================================================================*
* 4.2 NN2 with Caliper 0.5 
*==============================================================================*

* ----------------------------------------------------------------------
* Table A4: Nearest Neighbor-Matching with two neighbors and replacement
* -----------------------------------------------------------------------

* estimate ATE and ATT in a loop
* -------------------------------
local te ate atet
local cells E F  

foreach a of local te {
		gettoken left cells:cells 
    
cap: drop _KM_* 
scalar drop _all
matrix drop _all
cap noi drop OCS*

* obtain out-of sample information for caliper = 0.05
* ---------------------------------------------------
cap noi teffects psmatch (survival_di2) (Masn_e2 $sociodem $attitudes ///
$crisisdem $busidem  , probit) if sample==1, `a' nneighbor(2) ///
caliper(0.05) osample(OCS1)

* obtain out-of sample information for caliper = 0.05 with adjusted sample
* ------------------------------------------------------------------------
cap noi teffects psmatch (survival_di2) (Masn_e2 $sociodem $attitudes ///
$crisisdem $busidem  , probit) if sample==1 & OCS1!=1, `a' nneighbor(2) ///
caliper(0.05) osample(OCS2)

* obtain out-of sample information for caliper = 0.05 with adjusted sample
* ------------------------------------------------------------------------
cap noi teffects psmatch (survival_di2) (Masn_e2 $sociodem $attitudes ///
$crisisdem $busidem , probit) if sample==1 & OCS1!=1 & OCS2!=1, `a' nneighbor(2) ///
caliper(0.05) osample(OCS3)

* run final estimation
* --------------------	 
cap noi teffects psmatch (survival_di2) (Masn_e2 $sociodem $attitudes ///
$crisisdem $busidem , probit) if sample==1 & OCS1!=1 & OCS2!=1& OCS3!=1, `a' nneighbor(2) ///
caliper(0.05)
			
		* save results as matrix
		* ----------------------
		mat define M1=r(table)
			
		* extract ATE
		* -----------------
		mat M2 = M1[1,1] 
		mat list M2
			
		* extract standard errors
		* -----------------------
		mat M3 = M1[2,1]
		mat list M3
			
		* extract p-value
		* ---------------
		mat M4 = M1[4,1]
		mat list M4
			
		* save all results as .xls 
		* ------------------------
		putexcel set "$results/$outfile", modify sheet("Nearest Neighbour Matching")
		
		putexcel `left'4= mat(M2)
		putexcel `left'5= mat(M3)	
		putexcel `left'6= mat(M4)	

		* number of matched observations
		* ------------------------------
		putexcel `left'10= `e(N)'

}      

cap log close
********************************************************************************
*    							End
********************************************************************************