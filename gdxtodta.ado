*!v1.0.0 emunozsaavedra@worldbank.org - This a simplified version of gidddgximport.ado written by Israel Osorio.
cap program drop gdxtodta
program define gdxtodta, rclass
version 14.0

syntax, CGEPATH(string) SCENARIOS(string) GAMSPATH(string) [sets parameters variables]
qui {
	
	noi di ""
	noi di "-------------"
	noi di "- CGE Read -"
	noi di "-------------"
	noi di ""
	noi di "Extracting GDX scenario files for: `scenarios' "  
	noi di ""
	noi di "________________________________________________________________________________________________________________"
	noi di ""
	
	local num = 1
	foreach cgescen in `scenarios' {
	noi di "Scenario `num': `cgescen'"
	noi di ""
	
	cd "`cgepath'"
	
	if "`c(os)'"=="Windows" {
		local dumpexe "gdxdump.exe" 
		noi di `".    Executing... !"`gamspath'\\`dumpexe'"  "`cgepath'\\`cgescen'.gdx" output="`cgepath'\dump`cgescen'.txt""'
	                               !"`gamspath'\\`dumpexe'"  "`cgepath'\\`cgescen'.gdx" output="`cgepath'\dump`cgescen'.txt"
	}
	if "`c(os)'"=="MacOSX"  {
		local dumpexe "gdxdump"
		noi di `".    Executing... !"`gamspath'/`dumpexe'"  "`cgepath'/`cgescen'.gdx" output="`cgepath'/dump`cgescen'.txt""'
								   !"`gamspath'/`dumpexe'"  "`cgepath'/`cgescen'.gdx" output="`cgepath'/dump`cgescen'.txt"
	}

if "`sets'"!="" | ("`sets'"=="" & "`parameters'"=="" & "`variables'"=="") {	
	noi di ""
	noi di "Importing SETS to Stata .dta file"
	import delimited "`cgepath'/dump`cgescen'.txt", delimiter("*!", asstring) clear

	* Initial
		gen n = _n
		gen length = length(v1)
	
	* SETS
		gen setmark = (substr(v1,1,3)=="Set")
		gen endmark = (substr(v1,length,1)==";")
		
		gen idset = 0 if _n==1
		replace idset = idset[_n-1] + setmark if _n>1 
		replace idset = 0 if endmark[_n-1]==1 & setmark==0
		replace idset = idset[_n-1] + setmark if _n>1 & idset!=0	

		gen setopenposition  = strpos(v1,"(") if setmark==1
		gen setcloseposition = strpos(v1,")") if setmark==1
		gen setgroupposition = strpos(v1,"/") if setmark==1 
		
		keep if idset!=0
		
		* Need to add a condition when no sets are found
		
		* Set names
		gen setname = substr(v1,5,setopenposition-5) if setmark==1
		replace setname = setname[_n-1] if setname=="" & _n>1
	
		* Set labels
		gen setlabel = substr(v1,setcloseposition+2,setgroupposition-3-setcloseposition)
		replace setlabel = setlabel[_n-1] if setlabel=="" & _n>1
		
		* Set elements
		sort setname n
		by setname: gen ngroup = _n
		sort n
		
		gen set_e_openposition =    strpos(v1,"'")   if ngroup>1
		gen set_e_closeposition =  ustrpos(v1,"'",set_e_openposition+1) if ngroup>1
		gen setelement = substr(v1,set_e_openposition+1,set_e_closeposition-2)
		
		* Set element labels
		gen set_el_closeposition = ustrrpos(v1,",") if ngroup>1
		gen setelementlab = substr(v1, set_e_closeposition+2 , set_el_closeposition - set_e_closeposition - 2 )
		replace setelementlab = subinstr(setelementlab,"'","",6)
	
		* Export Sets
		keep n setname setlabel setelement setelementlab
		compress
		save "`cgepath'/CGE Sets `cgescen'.dta", replace	

		noi di "     ... CGE SETS file saved in `cgepath'/CGE Sets `cgescen'.dta"
		noi di ""
		noi di "________________________________________________________________________________________________________________"
		noi di ""	
		
}	

if "`parameters'"!="" | ("`sets'"=="" & "`parameters'"=="" & "`variables'"=="") {		
	noi di ""
	noi di "Importing PARAMETERS to Stata .dta file"
	import delimited "`cgepath'/dump`cgescen'.txt", delimiter("*!", asstring) clear		

	* Initial
		gen n = _n
		gen length = length(v1)
	
	* PARAMETERS
		gen parmark = (substr(v1,1,9)=="Parameter")
		gen endmark = (substr(v1,length-1,2)=="/;")	
		
		gen idpar = 0 if _n==1
		replace idpar = idpar[_n-1] + parmark if _n>1 
		replace idpar = 0 if endmark[_n-1]==1 & parmark==0
		replace idpar = idpar[_n-1] + parmark if _n>1 & idpar!=0	

		gen paropenposition  = strpos(v1,"(") if parmark==1
		gen parcloseposition = strpos(v1,")") if parmark==1
		gen pargroupposition = strpos(v1,"/") if parmark==1 
				
		keep if idpar!=0
		
		* Parameter name
			gen parameter = substr(v1,11,paropenposition-12) if parmark==1
			replace parameter = parameter[_n-1] if _n>1 & idpar!=0 & parmark!=1
		
		* Parameter label
			gen parlabel = substr(v1,parcloseposition+2,pargroupposition -2 -parcloseposition) if parmark==1
			replace parlabel = subinstr(parlabel,"'","",2)
			replace parlabel = parlabel[_n-1] if _n>1 & idpar!=0 & parmark!=1
		
		* Parameter elements
			gen parelems = substr(v1,paropenposition+1, parcloseposition-paropenposition-1)
			split parelems if parmark==1 , parse(",")
				scalar parmaxdims = r(nvars)
				local  _parelemslist `r(varlist)'
			drop parelems
			local t = parmaxdims 
			forval i = 1/`t' {
				replace parelems`i' = parelems`i'[_n-1] if _n>1 & idpar!=0 & parmark!=1
			}
		
		* Parameter values
		split v1 if idpar!=0 & parmark!=1, parse(" ")
			
			gen _lastv12 = substr(v12,length(v12),1)
			replace  v12 = substr(v12,1,length(v12)-1) if idpar!=0 & parmark!=1 & _lastv12==","
			replace v12 = "." if v12=="+Inf"
			replace v12 = "." if v12=="-Inf"
*			destring (v12), gen(parevaluation) 				
			destring (v12), gen(parevaluation) force /* modified on October 1, 2021 */
			split v11 if idpar!=0 & parmark!=1, parse(".") generate(parval)
				local t = parmaxdims
				forval i = 1/`t' {
					replace parval`i' = subinstr(parval`i',"'","",2)
				}	
		drop if parmark==1
		sort n
		keep  parameter parlabel parelems* parval* parevaluation
		compress
		order parameter parlabel parelems* parval* parevaluation
		
		* Export Parameters
		save "`cgepath'/CGE Parameters `cgescen'.dta", replace	

		noi di "     ... CGE PARAMETERS file saved in `cgepath'/CGE Parameters `cgescen'.dta"
		noi di ""
		noi di "________________________________________________________________________________________________________________"
		noi di ""			
}

if "`variables'"!="" | ("`sets'"=="" & "`parameters'"=="" & "`variables'"=="") {			
	noi di ""
	noi di "Importing VARIABLES to Stata .dta file"
	import delimited "`cgepath'/dump`cgescen'.txt", delimiter("*!", asstring) clear		

	* Initial
		gen n = _n
		gen length = length(v1)
	
	* VARIABLES
		gen varmark = strpos(v1,"Variable")
		gen varmark2 = strpos(v1,"Variable")
			replace varmark = 1 if varmark>1 & varmark!=.
		gen endmark = (substr(v1,length-1,2)=="/;")	
		
		gen idvar = 0 if _n==1
		replace idvar = idvar[_n-1] + varmark if _n>1 
		replace idvar = 0 if endmark[_n-1]==1 & varmark==0
		replace idvar = idvar[_n-1] + varmark if _n>1 & idvar!=0	

		gen varopenposition  = strpos(v1,"(") if varmark==1
		gen varcloseposition = strpos(v1,")") if varmark==1
		gen vargroupposition = strpos(v1,"/") if varmark==1 
				
		keep if idvar!=0
		
		* Variable name
			gen variable = substr(v1,varmark2+9,varopenposition-(varmark2+9)) if varmark==1
			
			gen _v1 = substr(v1,varmark2+9,100) if varmark==1 & (varopenposition==0 & varcloseposition==0)
			gen _blankpos = strpos(_v1," ") if _v1!=""
			replace variable = substr(_v1,1,_blankpos-1) if _v1!=""
			
			replace variable = variable[_n-1] if _n>1 & idvar!=0 & varmark!=1
		
		* Variable label
			gen varlabel = substr(v1,varcloseposition+2,vargroupposition -3 -varcloseposition) if varmark==1 & _v1==""
			
			gen vargroupposition2 = strpos(_v1,"/") if varmark==1  & _v1!=""
			replace varlabel = substr(_v1,_blankpos+1,vargroupposition2-_blankpos-2) if _v1!=""
			
			replace varlabel = subinstr(varlabel,"'","",2)
			replace varlabel = varlabel[_n-1] if _n>1 & idvar!=0 & varmark!=1
		
		* Variable elements
			gen varelems = substr(v1,varopenposition+1, varcloseposition-varopenposition-1)
			split varelems if varmark==1 , parse(",")
				scalar varmaxdims = r(nvars)
				local  _varelemslist `r(varlist)'
			drop varelems
			local t = varmaxdims 
			forval i = 1/`t' {
				replace varelems`i' = varelems`i'[_n-1] if _n>1 & idvar!=0 & varmark!=1
			}
		
		* Variable values
		split v1 if idvar!=0 & varmark!=1, parse(" ")
			
			gen _lastv12 = substr(v12,length(v12),1)
			replace  v12 = substr(v12,1,length(v12)-1) if idvar!=0 & varmark!=1 & _lastv12==","
			replace v12 = "." if v12=="+Inf"
			replace v12 = "." if v12=="-Inf"
			
			replace v12 = substr(_v1,vargroupposition2+2,length(_v1)-vargroupposition2-3) if _v1!=""
			
			destring (v12), gen(varevaluation) force				
			split v11 if idvar!=0 & varmark!=1, parse(".") generate(varval)
				local t = varmaxdims
				forval i = 1/`t' {
					replace varval`i' = subinstr(varval`i',"'","",2)
				}
				
		drop if varmark==1
		sort n
		keep  variable varlabel varelems* varval* varevaluation
		compress
		order variable varlabel varelems* varval* varevaluation

		* Export Variables
		save "`cgepath'/CGE Variables `cgescen'.dta", replace	

		noi di "     ... CGE VARIABLES file saved in `cgepath'/CGE Variables `cgescen'.dta"
		noi di ""
		noi di "________________________________________________________________________________________________________________"
		noi di ""			
}		
		
		local num = `num' + 1		
}


}	// quietly bracket

noi di ""
noi di " End of gdxtodta"
noi di ""
end

