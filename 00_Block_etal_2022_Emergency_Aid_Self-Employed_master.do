/*******************************************************************************
		     	Article: Emergency Aid for Self-Employed in the COVID-19 
							Pandemic: A Flash in the Pan? 
							
published in: Journal of Economic Psychology, 2022, 93(102567).
authors: Joern Block, Alexander S. Kritikos, Maximilian Priem, Caroline Stiel	
affiliations: Trier University, DIW Berlin, DIW-Econ		
				
********************************************************************************
													                 
																	 Do-File 00
	
							MASTER DO-FILE
						
		CONTENT:	Root file that manages the execution of all 
					subordinated do-files.
		
		OUTLINE:	PART 1:	Prepare work space
					PART 2: Run programs

					
--------------------------------------------------------------------------------
code authors: Maximilian Priem (DIWecon), Caroline Stiel (DIW Berlin)
version: 11-Feb-2021
--------------------------------------------------------------------------------

********************************************************************************
							PART 1: Work space preparation
*******************************************************************************/

clear all
set more off

*=========================================*
* 1.1 directories
*=========================================*

	global root /* insert your root directory*/

	global input			"$root\01_input"
	global scripts			"$root\02_scripts"
	global results			"$root\04_results"

*=========================================*
* 1.2 packages
*=========================================*

/*
//for frequencies
	ssc install fre
	
// package kmatch 
	ssc install kmatch 
	ssc install moremata
	ssc install kdens
	
//for coefplot
	net install gr0059_1.pkg, from(http://www.stata-journal.com/software/sj15-1/)
	
//for pstest
cap ssc install psmatch2
*/	

********************************************************************************
* 					PART 2: Run programs
********************************************************************************
/*

*===================================================*
*	2.1 Tranform data
*===================================================*

do "$scripts/01_Block_etal_2022_Emergency_Aid_Self-Employed_transformation.do"

*===================================================*
*	2.2 Generate variables 
*===================================================*

	do "$scripts/02_Block_etal_2022_Emergency_Aid_Self-Employed_variables.do"	
	
*===================================================*
*	2.3 Descriptive statistics 
*===================================================*

	do "$scripts/03_Block_etal_2022_Emergency_Aid_Self-Employed_descriptives.do"

*================================================================*
*	2.4 Propensity score matching and treatment effects analysis
*================================================================*

	do "$scripts/04_Block_etal_2022_Emergency_Aid_Self-Employed_treatmenteffects.do"
*/

		
********************************************************************************
* 								END
********************************************************************************		
