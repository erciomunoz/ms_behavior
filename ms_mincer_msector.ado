*! version 1.0.0 Ercio Munoz 12/11/2021
* Not a generic command, only for use within CGE-MS

* Program to impute income for movers	
cap program drop ms_mincer_msector
program define ms_mincer_msector
version 12.0

	syntax varlist [aweight/] [if], ORIGIN(string) DESTINATION(string) Generate(name) DEP(string)

// 	qui {
		
		ta `origin'
		local nsectors = r(r)
		
		tempvar fake_residual id Residuals rnd need_resid
			
		gen double `generate' = `dep'	
		gen double `Residuals' = .
		gen double `fake_residual' = .
		g `need_resid' = (`origin' == . & inrange(`destination',1,`nsectors'))
		g `rnd' = runiform()
		gsort `destination' - `need_resid' `rnd'
		bys `destination': gen `id' = _n
							
		* Estimating a separate Mincer regression for each sector 
		levelsof `origin', loc(sectors)
		foreach sector of numlist `sectors' {
	
			if "`if'"=="" {
				reg `dep' `varlist' [aw=`exp'] if `origin'==`sector' 
			}
			else {
				reg `dep' `varlist' [aw=`exp'] `if' & `origin'==`sector'
			}
			
			tempname b_`sector' sigma_`sector' Res`sector'
			mat `b_`sector''     = e(b)
			sca `sigma_`sector'' = e(rmse)
			predict `Res`sector'' if e(sample), resid
			replace `Residuals' = `Res`sector'' if e(sample)
			
		}
		 
	levelsof `origin', loc(osectors)
	levelsof `destination', loc(dsectors)

	foreach osector of numlist `osectors' {
	preserve
		keep if `origin' == `osector' & !missing(`Residuals')
		keep `Residuals'
		count 
		local N = r(N)		
		bsample `N'
		tempvar fake_residual_`osector'
		g double `fake_residual_`osector'' = `Residuals'
		g `id' = _n
		g `destination' = `osector'
		tempfile new_resid_`osector'
		save `new_resid_`osector''
	restore	
	}
	
	foreach dsector of numlist `dsectors' {	
		tempvar pred_`dsector'
		cap	mat score `pred_`dsector''  = `b_`dsector'' if `destination' == `dsector' 
		cap	replace `generate' = `pred_`dsector'' if `destination' == `dsector' & `origin'!=`destination' & inrange(`destination',1,`nsectors')
	}
	
	foreach osector of numlist `osectors' {
		foreach dsector of numlist `dsectors' {	
			cap	replace `generate' = `generate' + `Residuals' * ( `sigma_`dsector''/`sigma_`osector'' ) if `destination' == `dsector'  & `origin' == `osector' & `origin'!=`destination' & inrange(`destination',1,`nsectors')
		}
	}	

	foreach dsector of numlist `dsectors' {	
	merge 1:1 `id' `destination' using `new_resid_`dsector''
	drop if _merge==2
	drop _merge		
	replace `fake_residual'=`fake_residual_`dsector'' if `destination' == `dsector'  & `origin' == . & inrange(`destination',1,`nsectors')
	}
	
/*	count 
	local N = r(N)
	preserve
		keep `Residuals'
		bsample `N'
		g double `fake_residual' = `Residuals'
		g `id' = _n
		tempfile new_resid
		save `new_resid'
	restore
	g `id' = _n
	merge 1:1 `id' using `new_resid'
	drop _merge */
	
	replace `generate' = `generate' + `fake_residual' if `origin' == . & inrange(`destination',1,`nsectors')
	replace `generate' = . if `destination' ==. & inrange(`origin',1,`nsectors')
	
//	}

end


