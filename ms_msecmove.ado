*! version 1.0.0 Ercio Munoz 6/23/2022
* Not a generic command 
* Command that implements algorithm where non-participants can enter any sector.

* Program to select movers given some exogenous migration rate	
cap program drop ms_msecmove
program define ms_msecmove, sortpreserve eclass
version 12.0

syntax varlist(max==1) [aweight/] [if] ,  						/*
*/	GENerate(name) OWEight(string) /*
*/	DETerministic(varlist) CALIF(string) PROB(string) INDUSTRYSHARES(string) SEQUENCE(string)
				
	qui {

	local expsector `varlist' // Variable with original sectors	 
	ta `expsector'
	local nindustries = r(r) // Number of sectors
	ta `calif'
	local ncalif = r(r) // Number of skill groups
			
	if "`if'" == "" g `generate' = 99 
	else  g `generate' = 99 `if'  // The sample of interest starts having 99 as sector 
	
	tempvar pool
	g `pool'= (`generate'==99) // Workers available to be allocated 
	
	* Estimating a multinomial logit to predict the probability of being on each sector
	if "`if'" == "" mlogit `expsector' `deterministic' [pw=`oweight']
			   else mlogit `expsector' `deterministic' [pw=`oweight'] `if' 
		            predict `prob'1-`prob'`nindustries', pr	
	
// We loop over skill group and sectors
forvalues s=1(1)`ncalif' {
		
	forvalues i=1(1)`nindustries' {
	local j = `sequence'[`i',`s'] // We go sector by sector according to wage level
	
	if "`if'" == "" {
		* Initial labour distribution
		qui sum `oweight' 
		scalar oweight_all = r(sum) /* counting all individuals at baseline */
		qui sum `oweight' if `calif'==`s' & `expsector'==`j'
		scalar oweight_`s'_`j' = r(sum) /* counting individuals skill s in industry j at baseline */

		* Final labour distribution
		qui sum `exp' 
		scalar nweight_all = r(sum) /* counting all individuals with new weights */
		qui sum `exp' if `calif'==`s' & `expsector'==`j'
		scalar nweight_`s'_`j' = r(sum) /* counting individuals skill s in industry j with new weights */
		qui sum `exp' if `calif'==`s' & `expsector'==`j' & `pool'==1
		scalar nweight_pool_`s'_`j' = r(sum) /* counting individuals skill s in industry j with new weights after some were reallocated */	
	}
	else {
		* Initial labour distribution
		qui sum `oweight' `if' 
		scalar oweight_all = r(sum) /* counting all individuals at baseline */
		qui sum `oweight' `if' & `calif'==`s' & `expsector'==`j'
		scalar oweight_`s'_`j' = r(sum) /* counting individuals skill s in industry j at baseline */

		* Final labour distribution
		qui sum `exp' `if' 
		scalar nweight_all = r(sum) /* counting all individuals with new weights */
		qui sum `exp' `if' & `calif'==`s' & `expsector'==`j' 
		scalar nweight_`s'_`j' = r(sum) /* counting individuals skill s in industry j with new weights */
		qui sum `exp' `if' & `calif'==`s' & `expsector'==`j' & `pool'==1
		scalar nweight_pool_`s'_`j' = r(sum) /* counting individuals skill s in industry j with new weights after some were reallocated */
	}
	
* Shares
scalar R_ini_`s'_`j' = oweight_`s'_`j'/oweight_all // Share of skill s at industry j at base year
	
* Targets  
scalar Target_share_`s'_`j'  = `industryshares'[`j',`s']
scalar Target_nwork_`s'_`j'  = (Target_share_`s'_`j') * nweight_all  // Target number of workers of skill s in sector j
scalar nmigrants_s`s'_a`j' = Target_nwork_`s'_`j' - nweight_pool_`s'_`j' // Difference between target and actual	
		
	if nmigrants_s`s'_a`j'>0 {		/* Sector j needs more workers with skill s */

	tempvar cumpop_s`s'_`j'
	replace `generate' = `j' if `pool'==1 & `expsector'==`j' & `calif'==`s' // Those available to be allocated that were in j stay in j
	replace `pool'     = 0   if `pool'==1 & `expsector'==`j' & `calif'==`s' // Already assigned, so we remove them from the pool
	gsort - `pool' - `prob'`j' 
	g `cumpop_s`s'_`j'' = sum(`exp') if `pool'==1 & `calif'==`s' 
	replace `generate' = `j' if `cumpop_s`s'_`j'' <= nmigrants_s`s'_a`j' & !missing(`cumpop_s`s'_`j'') // Assign those with highest prob. to sector j
	replace `pool'     = 0   if `cumpop_s`s'_`j'' <= nmigrants_s`s'_a`j' & !missing(`cumpop_s`s'_`j'') // Remove those allocated to j from the pool
	label var `generate' "Deterministic movement"	
	
	}	
	
	else { /* Sector that needs to kick workers out */
	
	tempvar cumpop_s`s'_`j' sector_`s'_`j'
	g `sector_`s'_`j'' = (`pool'==1 & `expsector'==`j' & `calif'==`s') // Indicates those that start in the sector 
	gsort - `sector_`s'_`j'' - `prob'`j' 
	g `cumpop_s`s'_`j'' = sum(`exp') if `sector_`s'_`j''==1 
	replace `generate' = `j' if `sector_`s'_`j''==1 & `cumpop_s`s'_`j'' <= Target_nwork_`s'_`j' & !missing(`cumpop_s`s'_`j'') // Allocating to j only those with highest prob.
	replace `pool' = 0       if `sector_`s'_`j''==1 & `cumpop_s`s'_`j'' <= Target_nwork_`s'_`j' & !missing(`cumpop_s`s'_`j'')
	label var `generate' "Deterministic movement"	
	}
	
		
	} // end of loop over industries
	
} // end of loop over skill groups
		
	} // quietly

end
