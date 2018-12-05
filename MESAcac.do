clear
set more off
local date : di  %tdCY-N-D  daily("$S_DATE", "DMY")
log using  /Users/sussmanjb/Data/mesa/MesaCodeJBS/MesaCAC_`date',replace
display "$S_DATE"

* Jeremy Sussman and Venkatesh Murthy

/*
** this imports MESA data. It's slow, so I only did it once **
import delimited /Users/sussmanjb/Data/mesa/Primary/Exam1/Data/mesae1dres06192012.csv
 sum
save mesa1, replace
 use mesa1

keep mesaid-othhisp1 dm031c rbrach1 lbrach1 wtlb1 htcm1 bmi1c agatum1c-prcacgt01c afib1c /*   
	*/ hrtrate1 trig1-cepgfr1c  crp1 bphxage1-dbinsul1 aspnow1 fhha1c  /*
	 */ asacat1 htnmed1c a2a1c-ohga1c slf11c-thzd1c verir1c vasoda1c pkyrs1c  cig1c   /*
	 */ marital1 educ1 income1 agequit1 s1bp1 d1bp1 s2bp1 d2bp1 s3bp1 d3bp1 uabcat1c sb* db*
	 
clear
import delimited /Users/sussmanjb/Data/mesa/Primary/Events/CVD/Data/mesaevfu10_drepos_20150416.csv
	keep  mesaid fuptt prebase mi mitype mitt strk strktype strktt /*
		*/ tia tiatype tiatt dth dthtype dthtext dthtt  /*
		*/ chdh chdhtt chda chdatt cvdh cvdhtt cvda cvdatt 
	save mesafup, replace
	sum
	
merge 1:1 mesaid using mesa1	
save mesa, replace
*/

*** the main database. 
use mesa
sum


**** data cleaning
gen female = 0
	replace female =1 if gender ==0
gen male =0	
	replace male =1 if gender ==1
	
* Coding this as black vs. non-black, but actually the PCE score is for white and black 
* race1c  1 is white; 2 is asian; 3 is aa; 4 is hispanic; 
gen black = 0
	replace black =1 if race1c ==3
gen famhx = 0
	replace famhx = 1 if pmi1 ==1 | shrtatt1 == 1 | chrtatt1 == 1

* age variables
	gen age = age1c
	gen decade = floor(age1c/10)	
	gen lnage = ln(age)
	gen lnage2 = ln(age)^2

* BP Variables
	gen anyhtnmeds = 0
		replace anyhtnmeds =1 if htnmed1c ==1
	gen lntrtsbp = 0
		quietly replace lntrtsbp = ln(sbp1c) if(anyhtnmeds==1)
	gen lnuntrtsbp = 0
		quietly replace lnuntrtsbp = ln(sbp1c) if(anyhtnmeds==0)

gen crtsmoker = 0
	replace crtsmoker =1 if cgrcur1 ==1 | pipcur1 ==1 | cursmk1==1
gen lnchol = ln(chol1)
gen lnhdl = ln(hdl1)

* Data terms 
 gen lnage_lnchol     = lnage * lnchol
 gen lnage_lnhdl      = lnage * lnhdl
 gen lnage_lnuntrtsbp = lnage * lnuntrtsbp
 gen lnage_lntrtsbp   = lnage * lntrtsbp
 gen lnage_crtsmoker  = lnage * crtsmoker

 gen dm =0
	replace dm=1 if dm031c ==2 | dm031c ==3 | diabet ==1
	sum dm
 
 gen ascvd_10y = .
 
********************************************
*** CREATING THE POOLED COHORT EQUATIONS ***
********************************************

*************************
*** White Women score ***
*************************
quietly gen ascvd_wh_fe = -29.799 * lnage + 4.884 * lnage2 + 13.54 * lnchol + -3.114 * lnage_lnchol + -13.578 * lnhdl + 3.149 * lnage_lnhdl + 2.019 * lntrtsbp + 0 * lnage_lntrtsbp + 1.957 * lnuntrtsbp + 0 * lnage_lnuntrtsbp + 7.574 * crtsmoker + -1.665 * lnage_crtsmoker + 0.661 * dm 
quietly gen mean_ascvd_wh_fe = -29.18 // value from paper

* quietly replace ascvd_10y = 1-0.9665^exp(ascvd_wh_fe - mean_ascvd_wh_fe) if white==1 & female==1
quietly replace ascvd_10y = 1-0.9665^exp(ascvd_wh_fe - mean_ascvd_wh_fe) if black==0 & female==1
quietly drop ascvd_wh_fe mean_ascvd_wh_fe

*************************
*** black Women score ***
*************************
quietly gen ascvd_bl_fe = 17.114 * lnage + 0 * lnage2 + 0.940 * lnchol + 0 * lnage_lnchol + -18.920 * lnhdl + 4.475 * lnage_lnhdl + 29.291 * lntrtsbp + -6.432 * lnage_lntrtsbp + 27.820 * lnuntrtsbp + -6.087 * lnage_lnuntrtsbp + 0.691 * crtsmoker + 0 * lnage_crtsmoker + 0.874 * dm 
quietly gen mean_ascvd_bl_fe = 86.61 // value from paper

quietly replace ascvd_10y = 1-0.9533^exp(ascvd_bl_fe - mean_ascvd_bl_fe) if black==1 & female==1
quietly drop ascvd_bl_fe mean_ascvd_bl_fe

*************************
*** white male score ****
*************************
quietly gen ascvd_wh_ma = 12.344 * lnage + 0 * lnage2 + 11.853 * lnchol + -2.664 * lnage_lnchol + -7.990 * lnhdl + 1.769 * lnage_lnhdl + 1.797 * lntrtsbp + 0 * lnage_lntrtsbp + 1.764 * lnuntrtsbp + 0 * lnage_lnuntrtsbp + 7.837 * crtsmoker + -1.795 * lnage_crtsmoker + 0.658 * dm
quietly gen mean_ascvd_wh_ma = 61.18 // value from paper

* quietly replace ascvd_10y = 1-0.9144^exp(ascvd_wh_ma - mean_ascvd_wh_ma) if white==1 & male==1
quietly replace ascvd_10y = 1-0.9144^exp(ascvd_wh_ma - mean_ascvd_wh_ma) if black==0 & male==1
quietly drop ascvd_wh_ma mean_ascvd_wh_ma

*************************
*** black male score ****
*************************
quietly gen ascvd_bl_ma = 2.469 * lnage + 0 * lnage2 + 0.302 * lnchol + 0 * lnage_lnchol + -0.307 * lnhdl + 0 * lnage_lnhdl + 1.916 * lntrtsbp + 0 * lnage_lntrtsbp + 1.809 * lnuntrtsbp + 0 * lnage_lnuntrtsbp + 0.549 * crtsmoker + 0 * lnage_crtsmoker + 0.645 * dm
quietly gen mean_ascvd_bl_ma = 19.54 // value from paper

quietly replace ascvd_10y = 1-0.8954^exp(ascvd_bl_ma - mean_ascvd_bl_ma) if black==1 & male==1
quietly drop ascvd_bl_ma mean_ascvd_bl_ma

replace ascvd_10y=. if(ascvd_10y == 999)
	
sum ascv*

gen ascvd520 = 0
	replace ascvd520 =1 if ascvd_10y >0.0499999 & ascvd_10y<0.20000001

gen ascvd7520 = 0
	replace ascvd7520 =1 if ascvd_10y >0.075000 & ascvd_10y<0.20000001
	
	
************************************
***  MESA CALCULATORS	        ***
************************************
gen agat1 = agatp21c+1

gen cac0 = 0
	replace cac0 =1 if agatp21c==0


gen Terms = .
	replace Terms = (age * 0.0455) + (male * 0.7496) + (dm * 0.5168) /*
		*/ + (crtsmoker * 0.4732) + (chol1 * 0.0053) - (hdl1 * 0.0140) + (lipid1c * 0.2473) + /*
		*/ (sbp1c * 0.0085) + (anyhtnmeds * 0.3381) + (famhx * 0.4522) if race1c ==1

	replace Terms = (age * 0.0455) + (male * 0.7496) + (-0.2111) + (dm * 0.5168) /*
		*/ + (crtsmoker * 0.4732) + (chol1 * 0.0053) - (hdl1 * 0.0140) + (lipid1c * 0.2473) + /*
		*/ (sbp1c * 0.0085) + (anyhtnmeds * 0.3381) + (famhx * 0.4522) if race1c ==3
		
	replace Terms = (age * 0.0455) + (male * 0.7496) + (-0.5055) + (dm * 0.5168) /*
		*/ + (crtsmoker * 0.4732) + (chol1 * 0.0053) - (hdl1 * 0.0140) + (lipid1c * 0.2473) + /*
		*/ (sbp1c * 0.0085) + (anyhtnmeds * 0.3381) + (famhx * 0.4522) if race1c ==2
		
	replace Terms = (age * 0.0455) + (male * 0.7496) + (-0.19) + (dm * 0.5168) /*
		*/ + (crtsmoker * 0.4732) + (chol1 * 0.0053) - (hdl1 * 0.0140) + (lipid1c * 0.2473) + /*
		*/ (sbp1c * 0.0085) + (anyhtnmeds * 0.3381) + (famhx * 0.4522) if race1c ==4
		
gen mesaRisk = (1 - 0.99963^exp(Terms))

gen TermsCAC = .
	replace TermsCAC = (age * 0.0172) + (male * 0.4079) + (dm * 0.3892) /*
		*/ + (crtsmoker * 0.3717) + (chol1 * 0.0043) - (hdl1 * 0.0114) + (lipid1c * 0.1206) +  /*
		*/ (sbp1c * 0.0066) + (anyhtnmeds * 0.2278) + (famhx * 0.3239) + (ln(agat1) * 0.2743) if race1c ==1
		
	replace TermsCAC = (age * 0.0172) + (male * 0.4079) + (-0.3475) + (dm * 0.3892) /*
		*/ + (crtsmoker * 0.3717) + (chol1 * 0.0043) - (hdl1 * 0.0114) + (lipid1c * 0.1206) +  /*
		*/ (sbp1c * 0.0066) + (anyhtnmeds * 0.2278) + (famhx * 0.3239) + (ln(agat1) * 0.2743) if race1c ==2
		
	replace TermsCAC = (age * 0.0172) + (male * 0.4079) + (0.0353) + (dm * 0.3892) /*
		*/ + (crtsmoker * 0.3717) + (chol1 * 0.0043) - (hdl1 * 0.0114) + (lipid1c * 0.1206) +  /*
		*/ (sbp1c * 0.0066) + (anyhtnmeds * 0.2278) + (famhx * 0.3239) + (ln(agat1) * 0.2743)  if race1c ==3
		
	replace TermsCAC = (age * 0.0172) + (male * 0.4079) + (-0.0222) + (dm * 0.3892) /*
		*/ + (crtsmoker * 0.3717) + (chol1 * 0.0043) - (hdl1 * 0.0114) + (lipid1c * 0.1206) +  /*
		*/ (sbp1c * 0.0066) + (anyhtnmeds * 0.2278) + (famhx * 0.3239) + (ln(agat1) * 0.2743)  if race1c ==4
		
gen mesaCACRisk = (1 - 0.99833^exp(TermsCAC))	
	
sum mesa* asc*

*********************************************
*** Applying the ACC/AHA CPGs eligibility ***
*********************************************

/*In adults 40 to 75 years of age without diabetes mellitus and with LDL-C levels ≥70 mg/dL- 189 mg/dL
(≥1.8-4.9 mmol/L), at a 10-year ASCVD risk of ≥7.5% to 19.9%, if a decision about statin therapy is
uncertain, consider measuring CAC. If CAC is zero, treatment with statin therapy may be withheld or
delayed, except in cigarette smokers, those with diabetes mellitus, and those with a strong family
history of premature ASCVD. A CAC score of 1 to 99 favors statin therapy, especially in those ≥55 years
of age. For any patient, if the CAC score is ≥100 Agatston units or ≥75th percentile, statin therapy is
indicated unless otherwise deferred by the outcome of clinician–patient risk discussion.*/
*7.5-20. except cig, dm, fh

gen age4575 = 0
	replace age4575 =1 if age >44 & age <76
	drop if age <45
	drop if age >75

qui gen ldl190 =0
	qui replace ldl190=1 if ldl1 >190 & ldl1<500		
qui gen elig = 1
	
	count
drop if agatp21c ==.
	sum elig
	sum ascvd7520
replace elig = 0 	if ascvd7520==0   
	sum elig
	sum dm
replace elig = 0 	if dm==1
	sum elig
	sum cursmk1
replace elig = 0 	if cursmk1==1
	sum elig
	sum lipid1c
replace elig = 0 	if lipid1c ==1
	sum elig
	sum ldl190
replace elig = 0 	if ldl190 ==1
	sum elig
	
*** Counting risk factors ***
* Only the ones that are in the sample

gen rfcount = 0
	replace rfcount = rfcount+1 if female ==0
	replace rfcount = rfcount+1 if race1c == 2
	replace rfcount = rfcount+1 if sbpcp1>139
	replace rfcount = rfcount+1 if chol1>160
	replace rfcount = rfcount+1 if famhx>160
	replace rfcount = rfcount+1 if hdl1<40

foreach i in age female race1 sbpcp1 chol1 hdl1 dm {	
bysort cac0: sum `i'
}		


*** Figure 1a: Eligibility vs. age
mkspline age0 = age, cubic nknots(4)
	logistic elig age0*
	lroc, nograph
	predictnl eligP = predict(), ci(eligP_l eligP_u)  
	sort age	
twoway scatter eligP eligP_l eligP_u age, connect (L L L) msymbol (i i i ) /*
	*/ lwidth (thick medium medium) lcolor (black gs10 gs10) yscale(range(0.0 1)) ylabel(0 (0.2) 1) /*
	*/ ytitle("Probability of Being Appropriate for CAC Testing") xtitle("Age (years)") legend(off)
	graph export /Users/sussmanjb/Data/mesa/ageElig.pdf, replace

*** Figure 1b: Risk factors vs. age ****
twoway scatter rfcount age  if elig ==1, msymbol(i i i ) ||fpfitci rfcount age  if elig ==1, lcolor (black) lwidth (thick) alcolor(gs10) alwidth(medium medium) /*
	*/ fcolor(none) ytitle("ASCVD risk factors, other than age, number") xtitle("Age (years)") legend(off) /*
	*/  yscale(range(0 4))     ylabel(0 1 2 3 4,labcolor(navy))
graph export /Users/sussmanjb/Data/mesa/ageRF.pdf, replace


*** Figure 1c: % CAC0 vs. age ***
drop age0*
mkspline age0 = age  if elig ==1, cubic nknots(4)
    logistic cac0 age0*  if elig ==1
	lroc  if elig ==1, nograph
	predictnl cacP = predict()  if elig ==1, ci(cacP_l cacP_u)  
	sort age	
twoway scatter cacP cacP_l cacP_u age  if elig ==1, connect (L L L) msymbol (i i i ) /*
	*/ lwidth (thick medium medium) lcolor (black gs10 gs10) yscale(range(0.0 1)) ylabel(0 (0.2) 1) /*
	*/ ytitle("Probability of CAC = 0") xtitle("Age (years)") legend(off)
	graph export /Users/sussmanjb/Data/mesa/ageCac0.pdf, replace

	
** Note for Jeremy: 
** older versions of this have some analyses for the stuff I plan for later	

save mesa2, replace
 export delimited using "/Users/sussmanjb/Data/mesa/MesaForR.csv", replace	
	
log close
aaa

