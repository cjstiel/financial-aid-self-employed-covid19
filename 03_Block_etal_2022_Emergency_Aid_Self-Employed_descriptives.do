/*******************************************************************************
		     	Article: Emergency Aid for Self-Employed in the COVID-19 
							Pandemic: A Flash in the Pan? 
							
published in: Journal of Economic Psychology, 2022, 93(102567).
authors: Joern Block, Alexander S. Kritikos, Maximilian Priem, Caroline Stiel	
affiliations: Trier University, DIW Berlin, DIW-Econ		
				
********************************************************************************
													                 
																	 Do-File 03
							
							DESCRIPTIVE STATISTICS
							
		CONTENT:	Descriptive statistics of the whole sample, treatment,
					and control group
		
		OUTLINE:	PART 1: Definitions
					PART 2: Financial Impact of COVID-19
					PART 3: Future Prospects
					PART 4: Emergency Aid Program
					PART 5: Descriptives of Covariates before and after Matching

					
--------------------------------------------------------------------------------
code authors: Maximilian Priem (DIWecon), Caroline Stiel (DIW Berlin)
version: 08-Aug-2022 (v08)
--------------------------------------------------------------------------------
	
*******************************************************************************/
		
/*******************************************************************************
* 							PART 1: Definitions
*******************************************************************************/

set more off

*====================================*
* 1.1 Logfile
*====================================*

* define dates and time etc.
* -------------------------
local date=ltrim("$S_DATE")
local date=subinstr("`date'"," ","_",2)

* start log file
* -------------- 
cap log close
log using "$results\log_Descriptives_`date'.log", replace


*================================*
* 1.2 covariates for PSM
*===============================*

* main model
* ----------
global attitudes "ib2.risk_c"
global crisisdem "  i.running_cost_2 ib1.Hoehe_Umsatzrueckgang_2 ib1.solvency_firm dig_vor_corona Durststrecke3" 
global sociodem "se_full_time i.gender ib3.age_cat ib2.edu_cat ib2.location_DE i.Plan_AG2b week_quest" 
global busidem "ib2.duration_se ib1.industry_nace solo_solo" 
global staatl_Unt "staatl_Unt_2t6"

* heterogeneity analysis
* ----------------------
global sociodem_edu "se_full_time i.gender ib3.age_cat  ib2.location_DE i.Plan_AG2b week_quest" 



*================================*
* 1.3 Load data
*================================*

* load cleaned data set of unmatched sample (17,090 obs)
* ------------------------------------------------------
use "$input/Datensatz_Deskriptives.dta", clear



********************************************************************************
* 					PART 2: Financial impact of COVID-19
********************************************************************************

* Define applicants and non-applicants
* ------------------------------------
gen applied = .
replace applied  = 1 if Soforthilfe==1
replace applied  = 0 if Soforthilfe==2 | Soforthilfe==3 |Soforthilfe==4
tab applied, mi
separate applied, by(applied)


*==============================================================================*
* 2.1 Revenue decline
*==============================================================================*

*-------------------------------------------------------
* Figure 1: Revenue decline due to the COVID-19 pandemic
* ------------------------------------------------------

graph bar (percent) applied0 applied1 if sample==1, ///
over(Hoehe_Umsatzrueckgang_2, relabel(1 "no decline" 2 "0-25%" 3 "26-50%" ///
4 "51-75%" 5 "76-99%" 6 "100%")) ///
bar(2, color(white) lcolor(black) lwidth(medthick)) ///
bar(1, color(black%70) lcolor(black)) ///
ytitle("Percent", size(medium)) bargap(-30) ///
title("revenue decline due to COVID-19", size(medlarge)) graphregion(color(white)) ///
legend(order(1 "not applied" 2 "applied" )  region(lcolor(gs14))) ///

cap noi graph export "$results\graphs\RevenueDecline_bars_sw.png", as(png) replace


* -------------------------------------
* Table 1: Revenue decline by industry
* -------------------------------------

tab industry_nace Hoehe_Umsatzrueckgang_2 if sample==1 & applied==1, mi row
tab industry_nace Hoehe_Umsatzrueckgang_2 if sample==1 & applied==0, mi row



*==============================================================================*
* 2.2 Solvency
*==============================================================================*

* drop category "no separate bank account for my venture"
* -------------------------------------------------------
cap noi drop solvency_firm2 
gen solvency_firm2 = solvency_firm
replace solvency_firm2 =. if solvency_firm2 == 2
recode solvency_firm2 (3=2) (4=3) (5=4) (6=5) (7=6)
label define sv 1 "already insolvent" 2 "1 month" 3 "2 months" 4 "3 months" ///
5 "4 to 6 months" 6 "7 months +"
label value solvency_firm2 sv
tab solvency_firm2


* ---------------------------------------------------------------------
* Figure A2 (Appendix): Duration of solvency without government support
* ---------------------------------------------------------------------

* graph firm solvency
* -------------------
graph bar (percent) applied0 applied1 if sample==1, ///
over(solvency_firm2, relabel(1 `" "already" "insolvent" "' 2 "1" 3 "2" ///
4 "3" 5 "4 to 6" 6 "7+")) ///
text(-4 50 "months", size(medlarge)) ///
bar(2, color(white) lcolor(black) lwidth(medthick)) ///
bar(1, color(black%70) lcolor(black)) ///
ytitle("Percent", size(medlarge)) bargap(-30) ///
legend(order(1 "not applied" 2 "applied") region(lcolor(gs14))) ///
graphregion(color(white)) ///
title("with operational reserves", size(medlarge)) name(FirmSolvBars, replace) 

* graph private solvency
* ----------------------
graph bar (percent) applied0 applied1 if sample==1, ///
over(solvency_private, relabel(1 `" "already" "insolvent" "' 2 "1" 3 "2" ///
4 "3" 5 "4 to 6" 6 "7+")) ///
text(-4 50 "months", size(medlarge)) ///
bar(2, color(white) lcolor(black) lwidth(medthick)) ///
bar(1, color(black%70) lcolor(black)) ///
ytitle("Percent", size(medlarge)) bargap(-30) ///
legend(order(1 "not applied" 2 "applied") region(lcolor(gs14))) ///
graphregion(color(white)) ///
title("additional use of private reserves", size(medlarge)) name(PrivSolvBars, replace) 

* combined graph
* --------------
cap noi grc1leg2 FirmSolvBars PrivSolvBars, graphregion(color(white)) ycommon ///
legendfrom(FirmSolvBars) title("solvency")

cap noi graph export "$results\graphs\Solvency_bars_sw.png", as(png) replace



*==============================================================================*
* 2.3 Monthly financial loss
*==============================================================================*

* drop gaps (empty cells) for better visualization
* ------------------------------------------------
cap noi drop mtl_finanz_Luecke2
gen mtl_finanz_Luecke2 = mtl_finanz_Luecke
recode mtl_finanz_Luecke2 (11=8) (12=9) (14=10)
label define labLueck 1 "no loss" 2 "up to 500 EUR" 3 "501 to 1000 EUR" ///
4 "1001 to 1500 EUR" 5 "1501 to 2000 EUR" 6 "2001 to 2500 EUR" ///
7 "2501 to 3000 EUR" 8 "3001 to 5000 EUR" 9 "5001 to 10 000 EUR" ///
10 "more than 10 0001 EUR"
label value mtl_finanz_Luecke2 labLueck
tab mtl_finanz_Luecke2, mi


* --------------------------------------------------------------
* Figure A1 (Appendix): Monthly financial loss during the crisis
* --------------------------------------------------------------

graph bar (percent) applied0 applied1 if sample==1, ///
over(mtl_finanz_Luecke2, relabel(1 `" "no" "loss" "' 2 `" "up to" "500 EUR" "'  ////
3 `" "501 to" "1,000 EUR" "' 4 `" "1,001 to" " 1,500 EUR" "' ///
5 `" "1,501 to" "2,000 EUR" "' 6`" "2,001 to" "2,500 EUR" "' ///
7`" "2,501 to" "3,000 EUR" "' 8`" "3,001 to" "5,000 EUR" "' ///
9`" "5,001 to" "10,000 EUR" "' 10 `" "more than" "10,001 EUR" "') label(angle(90))) ///
title("monthly financial loss during the crisis", size(medlarge)) ///
bar(2, color(white) lcolor(black) lwidth(medthick)) ///
bar(1, color(black%70) lcolor(black)) ///
bargap(-30) ytitle("Percent", size(medium)) ///
legend(order(1 "not applied" 2 "applied") region(lcolor(gs14))) ///
graphregion(color(white)) ///
title("monthly financial loss during the crisis", size(medlarge))

cap noi graph export "$results\graphs\MonhtlyLoss_bars_sw.png", as(png) replace



* ==============================================================================
* 						PART 3: Future prospects
* ==============================================================================

*==============================================================================*
* 3.1 Financial hardship
*==============================================================================*

* drop gaps (empty cells) for better visualization
* -------------------------------------------------
cap noi drop Durststrecke2
gen Durststrecke2 = Dauer_finanz_Durststr
recode Durststrecke2 (2/4=2) (5/7=3) (8=4) (9=5) (10=6) (11=7) (12=8)
label define LabDS 1 "no hard times" 2 "1 to 3 months" 3 "4 to 6 months" ///
4 "7 to 9 months" 5 "10 to 12 months" 6 "13 to 18 months" 7 "19 to 24 months" ///
8 "more than 2 years"
label value Durststrecke2 LabDS
tab Durststrecke2, mi
tab Durststrecke, mi

* --------------------------------------------------------------
* Figure A3 (Appendix): Expected duration of financial hardship 
* --------------------------------------------------------------

graph bar (percent) applied0 applied1 if sample==1, ///
over(Durststrecke2, relabel(1 `" "no" "hardship" "' 2 `" "1 to 3" "months" "' ///
3 `" "4 to 6" "months" "' 4 `" "7 to 9" " months" "' ///
5 `" "10 to 12" "months" "' 6`" "13 to 18" "months" "' ///
7`" "19 to 24" "months" "' 8`" "more than" "2 years" "')) ///
bar(2, color(white) lcolor(black) lwidth(medthick)) ///
bar(1, color(black%70) lcolor(black)) ///
bargap(-30) ytitle("Percent", size(medium)) ///
legend(order(1 "not applied" 2 "applied") region(lcolor(gs14))) ///
title("expected duration of financial hardship" "due to the COVID-19 pandemic", size(medlarge)) ///
graphregion(color(white))

cap noi graph export "$results\graphs\FinancialHardship_bars_sw.png", as(png) replace



*==============================================================================*
* 3.2 Survival probability
*==============================================================================*

* -------------------------------------------------------------------
* Figure A4 (Appendix): Expected probability of occupational survival
* -------------------------------------------------------------------

graph bar (percent) applied0 applied1 if sample==1, ///
over(optimism, relabel(1 `" "very" "unlikely" "' 2 `" "unlikely" "" "' 3 `" "neutral" " "' ///
4 `" "likely" "" "' 5 `" "very" "likely" "')) ///
bar(2, color(white) lcolor(black) lwidth(medthick)) ///
bar(1, color(black%70) lcolor(black)) ///
bargap(-30) ///
ytitle("Percent", size(medium)) ///
legend(order(1 "not applied" 2 "applied") region(lcolor(gs14))) ///
title("expected survival probability", size(medlarge)) ///
graphregion(color(white))

cap noi graph export "$results\graphs\Optimism_bars_sw.png", as(png) replace


* ------------------------------------------------------------------------------
* Figure A7 (Appendix): Subjective survival probability among applicants by education level
* ------------------------------------------------------------------------------

* comparison by education level
* -----------------------------
gen HELP_edu = edu_cat_di
separate HELP_edu, by(HELP_edu)

* graph
* -----
graph bar (percent) HELP_edu0 HELP_edu1 if sample==1 & applied==1, ///
over(optimism, relabel(1 `" "very" "unlikely" "' 2 `" "unlikely" "" "' 3 `" "neutral" " "' ///
4 `" "likely" "" "' 5 `" "very" "likely" "')) ///
bar(2, color(white) lcolor(black) lwidth(medthick)) ///
bar(1, color(black%70) lcolor(black)) ///
bargap(-30) ///
ytitle("Percent", size(medium)) ///
legend(order(1 "no university degree" 2 "university degree") region(lcolor(gs14))) ///
title("expected survival probability among program applicants", size(medlarge)) ///
graphregion(color(white))

cap noi graph export "$results\graphs\Education_Optimism_bars_sw.png", as(png) replace



*===============================================================================
* 					PART 4: Emergency Aid Program
*===============================================================================

*==============================================================================*
* 4.1 Number of applicants vs. non-applicants
*==============================================================================*

* number of applicants
* --------------------
tab Soforthilfe, mi

* application status
* ------------------
tab Antrag_Status2, mi

* obs with payment received
* -------------------------
tab Hilfe_ausgezahlt, mi

* duration (days): from application to payment for those who received payment
* ---------------------------------------------------------------------------
tabstat Tage_Hilfe_ausge_nr if Hilfe_ausgezahlt==1, stats(n min p50 mean max)

* duration (days): from application to survey date for those waiting for decision
* ---------------------------------------------------------------------------
tabstat Tage_wartend_Bewill, stats(n min p50 mean max)

* duration (days): from application to (positive) decision
* --------------------------------------------------------
tab Tage_Antragstellung_Bewilligung, mi



*==============================================================================*
* 4.2 Timeline
*==============================================================================*

* ----------------------------------------------------
* Figure 2: Distribution of survey responses over time
* ----------------------------------------------------

twoway (histogram date_quest if sample==1, ///
		discrete percent width(1) lcolor(black) fcolor(white)), ///   
       legend(label(1 "share of survey responses") region(lcolor(gs14))) ///
	   xline(22065, lpattern(dash)) xline(21993, lpattern(dash)) ///
	   text(10 21994.5  "emergency aid package launched", orient(vertical) ///
	   color(cranberry)) ///
	   text(10 22063  "emergency aid package ended", orient(vertical) ///
	   color(cranberry)) ///
	   xline(22012, lpattern(dash) lcolor(black)) xline(22039, lpattern(dash) ///
	   lcolor(black)) ///
	   text(10 22010 "survey started", orient(vertical) color(black)) ///
	   text(10 22040.5  "survey ended", orient(vertical) color(black)) ///
	   xlabel(21993 "March 19th" 22000 "March 26th" 22007 "April 2nd" ///
	   22014 "April 9th" 22021 "April 16th" 22028 "April 23th" ///
	   22035 "April 30th" 22042 "May 7th" 22049 "May 14h" 22056 "May 21st" ///
	   22065 "May 31th", angle(90)) ///
	   xtitle("",) graphregion(color(white)) ///
	title("distribution of survey responses", size(medlarge)) name(timeline, replace)

cap noi graph export "$results\graphs\Timeline.png", as(png) replace


* -------------------------------------------------------
* Figure A5 (Appendix): Timing of the application process
* -------------------------------------------------------

* for better visualization: move payment day by half a day
* --------------------------------------------------------
gen date_paymentGR = date_payment+0.5

* graph
* -----
twoway (histogram date_antrag if sample==1, ///
		discrete percent width(1) color(black%70) barwidth(0.5)) ///        
       (histogram date_paymentGR if sample==1, ///
		discrete percent width(1) color(black%30) barwidth(0.5)), ///   
       legend(order(1 "date applied" 2 "date payment received")  region(lcolor(gs14))) ///
	   xtitle("",) graphregion(color(white)) ///
title("application process", size(medlarge)) name(apspeed,replace) ///
	   xlabel(21993 "March 19th" 22000 "March 26th" 22007 "April 2nd" ///
	   22014 "April 9th" 22021 "April 16th" 22028 "April 23th" ///
	   22035 "April 30th", angle(90))
	   
cap noi graph export "$results\graphs\Applicationprocessing_bars.png", as(png) replace




*==============================================================================*
* 4.3 Reasons for not yet applying ('planned')
*==============================================================================*

* ---------------------------------------------------------------------------
* Table A2 (Appendix): Reasons for not applying for the emergency aid program
* ---------------------------------------------------------------------------

tab Keine_Soforthilfe if applied == 0 & sample==1 & Keine_Soforthilfe!=., mi



********************************************************************************
* 			PART 5: Descriptives of covariates before and after matching
********************************************************************************

* --------------------------------------------
* Table A1 (Appendix): Descriptive Statistics
* --------------------------------------------

* main model with B=5 reps to obtain treated and matched sample
* -------------------------------------------------------------
* Note: bandwidth can be small, no estimation output used.
kmatch ps Masn_e2 $sociodem $attitudes $crisisdem $busidem (survival_di2) ///
if sample==1, ate att  pscmd(probit) vce(bootstrap, rep(5)) bwidth(cv) ///
kernel(epan)

 
 * save descriptive sample output
 * ------------------------------
cap: drop reg_sample
gen reg_sample =e(sample)



*==============================================================================*
* 5.1 Continuos variables
*==============================================================================*

* prepare output file
* -------------------
putexcel set "$results\Emergency_Aid_Matching_Descriptives.xlsx", modify sheet("Deskriptives")
putexcel M4 = "observations"
putexcel N4 = "mean"
putexcel O4 = "standard deviations"
putexcel P4 = "minimum"
putexcel Q4 = "maximum"

* save descriptives for matching sample
* -------------------------------------
sum dig_vor_corona if reg_sample==1 
putexcel M5 = `r(N)'
putexcel N5 = `r(mean)'
putexcel O5 = `r(sd)'
putexcel P5 = `r(min)'
putexcel Q5 = `r(max)'

* save descriptives for treatment group
* -------------------------------------
sum dig_vor_corona if reg_sample==1 & Masn_e2 == 1
putexcel M6 = `r(N)'
putexcel N6 = `r(mean)'
putexcel O6 = `r(sd)'
putexcel P6 = `r(min)'
putexcel Q6 = `r(max)'

* save descriptives for control group
* -----------------------------------
sum dig_vor_corona if reg_sample==1 & Masn_e2 == 0
putexcel M7 = `r(N)'
putexcel N7 = `r(mean)'
putexcel O7 = `r(sd)'
putexcel P7 = `r(min)'
putexcel Q7 = `r(max)'

* save descriptives for whole sample
* ----------------------------------
sum dig_vor_corona 
putexcel M8 = `r(N)'
putexcel N8 = `r(mean)'
putexcel O8 = `r(sd)'
putexcel P8 = `r(min)'
putexcel Q8 = `r(max)'



*==============================================================================*
* 5.2 Categorical variables
*==============================================================================*

* define all variables for which descriptives sholuld be calculcated
* ------------------------------------------------------------------
global var "risk_c running_cost_2 Hoehe_Umsatzrueckgang_2 solvency_firm gender age_cat edu_cat location_DE duration_se industry_nace se_full_time solo_solo Plan_AG2b Durststrecke3 week_quest" 

* define starting row in .xls-file
* --------------------------------
local zeile = 4

* loop through all variables
* ---------------------------
foreach v in $var {
	
	sleep 3000
	
	*--------------------------------------------------------------------------
	* Preparation
	*--------------------------------------------------------------------------
	
	* prepare output file
	* -------------------
	putexcel set "$results\Emergency_Aid_Matching_Descriptives.xlsx", modify sheet("Deskriptives")
		
		putexcel C2 = "Matching Sample"
		putexcel E2 = "Treatment"
		putexcel G2 = "Control"
		putexcel I2 = "Whole Sample"
		
		putexcel C3 = "%"
		putexcel D3 = "N"
		putexcel E3 = "%"
		putexcel F3 = "N"
		putexcel G3 = "%"
		putexcel H3 = "N"
		putexcel I3 = "%"
		putexcel J3 = "N"		
		
		* store variable and value labels
		* -------------------------------
		fre `v'  if reg_sample==1, includelabeled
		local lab_val = r(lab_valid)
		local lab_var = r(depvar)
		
		local ++zeile
		
		* insert value labels 
		* ---------------------
		local help = `zeile'
		foreach x in `lab_val' {
			local h = substr("`x'",3,.)
			putexcel B`help' = "`h'"
			local ++help 
			}
		
		* insert variable label
		* -----------------------
			local help = `zeile'
			foreach x in `lab_var' {
				putexcel A`help' = "`x'"
				local ++help 
			}
		
		*----------------------------------------------------------------------
		* compute frequencies (percent)
		* ---------------------------------------------------------------------
		
		* matching sample
		* ---------------
		fre `v'  if reg_sample==1, includelabeled 
		matrix freq = r(valid)/r(N_valid)
		putexcel C`zeile' = matrix(freq)
		
		* treatment group
		* ---------------
		fre `v'  if reg_sample==1 & Masn_e2 == 1, includelabeled 
		matrix freq = r(valid)/r(N_valid)
		putexcel E`zeile' = matrix(freq)
		
		* control group
		* --------------
		fre `v'  if reg_sample==1 & Masn_e2 == 0, includelabeled 
		matrix freq = r(valid)/r(N_valid)
		putexcel G`zeile' = matrix(freq)
		
		* whole sample
		* -------------
		fre `v' , includelabeled 
		matrix freq = r(valid)/r(N_valid)
		putexcel I`zeile' = matrix(freq)

		sleep 3000
		
		*----------------------------------------------------------------------
		* compute frequencies (absolute numbers)
		* ---------------------------------------------------------------------
		
		* matching sample
		* ---------------
		fre `v'  if reg_sample==1, includelabeled 
		matrix freq = r(valid)
		putexcel D`zeile' = matrix(freq)
		
		* treatment group
		* ---------------
		fre `v'  if reg_sample==1 & Masn_e2 == 1, includelabeled 
		matrix freq = r(valid)
		putexcel F`zeile' = matrix(freq)
		
		* control group
		* -------------
		fre `v'  if reg_sample==1 & Masn_e2 == 0, includelabeled 
		matrix freq = r(valid)
		putexcel H`zeile' = matrix(freq)
		
		* whole sample
		* ------------
		fre `v' , includelabeled 
		matrix freq = r(valid)
		putexcel J`zeile' = matrix(freq)

		
		local valid = r(r_valid)
	
		local zeile = `zeile' +`valid'
		
	}

********************************************************************************
* 							Clean and save
********************************************************************************
	
cap log close	

********************************************************************************
* 									End
********************************************************************************	