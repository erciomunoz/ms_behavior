*!v1.0 emunozsaavedra@worldbank.org - This a simplified version of gidddgximport.ado written by Israel Osorio.
cap program drop gdxtodta
program define gdxtodta, rclass
version 14.0

syntax, CGEPATH(string) SCENARIOS(string) GAMSPATH(string) [sets parameters variables gms]
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
		noi di `".    Executing... !"`gamspath'\\`dumpexe'"  "`cgepath'\\`cgescen'\\`cgescen'.gdx" output="`cgepath'\\`cgescen'\dump`cgescen'.txt""'
	                               !"`gamspath'\\`dumpexe'"  "`cgepath'\\`cgescen'\\`cgescen'.gdx" output="`cgepath'\\`cgescen'\dump`cgescen'.txt"
	}
	if "`c(os)'"=="MacOSX"  {
		local dumpexe "gdxdump"
		noi di `".    Executing... !"`gamspath'/`dumpexe'"  "`cgepath'/`cgescen'/`cgescen'.gdx" output="`cgepath'/`cgescen'/dump`cgescen'.txt""'
								   !"`gamspath'/`dumpexe'"  "`cgepath'/`cgescen'/`cgescen'.gdx" output="`cgepath'/`cgescen'/dump`cgescen'.txt"
	}

if "`sets'"!="" | ("`sets'"=="" & "`parameters'"=="" & "`variables'"=="") {	
	noi di ""
	noi di "Importing SETS to Stata .dta file"
	import delimited "`cgepath'/`cgescen'/dump`cgescen'.txt", delimiter("*!", asstring) clear

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
		save "`cgepath'/`cgescen'/CGE Sets `cgescen'.dta", replace	

		noi di "     ... CGE SETS file saved in `cgepath'/`cgescen'/CGE Sets `cgescen'.dta"
		noi di ""
		noi di "________________________________________________________________________________________________________________"
		noi di ""	
		
}	

if "`parameters'"!="" | ("`sets'"=="" & "`parameters'"=="" & "`variables'"=="") {		
	noi di ""
	noi di "Importing PARAMETERS to Stata .dta file"
	import delimited "`cgepath'/`cgescen'/dump`cgescen'.txt", delimiter("*!", asstring) clear		

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
		save "`cgepath'/`cgescen'/CGE Parameters `cgescen'.dta", replace	

		noi di "     ... CGE PARAMETERS file saved in `cgepath'/`cgescen'/CGE Parameters `cgescen'.dta"
		noi di ""
		noi di "________________________________________________________________________________________________________________"
		noi di ""			
}

if "`variables'"!="" | ("`sets'"=="" & "`parameters'"=="" & "`variables'"=="") {			
	noi di ""
	noi di "Importing VARIABLES to Stata .dta file"
	import delimited "`cgepath'/`cgescen'/dump`cgescen'.txt", delimiter("*!", asstring) clear		

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
		save "`cgepath'/`cgescen'/CGE Variables `cgescen'.dta", replace	

		noi di "     ... CGE VARIABLES file saved in `cgepath'/`cgescen'/CGE Variables `cgescen'.dta"
		noi di ""
		noi di "________________________________________________________________________________________________________________"
		noi di ""			
}		

if "`gms'"!="" {			
	* gdxdump to declare all elements of CGE model in GAMS - saved as gms file
	noi di "----------------------------------------"
	noi di " Creating input file dump`cgescen'.gms"
	noi di "----------------------------------------"
	noi di ""
	
	noi di `"     Executing... !"`gamspath'/`dumpexe'"  "`cgepath'/`cgescen'/`cgescen'.gdx" > "`cgepath'/`cgescen'/dump`cgescen'.gms""'
	!"`gamspath'/`dumpexe'"  "`cgepath'/`cgescen'/`cgescen'.gdx" > "`cgepath'/`cgescen'/dump`cgescen'.gms"
	
	file open myfile using read`cgescen'.gms, write replace
	noi di "-----------------------------------"
	noi di " Creating file read`cgescen'.gms"
	noi di "-----------------------------------"
	noi di ""
	
          file write myfile `"$"'
		  file write myfile `"include "./`cgescen'/dump`cgescen'.gms" "' _n
          file write myfile `"parameters   "' _n
          file write myfile `"       storeld(a,l,t) "Demand for labor by skill"   "' _n
          file write myfile `"       storeswage(a,l,t) "Sectoral wage by skill"   "' _n
          file write myfile `"       storexf(oa,t) "Aggregate real expenditures on goods and services"   "' _n
          file write myfile `"       storepf(oa,t) "Aggregate expenditure price index"   "' _n
          file write myfile `"       storexkf(h,k,t) "Demand for bundled commodities"   "' _n
          file write myfile `"       storepa(i,t) "Armington price"   "' _n
          file write myfile `"       storeyh(h,t) "Total household income"   "' _n
          file write myfile `"       storeyd(h,t) "Post-tax household income"   "' _n
          file write myfile `"       storexa(i,aa,t) "Armington demand"   "' _n		  
          file write myfile `"       storekapy(t) "Gross profits"   "' _n
		  file write myfile `"		 storetransfers(inst,instp,t) "Transfers across institutions"   "' _n
		  file write myfile `"       storegintd(t) "Institutions"   "' _n
		  file write myfile `"       storepop(cohorts, t) "Population"	"' _n
          file write myfile `";   "' _n
          file write myfile `"   "' _n
          file write myfile `"$"'
		  file write myfile `"gdxin "./"'
		  file write myfile `"`cgescen'"'
		  file write myfile `"/"'
		  file write myfile `"`cgescen'";   "' _n
          file write myfile `"$"'
		  file write myfile `"load storeld=ld.l   "' _n
          file write myfile `"$"'
		  file write myfile `"load storeswage=swage.l   "' _n
          file write myfile `"$"'
		  file write myfile `"load storexf=xf.l   "' _n
          file write myfile `"$"'
		  file write myfile `"load storepf=pf.l   "' _n
          file write myfile `"$"'
		  file write myfile `"load storexkf=xkf.l   "' _n
          file write myfile `"$"'
		  file write myfile `"load storepa=pa.l   "' _n
          file write myfile `"$"'
		  file write myfile `"load storeyh=yh.l   "' _n
          file write myfile `"$"'
		  file write myfile `"load storeyd=yd.l   "' _n
          file write myfile `"$"'
		  file write myfile `"load storexa=xa.l   "' _n		  
          file write myfile `"$"'
		  file write myfile `"load storekapy=kapy.l   "' _n		  		  
          file write myfile `"$"'
		  file write myfile `"load storetransfers=transfers.l   "' _n		  		  		  
          file write myfile `"$"'
		  file write myfile `"load storegintd=gintd.l   "' _n
		  file write myfile `"$"'
		  file write myfile `"load storepop=pop.l	"' _n
          file write myfile `"   "' _n
          file write myfile `"file SC"'
		  file write myfile `"`cgescen'  / "./"'
		  file write myfile `"`cgescen'"'
		  file write myfile `"/SC"'
		  file write myfile `"`cgescen'.csv"     / ;   "' _n
          file write myfile `"       SC`cgescen'.pc = 5;   "' _n
          file write myfile `"       SC`cgescen'.nd = 10 ;   "' _n
          file write myfile `"put SC`cgescen' ;   "' _n
          file write myfile `"put "TS1" "TS2" "TS3"   "TL1" "TL2" "TL3" "year" "value"        /   "' _n
          file write myfile `"loop((a,l,t),   "' _n
          file write myfile `"       put storeld.ts, a.ts, l.ts,          "ld", a.tl, l.tl, t.tl, storeld(a,l,t)  /   "' _n
          file write myfile `");   "' _n
          file write myfile `"loop((a,l,t),   "' _n
          file write myfile `"       put storeswage.ts, a.ts, l.ts,       "swage", a.tl, l.tl, t.tl, storeswage(a,l,t)        /   "' _n
          file write myfile `");   "' _n
          file write myfile `"loop((oa,t),   "' _n
          file write myfile `"       put storexf.ts, oa.ts, "",           "xf", oa.tl, "", t.tl, storexf(oa,t)        /   "' _n
          file write myfile `");   "' _n
          file write myfile `"loop((oa,t),   "' _n
          file write myfile `"       put storepf.ts, oa.ts, "",           "pf", oa.tl, "", t.tl, storepf(oa,t)        /   "' _n
          file write myfile `");   "' _n
          file write myfile `"loop((h,k,t),   "' _n
          file write myfile `"       put storexkf.ts, h.ts, k.ts,         "xkf", h.tl, k.tl, t.tl, storexkf(h,k,t)        /   "' _n
          file write myfile `");   "' _n
          file write myfile `"loop((i,t),   "' _n
          file write myfile `"       put storepa.ts, "", i.ts,            "ps", "", i.tl, t.tl, storepa(i,t)       /   "' _n
          file write myfile `");   "' _n
          file write myfile `"loop((h,t),   "' _n
          file write myfile `"       put storeyh.ts,  h.ts, "",         "yh",  h.tl, "", t.tl, storeyh(h,t)     /   "' _n
          file write myfile `");   "' _n
          file write myfile `"loop((h,t),   "' _n
          file write myfile `"       put storeyd.ts,  h.ts, "",         "yd",  h.tl, "", t.tl, storeyd(h,t)     /   "' _n
		  file write myfile `");   "' _n
          file write myfile `"loop((i,aa,t),   "' _n
          file write myfile `"       put storexa.ts,  i.ts, aa.ts,         "xa",  i.tl, aa.tl, t.tl, storexa(i,aa,t)     /   "' _n
          file write myfile `");   "' _n
          file write myfile `"loop((t),   "' _n
          file write myfile `"       put storekapy.ts,  "", "",         "kapy",  "", "", t.tl, storekapy(t)     /   "' _n
          file write myfile `");   "' _n
          file write myfile `"loop((inst,instp,t),   "' _n
          file write myfile `"       put storetransfers.ts,  inst.ts, instp.ts,         "transfers",  inst.tl, instp.tl, t.tl, storetransfers(inst,instp,t)     /   "' _n
          file write myfile `");   "' _n
          file write myfile `"loop((t),   "' _n
          file write myfile `"       put storegintd.ts,  "", "",         "gintd",  "", "", t.tl, storegintd(t)     /   "' _n
          file write myfile `");   "' _n
		  file write myfile `"loop((cohorts,t),	   "' _n
		  file write myfile `"       put storepop.ts,  cohorts.ts, "", "pop", cohorts.tl, "", t.tl, storepop(cohorts,t)   /    "' _n
		  file write myfile `");   "' _n
          file write myfile `"putclose ;   "' _n

	file close myfile
	
		noi di "     ----------------"
		noi di "      Executing GAMS"
		noi di "     ----------------"
		
		if "`c(os)'"=="Windows" {
			noi di "Windows"
			noi di `"    Executing... !"`gamspath'/gams" read`cgescen'		"'
			!"`gamspath'/gams" read`cgescen'		
			copy "`cgepath'/read`cgescen'.gms" "`cgepath'/`cgescen'/read`cgescen'.gms" , replace
			cap erase "`cgepath'/read`cgescen'.gms"
			cap erase "`cgepath'/read`cgescen'.lst"
			cap erase "`cgepath'/read`cgescen'.log"
			cap erase "`cgepath'/read`cgescen'.lxi"

		noi di "     ... GAMS file saved in `cgepath'/`cgescen'/read`cgescen'.gms"
		noi di "     ... CSV file saved in `cgepath'/`cgescen'/SC`cgescen'.csv"
		noi di "________________________________________________________________________________________________________________"
		noi di ""
		
		}

		if "`c(os)'"=="MacOSX" {
			noi di "MacOSX"
			noi di `"    Executing... !"`gamspath'/gams" read`cgescen'"'
			!"`gamspath'/gams" read`cgescen'		
			copy "`cgepath'/read`cgescen'.gms" "`cgepath'/`cgescen'/read`cgescen'.gms" , replace
			cap erase "`cgepath'/read`cgescen'.gms"
			cap erase "`cgepath'/read`cgescen'.lst"
			cap erase "`cgepath'/read`cgescen'.log"
			cap erase "`cgepath'/read`cgescen'.lxi"

		noi di "     ... GAMS file saved in `cgepath'/`cgescen'/read`cgescen'.gms"
		noi di "     ... CSV file saved in `cgepath'/`cgescen'/SC`cgescen'.csv"
		noi di "________________________________________________________________________________________________________________"
		noi di ""
		
		}
		
}		
		
		local num = `num' + 1		
}


}	// quietly bracket

noi di ""
noi di " End of IMPORT-GDX"
noi di ""
end

