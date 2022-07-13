*! version 1.0.0 Ercio Munoz 12/10/2021
* Not a generic command
* For use within "master.do" for the GIDD project

* Program to apply change in wages across sectors and skills (coming from the CGE) to labor income in the HH survey
cap program drop ms_wages
program define ms_wages, sortpreserve
version 12.0

syntax varlist(max==1) [aweight/], OWeight(string) YSim(string) IND(string) /*
*/ SKilled(string) NEWIND(string) Generate(string) GROWTH(string)
	  
   *qui {

	tempvar wage wagenew YsimEcotemp 
	g double `wage' = `varlist'	
	g double `wagenew' = `ysim'
	g double `YsimEcotemp' = . 	  
	  
    levelsof `ind', local(allinds)
    levelsof `skilled', local(skills)

	foreach aa of local allinds {
		local skillgroup = 1
		foreach ss of local skills {
			
			tempvar Ysim_`aa'_`ss' Y_`aa'_`ss'
			
			sum `wagenew' [w=`exp']   if `newind'==`aa' & `skilled'==`ss' 
			scalar `Ysim_`aa'_`ss'' = r(mean)
			
			sum `wage' [w=`oweight']  if `ind'==`aa' & `skilled'==`ss'
			scalar `Y_`aa'_`ss'' = r(mean)
		
			replace `YsimEcotemp' = `wagenew' * (`Y_`aa'_`ss''/`Ysim_`aa'_`ss'') * `growth'[`aa',`skillgroup'] if (`newind'==`aa' & `skilled'==`ss')
		
			local skillgroup = `skillgroup'+1
		}
	}  	  

	/* I re-center labor income to the original mean because change in wages are nominal and I have not assumed something for non-labor income */
/*
	sum `wage' [w=`oweight']
	scalar _labinc0 = r(mean)
	      
	sum `YsimEcotemp' [w=`exp']
	scalar _labinc1 = r(mean)
	  	  
	gen double `generate' = `YsimEcotemp'*(_labinc0/_labinc1)
*/  
	gen double `generate' = `YsimEcotemp'
  * }
   
end