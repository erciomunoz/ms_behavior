/* 
Example 3: Microsimulation with job queueing linked to a CGE
Date: 7/12/2022
*/
net install github, from("https://haghish.github.io/github/")
github install erciomunoz/ms_behavior

use Example3.dta,clear

/* Same matrices as example 1 */
{
mat gen_edu_age_shares = .0758835\.0230117\.0127541\.0322489\.033622\.0316504\.024508 ///
\.0322303\0\.0309548\.0148538\.0163911\.0231916\.022489\.0104595\.0027001\0\.0216652\ ///
.0430452\.0226705\.0146583\.0154868\.0066576\.0013731\.0819804\.0263535\.0153777 ///
\.0289435\.029335\.0232391\.0125791\.0136433\0\.0323096\.0188657\.0153483\.021913  ///
\.0242922\.0116992 \.0048066 \0 \.0191356 \.0354902 \.0257726 \.0164802 \.0170445 ///
\.0082729 \.0046124 

mat growth_laborincome = 157.66,131.62 \ 112.93,59.93 \ 99.19,76.11 \ 74.17,97.37 ///
 \ 82.15,90.63 \ 97.61,74.16 \ 90.63,66.22 \ 88.99,88.59 

mat sectoral_targets = .2164053 , .029479 \ .0015971 , .0011561 \ .0608484 , .0350391 \ ///
.0001848 , .0013321 \ .0331996 , .0086027 \ .0633268 , .0346651 \ .009947 , .0096049 \ ///
.019996 , .0538296 
}	

ms_reweight, age(age) edu(calif) gender(gender) hhsize(hsize) hid(hhid) ///
 iw(weight) country("Example") iyear(2002) tyear(2016) generate(wgtsim) match(HH) /// 
 popdata("population - Example3") variant("Medium-variant") targets(gen_edu_age_shares)

mat sector_shares_s1=1,.\2,.\3,.\4,.\5,.\6,.\7,.\8,.
mat sector_shares_s2=1,.\2,.\3,.\4,.\5,.\6,.\7,.\8,.
forvalues i=1(1)8 {
	qui sum labor_income [w=weight] if industry==`i' & skilled==0
	mat sector_shares_s1[`i',2]=r(mean)		
	qui sum labor_income [w=weight] if industry==`i' & skilled==1
	mat sector_shares_s2[`i',2]=r(mean)		
} 
mata : st_matrix("sector_shares_s1", sort(st_matrix("sector_shares_s1"), (-2)))	
mata : st_matrix("sector_shares_s2", sort(st_matrix("sector_shares_s2"), (-2)))	
mat order = sector_shares_s1[1...,1],sector_shares_s2[1...,1]
   
recode skilled 0=1 1=2		
qui ms_msecmove industry [w=wgtsim], oweight(weight) calif(skilled)  ///
 gen(sector_sim) sequence(order) industryshares(sectoral_targets) ///
 det(gender age age2 educy educy2 hsize) prob(Pr) 
	
	/* Mincer for movers */
recode sector_sim 99=.
qui gen lnY = ln(labor_income)
recode skilled 1=0 2=1

qui	ms_mincer_msector head male age age2 educy educy2 skilled [aw=wgt], ///
 origin(industry) destination(sector_sim) g(lnY_new) dep(lnY)		
qui gen Y_new = exp(lnY_new)
		
	/* Passing change in wages by sector/skill */
qui ms_wages labor_income [w=wgtsim], oweight(weight) /// 
 ysim(Y_new) skilled(skilled) ind(industry) newind(sector_sim) ///
 g(Y_new2) growth(growth_laborincome)
	 
g sim_labor_income = Y_new2
replace sim_labor_income=. if sim_labor_income==0
drop lnY lnY_new Y_new Y_new2


* github uninstall ms_behavior