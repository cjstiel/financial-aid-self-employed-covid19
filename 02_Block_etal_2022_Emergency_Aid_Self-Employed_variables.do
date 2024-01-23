/*******************************************************************************
		     	Article: Emergency Aid for Self-Employed in the COVID-19 
							Pandemic: A Flash in the Pan? 
							
published in: Journal of Economic Psychology, 2022, 93(102567).
authors: Joern Block, Alexander S. Kritikos, Maximilian Priem, Caroline Stiel	
affiliations: Trier University, DIW Berlin, DIW-Econ		
				
********************************************************************************
													                 
																	 Do-File 02
	
						VARIABLES AND DATA CLEANING
				
		CONTENT: Generates variables for the analysis and cleans the data set	
		
		OUTLINE:	PART 1: Covariates
							1.1: General 
							1.2: Self-employment
							1.3: Revenue and living costs
							1.4: Revenue decline due to COVID 19
							1.5: Other government support programs
					
					PART 2: Treatment - Emergency Aid
							2.1: Time of survey
							2.2: Time of application
							2.3: Time of payment
							2.4: Duration from application till decision
							2.5: Duration from application till payment
							2.6: Treatment variable
					
					PART 3: Outcome variable (survival)
							
					PART 4: Sample definition

							
					
--------------------------------------------------------------------------------
code authors: Maximilian Priem (DIWecon), Caroline Stiel (DIW Berlin)
version: 01-Mar-2022
--------------------------------------------------------------------------------					 
	 
*******************************************************************************/
set more off

* define dates and time etc.
* --------------------------
local date=ltrim("$S_DATE")
local date=subinstr("`date'"," ","_",2)

* start logfile
* -------------
cap log close
log using "$results\log_Variables_`date'.log", replace

* load data set
* -------------
use "$input/Dataset_renamed.dta", clear

********************************************************************************	
* 					PART 1: Covariates
********************************************************************************

* number of observations
* ---------------------------
count if respondent_id != "."

*===============================================================================
* 1.1 General								
*===============================================================================

* ------------------------------------------------------------------------------
* age
* ------------------------------------------------------------------------------

* check original variable
* -----------------------
tab age, gen(age_)
	label variable age_1 "- Age: <20"
	label variable age_2 "- Age: 20-24"
	label variable age_3 "- Age: 25-29"
	label variable age_4 "- Age: 30-34"
	label variable age_5 "- Age: 35-39"
	label variable age_6 "- Age: 40-44"
	label variable age_7 "- Age: 45-49"
	label variable age_8 "- Age: 50-54"
	label variable age_9 "- Age: 55-59"
	label variable age_10 "- Age: 60-64"
	label variable age_11 "- Age: >65"

label variable age "- Age (1-11)"

* summarize categories (fine type)
* ---------------------------------
gen new_age_1 = (age_1 == 1 | age_2 == 1 | age_3 == 1)
	label variable new_age_1 "- Age: <29"
gen new_age_2 = (age_4 == 1 | age_5 == 1)
	label variable new_age_2 "- Age: 30-39"
gen new_age_3 = (age_6 == 1 | age_7 == 1)
	label variable new_age_3 "- Age: 40-49"
gen new_age_4 = (age_8 == 1 | age_9 == 1)
	label variable new_age_4 "- Age: 50-59"
gen new_age_5 = (age_10 == 1 | age_11 == 1)
	label variable new_age_5 "- Age: >60"
		
* construct joint categorical variable
* ------------------------------------		
gen age_new = 0
	replace age_new = 1 if new_age_1 == 1
	replace age_new = 2 if new_age_2 == 1
	replace age_new = 3 if new_age_3 == 1
	replace age_new = 4 if new_age_4 == 1
	replace age_new = 5 if new_age_5 == 1
tab age_new, mi
* note: 0 = missing.

* summarize categories (broad type)
* ---------------------------------
cap: drop age_cat 
gen age_cat = age
recode age_cat (1/5 = 1) (6/7 = 2) (8/9 = 3) (10/11 = 4)
label de age_c 1 "till 39 years" 2 "40 - 49 years" 3 "50 - 59 years" 4 "60+ years", replace
label val age_cat age_c
tab age_cat, mi


* ------------------------------------------------------------------------------
* gender
* ------------------------------------------------------------------------------

* generate 'female' variable
* --------------------------
gen female = (gender == 2)
	label variable female "- Gender: female"
tab female, mi


* ------------------------------------------------------------------------------
* education
* ------------------------------------------------------------------------------

* check original variable
* ------------------------
tab Education

* recode categories
* ------------------
cap:drop edu_cat
gen edu_cat = Education
recode edu_cat (1/4 = 1) (5/6=2) (7/9=3)
label de edu_c 1 "other" 2 "apprenticeship" 3 "university", replace
label val edu_cat edu_c
tab edu_cat, mi

* generate binary variable (university degree yes/no)
* ---------------------------------------------------
cap: drop edu_cat_di
gen edu_cat_di=.
replace edu_cat_di = 1 if edu_cat==3
replace edu_cat_di = 0 if edu_cat ==1 | edu_cat ==2
label define educ 1 "university degree" 0 "no university degree", replace
label values edu_cat_di educ
tab edu_cat_di
 

* ------------------------------------------------------------------------------
* risk tolerance
* ------------------------------------------------------------------------------

* check original variable
* -----------------------
tab risk, mi
label variable risk "- Risk-taking (1-5)"

* recode categories
* -----------------
cap: drop risk_c
gen risk_c = risk
recode	risk_c (1/2=1) (3=2)(4/5=3)
label define c_risk 1 "low risk tolerance" 2 "medium risk tolerance" ///
3 "high risk tolerance" , replace 
label values risk_c c_risk
tab risk_c, mi



*===============================================================================
* 1.2 Self-employment							
*===============================================================================

* ------------------------------------------------------------------------------
* location (federal state)
* ------------------------------------------------------------------------------

* check original variable
* ------------------------
tab location, mi

* drop foreign ventures and name federal states
* ----------------------------------------------
cap: drop location_DE
gen location_DE = location if location !=17 & !missing(location)
label define location_DE1 1 "Baden-Württemberg" 2 "Bayern" 3 "Berlin" ///
4 "Brandenburg" 5 "Bremen" 6 "Hamburg" 7 "Hessen" 8 "Mecklenburg-Vorpommern" ///
9 "Niedersachsen" 10 "Nordrhein-Westfalen" 11 "Rheinland-Pfalz" ///
12 "Saarland" 13 "Sachsen" 14 "Sachsen-Anhalt" 15 "Schleswig-Holstein" ///
16 "Thüringen", replace
label values location_DE location_DE1


* ------------------------------------------------------------------------------
* industry
* ------------------------------------------------------------------------------

* check original variable
* ------------------------
 tab Branche
 tab Branche, gen(industry_)
 
* sort industries by NACE Rev.2 categories
* ----------------------------------------

cap: drop industry_nace
gen industry_nace =. 
replace industry_nace = 1 if (industry_26 ==1 | industry_9 ==1 | industry_25 ==1) 
replace industry_nace = 2 if (industry_18 ==1 | industry_19 ==1  | industry_22==1) 
replace industry_nace = 3 if industry_23 ==1 
replace industry_nace = 4 if (industry_4 ==1 | industry_11 ==1 | industry_10 ==1) 
replace industry_nace = 5 if (industry_2 ==1 | industry_6 ==1 | industry_5 ==1 ///
							| industry_8 ==1 | industry_3 ==1) 
replace industry_nace = 6 if (industry_1 ==1 | industry_24 ==1 | industry_20 ==1) 
replace industry_nace = 7 if industry_7 ==1 
replace industry_nace = 8 if (industry_14 ==1 | industry_15==1) 
replace industry_nace = 9 if (industry_16 ==1 | industry_13 ==1 ///
							| industry_12 ==1 | industry_17 ==1) 
replace industry_nace = 10 if (industry_27 == 1 | industry_21 ==1) 

label define nace 1 "manufacturing" ///
2 "trade, repair of motor vehicles"  ///
3 "hotels and restaurants" 4 "information and communications" ///
5 "professional services" ///
6 " other services" ///
7  "education" 8 "health care and social services" ///
9 "arts, recreation, cultural activities" 10 "other" , replace
label values industry_nace nace
tab industry_nace, mi


* generate binary variable: particularly affected industries (yes/no)
* ------------------------------------------------------------------
cap noi drop industries_cri
gen industries_cri = industry_nace
recode industries_cri (1/2=0) (3=1) (4/8=0) (9=1) (10=0) 
label define lab_vi 0 "other" 1 "industries heavily affected by the crisis"
label values industries_cri lab_vi
tab industries_cri, mi


* ------------------------------------------------------------------------------
* solo self-employment
* ------------------------------------------------------------------------------

* solo self-employed without employees
* ------------------------------------
* Solo yes = 1, no = 0 (based on employees)
gen solo_solo = (employees == 1 & employees_450 == 1)
	label variable solo_solo "- SE: solo"
tab solo_solo, mi

* solo self-employed with minor employed employees
* -------------------------------------------------
gen solo_emp_450 = (employees == 1 & (employees_450 == 2 | employees_450 == 3 |employees_450 == 4))
 label variable solo_emp_450 "- SE: solo with <450 EUR"


* ------------------------------------------------------------------------------
* full-time vs.part-time
* ------------------------------------------------------------------------------

* construct binary variable
* -------------------------
* Full-time = 1, part-time = 0
gen se_full_time = (umfang_se == 1 | umfang_se == 2 | umfang_se == 3)
label variable se_full_time "SE: full-time"
label de full 0 "Other than full time" 1 "full time", replace 
label val se_full_time full
tab se_full_time, mi

* construct binary variable for more than one occupation (self-employed & employed)
* ---------------------------------------------------------------------------
gen se_hybrid = (umfang_se == 4)
label variable se_hybrid "- SE: hybrid"


* ------------------------------------------------------------------------------
* duration of self-employment
* ------------------------------------------------------------------------------

* generate categorical variable
* ------------------------------
gen duration_se = 0
	replace duration_se = 1 if start_se == 1 | start_se == 2 | start_se == 3 | start_se == 4 | start_se == 5	
	replace duration_se = 2 if start_se == 6																	
	replace duration_se = 3 if start_se == 7																	
	replace duration_se = 4 if start_se == 8																	
	replace duration_se = 5 if start_se == 9 | start_se == 10 | start_se == 11									

label variable duration_se "- SE: duration (1-5)"
label de dur 1 "SE since 2016-2020" 2 "SE since 2010-2015" 3 "SE since 2000-2009" ///
4 "SE seit 1990-1999" 5 "SE since < 1990", replace
label val duration_se dur
tab duration_se, mi


*-------------------------------------------------------------------------------
* level of digitalization prior to the crisis	
*-------------------------------------------------------------------------------

* check original variables
* ------------------------
tab1 Digitalisierungsgrad_*, mi

* compute average across topics
* -----------------------------
cap: drop dig_vor_corona
gen dig_vor_corona = (Digitalisierungsgrad_1  + Digitalisierungsgrad_2 + Digitalisierungsgrad_3)/3 ///
						if !missing(Digitalisierungsgrad_1) ///
						& !missing(Digitalisierungsgrad_2) ///
						& !missing(Digitalisierungsgrad_3)
label variable dig_vor_corona "average degree of digitization before crisis (1-5 scale)"
tab dig_vor_corona, mi				



*===============================================================================
* 1.3 Revenue and living costs			
*===============================================================================

* ------------------------------------------------------------------------------
* Basic income scheme
* ------------------------------------------------------------------------------

* check original variables
* ------------------------
tab Plan_AG2, mi

* recode categories
* --------------------
gen Plan_AG2b = Plan_AG2
recode Plan_AG2b (4/max = 0) (3=1)
label de labelsAGb 0 "I will not apply" 1 "I already applied" 2 "I am planning to apply"
label values Plan_AG2b labelsAGb
tab Plan_AG2b, mi


* ------------------------------------------------------------------------------
* running costs
* ------------------------------------------------------------------------------

* check original variable
* -----------------------
tab running_cost, mi
label variable running_cost "- Private running cost"
 
* recode categories
* ------------------
cap: drop running_cost_2
gen running_cost_2 = running_cost
recode running_cost_2 (11/13=11)
label define running_c 1 "0-500" 2 "501-1,000" 3 "1,001-1,500" ///
4 "1,501-2,000" 5 "2,001-2,500" 6 "2,501-3,000" 7 "3,001-3,500" ///
8 "3,501-4,000" 9 "4,001-4,500" 10 "4,501-5000" 11 ">5,000", replace
label values running_cost_2 running_c
tab running_cost_2, mi



*===============================================================================
* 1.4 Revenue decline due to COVID-19		
*===============================================================================

-----------------------------------------------------------------------
* revenue decline
* ------------------------------------------------------------------------------

* check original variable
* -----------------------
tab Hoehe_Umsatzrueckgang, mi

* recode categories
* -----------------
cap: drop Hoehe_Umsatzrueckgang_2
gen Hoehe_Umsatzrueckgang_2 = Hoehe_Umsatzrueckgang
recode Hoehe_Umsatzrueckgang_2 (1/2=1) (3=2) (4=3) (5=4)(6=5)(7=6)
label define Umsatzrueckgang 1 "no decline" 2 "decline till 25%" ///
3 "26%-50%" 4 "51%-75%" 5 "76%-99%" 6 "100% (no more revenue)", replace
label values Hoehe_Umsatzrueckgang_2 Umsatzrueckgang
tab Hoehe_Umsatzrueckgang_2, mi


* ------------------------------------------------------------------------------
* expected duration of financial hardship
* ------------------------------------------------------------------------------

* check original variable
* -----------------------
tab Dauer_finanz_Durststr, mi

* recode categories
* -----------------
cap noi drop Durststrecke3
gen Durststrecke3 = Dauer_finanz_Durststr
recode Durststrecke3 (2/4=2) (5/7=3) (8=4) (9=5) (10=6) (11=6) (12=6)
label define LabDS3 1 "no hard times" 2 "1 to 3 months" 3 "4 to 6 months" ///
4 "7 to 9 months" 5 "10 to 12 months" 6 "more than one year"
label value Durststrecke3 LabDS3
tab Durststrecke3, mi


* ------------------------------------------------------------------------------
* monthly financial loss (venture)
* ------------------------------------------------------------------------------

* check original variable
* -----------------------
tab mtl_finanz_Luecke, mi

* recode categories
* -----------------
recode mtl_finanz_Luecke (8/11= 11) (13/14 = 14)
label de labels45 11 "3,001-5,000 Euro" 14 "10,001 Euro and more", modify
tab mtl_finanz_Luecke, mi


* ------------------------------------------------------------------------------
* firm solvency
* ------------------------------------------------------------------------------

* check original variable
* -----------------------
clonevar solvency_firm = Dauer_Zahlungsfaehig_betriebl
tab solvency_firm, mi

* recode categories
* -----------------
recode solvency_firm (6/8= 6) (9/max =7)
label de labels51 6 "4-6 months" 7 "7 months +", modify
tab solvency_firm


* ------------------------------------------------------------------------------
* private solvency
* ------------------------------------------------------------------------------

* check original variable
* -----------------------
tab solvency_private

* recode categories
* -----------------
recode solvency_private (5/7 = 5) (8/max = 6)
label de labels52 5 "4-6 months" 6 "7 months +", modify
tab solvency_private



*===============================================================================
* 1.5 Other government support programs				
*===============================================================================

* check original variables
* ------------------------
tab1 staatl_Unt*

* BAFA-Förderung
* --------------
cap: drop staatl_Unt_2c
 gen staatl_Unt_2c=0 
 replace staatl_Unt_2c =1 if staatl_Unt_1==.  & staatl_Unt_2==1
label define sU2 0 "no BAFA-Förderung" 1 "BAFA-Förderung"
label values staatl_Unt_2c sU2
tab staatl_Unt_2c

* KfW-Darlehen
* ------------
cap: drop staatl_Unt_3c
 gen staatl_Unt_3c=0 
 replace staatl_Unt_3c =1 if staatl_Unt_1==.  & staatl_Unt_3==1 
label define sU3 0 "no KfW-Darlehen" 1 "KfW-Darlehen"
label values staatl_Unt_3c sU3
tab staatl_Unt_3c
 
* KfW-Schnellkredit
* -----------------
cap: drop staatl_Unt_4c
 gen staatl_Unt_4c=0
 replace staatl_Unt_4c =1 if staatl_Unt_1==.  & staatl_Unt_4==1  
label define sU4 0 "no KfW-Schnellkredit" 1 "KfW-Schnellkredit"
label values staatl_Unt_4c sU4
tab staatl_Unt_4c

* Kurzarbeitergeld
* ----------------
 cap: drop staatl_Unt_5c
 gen staatl_Unt_5c=0 
 replace staatl_Unt_5c =1 if staatl_Unt_1==.  & staatl_Unt_5==1 
 label define sU5 0 "no Kurzarbeitergeld" 1 "Kurzarbeitergeld"
label values staatl_Unt_5c sU5
 tab staatl_Unt_5c
 
* Leistungsverweigerungsrecht
* --------------------------
 cap: drop staatl_Unt_6c 
 gen staatl_Unt_6c=0
 replace staatl_Unt_6c =1 if staatl_Unt_1==.  & staatl_Unt_6==1
label define sU6 0 "no Leistungsverweigerungsrecht" 1 "Leistungsverweigerungsrecht"
label values staatl_Unt_6c sU6
tab staatl_Unt_6c


 * joint variable for all other government support programs
 * --------------------------------------------------------
 cap: drop staatl_Unt_2t6
 gen staatl_Unt_2t6=0
 replace staatl_Unt_2t6=1 if staatl_Unt_2c==1 | staatl_Unt_3c==1 ///
							| staatl_Unt_4c==1 | staatl_Unt_5c==1 ///
							| staatl_Unt_6c==1
label define sU2t6 0 "no other government support programs" 1 "other government support programs from list"
label values staatl_Unt_2t6 sU2t6
tab staatl_Unt_2t6

 
 


********************************************************************************
* 					Part 2: Treatment -  Emergency Aid
********************************************************************************

*==============================================================================*	
* 2.1 Time of survey
*==============================================================================*


* -------------------------------------------------------------
* Version 1: recode the date at which individual started survey
* -------------------------------------------------------------
gen date = substr(date_created,1,10)
gen date_quest = date(date, "MDY")
display date("03/15/2020","MDY")

* generate week when individual started survey
* --------------------------------------------
* Note: Add last possible day of survey (4 May 2020) to calendar week 18
gen week_quest = date_quest
replace week_quest = 10 if week_quest > date("03/01/2020","MDY") & week_quest < date("03/09/2020","MDY") 
replace week_quest = 11 if week_quest > date("03/08/2020","MDY") & week_quest < date("03/16/2020","MDY") 
replace week_quest = 12 if week_quest > date("03/15/2020","MDY") & week_quest < date("03/23/2020","MDY") 
replace week_quest = 13 if week_quest > date("03/22/2020","MDY") & week_quest < date("03/30/2020","MDY") 
replace week_quest = 14 if week_quest > date("03/29/2020","MDY") & week_quest < date("04/06/2020","MDY") 
replace week_quest = 15 if week_quest > date("04/05/2020","MDY") & week_quest < date("04/13/2020","MDY") 
replace week_quest = 16 if week_quest > date("04/12/2020","MDY") & week_quest < date("04/20/2020","MDY") 
replace week_quest = 17 if week_quest > date("04/19/2020","MDY") & week_quest < date("04/27/2020","MDY") 
replace week_quest = 18 if week_quest > date("04/26/2020","MDY") & week_quest < date("05/05/2020","MDY") 
replace week_quest = 19 if week_quest > date("05/04/2020","MDY") & week_quest < date("05/11/2020","MDY") 

replace week_quest = . if date_quest<date("03/02/2020","MDY") | date_quest>date("05/04/2020","MDY")

label val week_quest weeks

tab week_quest



* -------------------------------------------------------------------
* Version 2: recode the date at which individual last modified survey
* -------------------------------------------------------------------

cap: drop survey_answer
gen survey_answer = date(date_modified, "MDYhms") 
list date_modified survey_answer in 1/10 

* recode PM/AM to 24 hours
* ------------------------
cap: drop survey_answer_day
gen survey_answer_day = survey_answer
format survey_answer_day %tc
list date_modified survey_answer_day in 1/10

* recode format as M/D/Y
* ----------------------
format %tdNN/DD/CCYY survey_answer_day
list date_modified survey_answer_day in 1/10
sum survey_answer_day, detail

* generate week when individual last modified survey
* --------------------------------------------------
cap: drop survey_answer_week
gen survey_answer_week =  survey_answer

replace survey_answer_week = 15 if survey_answer_week > date("04/05/2020","MDY") & survey_answer_week < date("04/13/2020","MDY")
replace survey_answer_week = 16 if survey_answer_week > date("04/12/2020","MDY") & survey_answer_week < date("04/20/2020","MDY") 
replace survey_answer_week = 17 if survey_answer_week > date("04/19/2020","MDY") & survey_answer_week < date("04/27/2020","MDY") 
replace survey_answer_week = 18 if survey_answer_week > date("04/26/2020","MDY") & survey_answer_week < date("05/04/2020","MDY") 
replace survey_answer_week = 19 if survey_answer_week > date("05/03/2020","MDY") & survey_answer_week < date("05/11/2020","MDY")

label def week 15 "KW 15"  16 "KW 16" 17 "KW 17" 18 "KW 18" 19 "KW 19", replace
label val survey_answer_week week
tab survey_answer_week




*==============================================================================*
* 2.2 Time of application
*==============================================================================*

* check and recode application date
* ---------------------------------
tab Antragsdatum, mi
gen date_antrag = date(Antragsdatum, "MDY")

* to Format MDY
* -------------
gen date_antrag_mdy = date_antrag
format %tdNN/DD/CCYY date_antrag_mdy
list date_antrag_mdy in 1/10

* generate application week
* -------------------------
gen week_antrag = date_antrag
replace week_antrag = 10 if week_antrag > date("03/01/2020","MDY") & week_antrag < date("03/09/2020","MDY") 
replace week_antrag = 11 if week_antrag > date("03/08/2020","MDY") & week_antrag < date("03/16/2020","MDY") 
replace week_antrag = 12 if week_antrag > date("03/15/2020","MDY") & week_antrag < date("03/23/2020","MDY") 
replace week_antrag = 13 if week_antrag > date("03/22/2020","MDY") & week_antrag < date("03/30/2020","MDY") 
replace week_antrag = 14 if week_antrag > date("03/29/2020","MDY") & week_antrag < date("04/06/2020","MDY") 
replace week_antrag = 15 if week_antrag > date("04/05/2020","MDY") & week_antrag < date("04/13/2020","MDY") 
replace week_antrag = 16 if week_antrag > date("04/12/2020","MDY") & week_antrag < date("04/20/2020","MDY") 
replace week_antrag = 17 if week_antrag > date("04/19/2020","MDY") & week_antrag < date("04/27/2020","MDY") 
replace week_antrag = 18 if week_antrag > date("04/26/2020","MDY") & week_antrag < date("05/04/2020","MDY") 
replace week_antrag = 19 if week_antrag > date("05/03/2020","MDY") & week_antrag < date("05/11/2020","MDY") 

replace week_antrag = . if date_antrag<date("03/02/2020","MDY") | date_antrag>date("05/04/2020","MDY")

label def weeks 10 "KW 10"  11 "KW 11"  12 "KW 12"  13 "KW 13"  14 "KW 14"  15 "KW 15"  16 "KW 16" 17 "KW 17" 18 "KW 18" 19 "KW 19", replace
label val week_antrag weeks

tab week_antrag


* recode Emergency_Aid=1 if information was provided at "Antrag_Status"
* ----------------------------------------------------------------------
replace Soforthilfe = 1 if !missing(Antrag_Status)

* Combine information on application status with info from emergeny aid variable
* ------------------------------------------------------------------------------
tab Antrag_Status, mi
tab Soforthilfe, mi

gen Antrag_Status2 = Antrag_Status
replace Antrag_Status2 = 4 if Soforthilfe ==2
replace Antrag_Status2 = 5 if Soforthilfe ==3
replace Antrag_Status2 = 6 if Soforthilfe ==4

label copy labels101 l_Antrag_Status2
label de l_Antrag_Status2  1 "Yes, it was accepted" 2 "Yes, but it was declined" ///
3 "Yes, I am waiting for a decision"  4 "I am planning to do so" 5 "I am not sure yet" ///
6 "No, I won't", replace
label val Antrag_Status2 l_Antrag_Status2
tab Antrag_Status2, mi



*==============================================================================*
* 2.3 Time of payment
*==============================================================================*

* recode number of days between application and payment
* ------------------------------------------------------
destring(Tage_Hilfe_ausgezahlt), gen(Tage_Hilfe_ausge_nr)

* generate date of payment
* ------------------------
cap noi drop date_payment
gen date_payment=.
replace date_payment = date_antrag + Tage_Hilfe_ausge_nr

* delete implausible dates after survey had ended
* -----------------------------------------------
replace date_payment = . if date_payment > date("05/04/2020","MDY")

* to format MDY
* -------------
gen date_payment_mdy = date_payment
format %tdNN/DD/CCYY date_payment_mdy
list date_payment_mdy in 1/10


* Generate week of payment received
* ----------------------------------
gen week_payment = .
replace week_payment = 10 if date_payment > date("03/01/2020","MDY") & date_payment < date("03/09/2020","MDY") 
replace week_payment = 11 if date_payment > date("03/08/2020","MDY") & date_payment < date("03/16/2020","MDY") 
replace week_payment = 12 if date_payment > date("03/15/2020","MDY") & date_payment < date("03/23/2020","MDY") 
replace week_payment = 13 if date_payment > date("03/22/2020","MDY") & date_payment < date("03/30/2020","MDY") 
replace week_payment = 14 if date_payment > date("03/29/2020","MDY") & date_payment < date("04/06/2020","MDY") 
replace week_payment = 15 if date_payment > date("04/05/2020","MDY") & date_payment < date("04/13/2020","MDY") 
replace week_payment = 16 if date_payment > date("04/12/2020","MDY") & date_payment < date("04/20/2020","MDY") 
replace week_payment = 17 if date_payment > date("04/19/2020","MDY") & date_payment < date("04/27/2020","MDY") 
replace week_payment = 18 if date_payment > date("04/26/2020","MDY") & date_payment < date("05/04/2020","MDY") 
replace week_payment = 19 if date_payment > date("05/03/2020","MDY") & date_payment < date("05/11/2020","MDY") 

replace week_payment = . if date_payment<date("03/02/2020","MDY") | date_payment>date("05/04/2020","MDY")

label def weeks 10 "KW 10"  11 "KW 11"  12 "KW 12"  13 "KW 13"  14 "KW 14"  15 "KW 15"  16 "KW 16" 17 "KW 17" 18 "KW 18" 19 "KW 19", replace
label val week_payment weeks

tab week_payment, mi


*==============================================================================*
* 2.4 Duration from application to (positive) decision
*==============================================================================*


*-------------------------------------------------------------------------------
* Application processing speed
*-------------------------------------------------------------------------------

* check original variable (number of days from application to pos. decision)
*---------------------------------------------------------------------------
tab Tage_Antragstellung_Bewilligung, mi

* generate application processing speed (3 categories)
* ----------------------------------------------------
cap: drop Antrag_dauer		
gen Antrag_dauer =.
replace Antrag_dauer = 1 if inrange(Tage_Antragstellung_Bewilligung,1,5) ///
							& (Antrag_Status2 == 1 | Antrag_Status2 == 2 ///
							|Antrag_Status2 == 3)
replace Antrag_dauer = 2 if inrange(Tage_Antragstellung_Bewilligung,6,12) ///
							&(Antrag_Status2 == 1 | Antrag_Status2 == 2 ///
							|Antrag_Status2 == 3)
replace Antrag_dauer = 3 if (Antrag_Status2 == 4 | Antrag_Status2 == 5 ///
							|Antrag_Status2 == 6) 
label define labAD 1 "up to 5 days" 2 "more than 5 days" 3 "did not (yet) apply", replace
label values Antrag_dauer labAD
tab Antrag_dauer, mi



*-------------------------------------------------------------------------------
* Number of days waiting (only those waiting for a decision)
*-------------------------------------------------------------------------------

* (survey date - application date) of those waiting 
* --------------------------------------------------
* those waiting: Antrag_Status=="Ja, warte auf Entscheidung"
gen Tage_wartend_Bewill = .
replace Tage_wartend_Bewill = survey_answer - date_antrag if Antrag_Status2==3

* recode implausible values as missing
* ------------------------------------
* application date before 19-March-2020 and after survey had ended
replace Tage_wartend_Bewill=. if Tage_wartend_Bewill < 0 | date_antrag < 21993
label variable Tage_wartend_Bewill "Number of days waiting for those waiting"

tab Tage_wartend_Bewill, mi
tabstat Tage_wartend_Bewill, stats (min p50 mean max) 



*==============================================================================*
* 2.5 Duration from application till payment
* =============================================================================*

* Number of days between application and payment
* ----------------------------------------------
tab Tage_Hilfe_ausgezahlt, mi
tab Tage_Hilfe_ausge_nr, mi

* Number of days if aid had not yet been granted
* ----------------------------------------------
count if !missing(Tage_Hilfe_ausge_nr) & Antrag_Status!=1

* Number of days if aid was granted and payment was received
* ----------------------------------------------------------
count if !missing(Tage_Hilfe_ausge_nr) &  Hilfe_ausgezahlt==1

* Number of days waiting if aid was granted but payment not yet received
* ----------------------------------------------------------------------
count if !missing(Tage_Hilfe_ausge_nr) &  Hilfe_ausgezahlt==2
tab Tage_Hilfe_ausge_nr if Hilfe_ausgezahlt==2



*==============================================================================*
* 2.6 Treatment variable
*==============================================================================*


* 'Payment received' versus 'application planned'
* -----------------------------------------------
cap:8drop  Masn_e2
gen Masn_e2=.
replace Masn_e2 =1 if Antrag_Status2 == 1 & Hilfe_ausgezahlt ==1
replace Masn_e2 =0 if Antrag_Status2 ==4 

label define e_Masn 1 "payment received" 0 "application planned" ,replace
label values Masn_e2 e_Masn
tab Masn_e2, mi



********************************************************************************	
* 					PART 3:  Outcome variable (survival)
********************************************************************************

* clean
cap: drop surv*

* check original variable
* ------------------------
* Q: What is the likelihood that you must/will quit self-employment within the 
* next 12 month?
*  1: very low 2: rather low 3: neutral 4: rather high 5: very high
tab Jahresvorraussage_1, mi

* check existing ordinal outcome variable
* ---------------------------------------
* Builds on 'Jahresvoraussage_1' but order is reversed. Allows for inverse 
* interpretation: Pr(exit)=very low -> Pr(survival)=very high
gen optimism = .
	replace optimism = 1 if Jahresvorraussage_1 == 5
	replace optimism = 2 if Jahresvorraussage_1 == 4
	replace optimism = 3 if Jahresvorraussage_1 == 3
	replace optimism = 4 if Jahresvorraussage_1 == 2
	replace optimism = 5 if Jahresvorraussage_1 == 1
label variable optimism "- Optimism: will survive (1-5)"	
tab optimism, mi

* generate binary outcome variable
* Pr(survival)=1 if likelihood to quit is "very low" == 1 | "rather low" ==1
* ------------------------------------------------------------------------------
gen survival_di2 = Jahresvorraussage_1
recode survival_di2 (1/2=1) (3/5=0) 
label de surv2 1 "likely survive" 0 "likely not survive", replace
label val survival_di2 surv2


********************************************************************************	
*					PART 4: Sample definition
********************************************************************************


cap: drop sample

* generate binary variable 'sample'
* ---------------------------------
gen sample = 1

* drop implausible values
* ----------------------- 
* I: application after survey date or long before program was launched
gen date_diff = date_quest - date_antrag
tab date_diff, mi
replace sample = 0 if (date_diff < 0 | date_diff > 100) & !missing(date_diff)

* II: application date before start of the program (conservative: 15-March-2020)
list Antragsdatum if date_antrag == 21989
replace sample = 0 if date_antrag < 21989 & !missing(date_antrag)

* venture is located outside of Germany
* -------------------------------------
replace sample = 0 if location == 17

* check number of observations
* ----------------------------
tab sample, mi


* remove observations with missings in covariates
* -----------------------------------------------
replace sample = 0 if age_cat ==. 
replace sample = 0 if Plan_AG2 == . 
replace sample = 0 if dig_vor_corona == .  
replace sample = 0 if risk_c == . 
replace sample = 0 if edu_cat ==. 
replace sample = 0 if industry_nace == . 
replace sample = 0 if Durststrecke3 == . 
* no observations lost:
replace sample = 0 if duration_se == . 
replace sample = 0 if gender == . 
replace sample = 0 if running_cost_2 == . 
replace sample = 0 if Hoehe_Umsatzrueckgang_2 == . 
replace sample = 0 if solvency_firm == . 
replace sample = 0 if solo_solo == . 
replace sample = 0 if week_quest == . 

* remove observations with missings in outcome variable
* -----------------------------------------------------
replace sample = 0 if survival_di2 ==.

* check number of observations
* ----------------------------
tab sample, mi


* save dataset for descriptive statistics
* ---------------------------------------
save "$input/TEMP1.dta", replace
keep if sample==1
save "$input/Datensatz_Deskriptives.dta", replace
use "$input/TEMP1.dta", clear

* remove observations with missings in treatment variable
* -------------------------------------------------------
gen sampleT = sample
replace sampleT = 0 if Masn_e2 == .
tab sampleT, mi


*==============================================================================*
* 							SAVE and CLEAN
*==============================================================================*

cap noi erase "$input/TEMP1.dta"
*save data
save "$input/Datensatz_Variables_v03.dta", replace

cap log close
********************************************************************************
* 									End
********************************************************************************
