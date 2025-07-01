--MEMBER SUMMARY

--Age groups
SELECT
CASE
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 0 AND
		DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date)
		<= 18 THEN '0-18'
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 19 AND
		DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date)
		<= 44 THEN '19-44'
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 45 AND
		DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date)
		<= 54 THEN '45-54'
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 55 AND
		DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date)
		<= 64 THEN '55-64'
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 65 AND
		DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date)
		<= 74 THEN '65-74'
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 75 AND
		DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date)
		<= 84 THEN '75-84'
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 85 THEN '85+'
	ELSE '0' END
	as age_grp
,COUNT(DISTINCT desynpuf_id)
FROM beneficiary_summary_10
GROUP BY 1
;

--MEMBER AGES
--0-18: 0
--19-44: 3,857 (3.4%)
--45-54: 5,244 (4.7%)
--55-64: 7,859 (7.0%)
--65-74: 41,059 (36.4%)
--75-84: 34,793 (30.9%)
--85+: 19,942 (17.7%)

--Total Members: 112,754

--Geography
SELECT 
--a.sp_state_code,
b.short_desc
,COUNT(DISTINCT a.desynpuf_id) as member_ct
,CONCAT((COUNT(DISTINCT a.desynpuf_id)*100)/112754,'%') as member_percent
FROM beneficiary_summary_10 a
JOIN state_codes b ON a.sp_state_code = b.state_cd
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

--TOP 10 STATES
--"CA"	9919	"8%"
--"FL"	7511	"6%"
--"TX"	6520	"5%"
--"NY"	6329	"5%"
--"PA"	5042	"4%"
--"OH"	4180	"3%"
--"IL"	4119	"3%"
--"MI"	3883	"3%"
--"NC"	3797	"3%"
--"NJ"	3085	"2%"

--Total Members: 112,754


--------------------------------------
--Segmentation

SELECT
CASE 
	WHEN bene_sex_ident_cd = '1' THEN 'Male'
	WHEN bene_sex_ident_cd = '2' THEN 'Female'
	ELSE '0' END as sex
,CASE 
	WHEN bene_race_cd = '1' THEN 'White'
	WHEN bene_race_cd = '2' THEN 'Black'
	WHEN bene_race_cd = '3' THEN 'Others'
	WHEN bene_race_cd = '5' THEN 'Hispanic'
	ELSE '0' END as race
,CASE
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 0 AND
		DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date)
		<= 18 THEN '0-18'
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 19 AND
		DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date)
		<= 44 THEN '19-44'
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 45 AND
		DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date)
		<= 54 THEN '45-54'
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 55 AND
		DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date)
		<= 64 THEN '55-64'
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 65 AND
		DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date)
		<= 74 THEN '65-74'
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 75 AND
		DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date)
		<= 84 THEN '75-84'
	WHEN DATE_PART('year','2010-12-31'::date)-DATE_PART('year',bene_birth_dt::date) 
		>= 85 THEN '85+'
	ELSE '0' END
	as age_grp
--,COUNT(DISTINCT a.desynpuf_id) as member_ct
--,ROUND(SUM(b.clm_pmt_amt)) as inpatient_pmt_amt
--,ROUND(SUM(c.clm_pmt_amt)) as outpatient_pmt_amt
,ROUND(SUM(b.clm_pmt_amt) + SUM(c.clm_pmt_amt)) as total_pmt_amt
--,ROUND((SUM(b.clm_pmt_amt) + SUM(c.clm_pmt_amt)) / COUNT(DISTINCT a.desynpuf_id)) 
--	 as total_pmt_per_member
FROM beneficiary_summary_10 a
RIGHT JOIN inpatient_claims b ON a.desynpuf_id = b.desynpuf_id
RIGHT JOIN outpatient_claims c ON a.desynpuf_id = c.desynpuf_id
WHERE b.clm_from_dt >= '2010-01-01'
AND c.clm_from_dt >= '2010-01-01'
GROUP BY 1,2,3
ORDER BY 4 DESC
;

--Top 10 segments by total payments per member
--"Male"	"Hispanic"	"65-74"	$141,655
--"Male"	"Hispanic"	"45-54"	$95,590
--"Female"	"Others"	"45-54"	$69,170
--"Male"	"Others"	"45-54"	$62,330
--"Male"	"Black"		"85+"	$58,800
--"Male"	"Others"	"75-84"	$58,661
--"Male"	"Black"		"75-84"	$56,567
--"Female"	"Others"	"19-44"	$56,442
--"Female"	"White"		"45-54"	$54,994
--"Male"	"Black"		"45-54"	$54,756

--Top 10 segments by total payments
--"Female"	"White"	"75-84"	$58,584,800
--"Male"	"White"	"65-74"	$43,143,670
--"Female"	"White"	"65-74"	$43,050,720
--"Female"	"White"	"85+"	$42,633,040
--"Male"	"White"	"75-84"	$40,363,420
--"Male"	"White"	"85+"	$24,117,870
--"Female"	"White"	"55-64"	$11,241,700
--"Male"	"White"	"55-64"	$9,191,320
--"Female"	"White"	"45-54"	$6,654,290
--"Female"	"Black"	"75-84"	$6,144,320

------------------------------------------
--Comorbidities

--inpatient comorbitidies
SELECT
a.icd9_dgns_cd_2
,c.short_desc
--,COUNT(DISTINCT a.clm_id) as inpatient_claim_ct
,ROUND(SUM(clm_pmt_amt))
FROM inpatient_claims a
LEFT JOIN dgns_codes c ON a.icd9_dgns_cd_2 = c.dgns_cd
WHERE a.clm_from_dt >= '2010-01-01'
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10;

--outpatient comorbidities
SELECT
a.icd9_dgns_cd_2
,c.short_desc
--,COUNT(DISTINCT a.clm_id) as outpatient_claim_ct
,ROUND(SUM(clm_pmt_amt))
FROM outpatient_claims a
LEFT JOIN dgns_codes c ON a.icd9_dgns_cd_2 = c.dgns_cd
WHERE a.clm_from_dt >= '2010-01-01'
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10;

--INPATIENT
--Top 10 Comorbidities by CLAIM CT (second diagnsosis code)
--"Hypertension NOS"			865
--"Hyperlipidemia NEC/NOS"		391
--"DMII wo cmp nt st uncntr"	321
--"Crnry athrscl natve vssl"	293
--"Esophageal reflux"			258
--"Atrial fibrillation"			256
--"CHF NOS"						247
--"Hypothyroidism NOS"			241
--"Urin tract infection NOS"	215
--"Chr airway obstruct NEC"		196

--Top 10 Comorbidities by PAYMENT AMT
--"Hypertension NOS"			7,278,600
--"Hyperlipidemia NEC/NOS"		3,115,880
--"DMII wo cmp nt st uncntr"	2,822,900
--"CHF NOS"						2,580,900
--"Crnry athrscl natve vssl"	2,578,000
--"Acute kidney failure NOS"	2,342,000
--"Urin tract infection NOS"	2,241,100
--"Esophageal reflux"			2,221,190
--"Atrial fibrillation"			2,140,000
--"Hypothyroidism NOS"			1,932,200

--

--OUTPATIENT
--Top 10 Comorbidities by claim count
--"Hypertension NOS"			6,809
--"DMII wo cmp nt st uncntr"	3,635
--"Long-term use anticoagul"	3,582
--"Hyperlipidemia NEC/NOS"		3,515
--"Long-term use meds NEC"		3,343
--"Hypothyroidism NOS"			1,799
--"Atrial fibrillation"			1,745
--"Benign hypertension"			1,588
--"Pure hypercholesterolem"		1,555
--"Anemia in chr kidney dis"	1,378

--Top 10 Comorbidities by PAYMENT AMT
--"Anemia in chr kidney dis"	2,320,860
--"Hypertension NOS"			1,868,280
--"Sec hyperparathyrd-renal"	1,709,060
--"Iron defic anemia NOS"		1,381,340
--"DMII wo cmp nt st uncntr"	899,490
--"Hyperlipidemia NEC/NOS"		737,790
--"Long-term use meds NEC"		729,630
--"Long-term use anticoagul"	417,830
--"Hypothyroidism NOS"			369,510
--"Pure hypercholesterolem"		349,070

--------------------------------------------
--Diagnosis by sex

--women
SELECT
a.icd9_dgns_cd_1
,d.short_desc
--,ROUND(SUM(a.clm_pmt_amt)) as inpatient_pmt_amt
--,ROUND(SUM(b.clm_pmt_amt)) as outpatient_pmt_amt
,ROUND(SUM(a.clm_pmt_amt)+SUM(b.clm_pmt_amt)) as ttl_pmt_amt
FROM inpatient_claims a
FULL OUTER JOIN outpatient_claims b ON a.desynpuf_id = b.desynpuf_id
LEFT JOIN beneficiary_summary_10 c ON a.desynpuf_id = c.desynpuf_id
	AND b.desynpuf_id = c.desynpuf_id
LEFT JOIN dgns_codes d ON a.icd9_dgns_cd_1 = d.dgns_cd
WHERE a.clm_from_dt >= '2010-01-01'
AND b.clm_from_dt >= '2010-01-01'
--AND bene_sex_ident_cd = '2' --female
AND bene_sex_ident_cd = '1' --male
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10
;

--Top 10 expensive diagnoses for WOMEN (inpatient + outpatient)
--"Septicemia NOS"				8,501,520
--"Rehabilitation proc NEC"		8,139,100
--"Pneumonia, organism NOS"		5,040,330
--"Subendo infarct, initial"	4,850,900
--"Crnry athrscl natve vssl"	4,400,690
--"Obs chr bronc w(ac) exac"	3,866,790
--"Loc osteoarth NOS-l/leg"		3,355,300
--"Aortic valve disorder"		3,084,030
--"Acute kidney failure NOS"	3,006,110
--"Urin tract infection NOS"	2,982,770

--Top 10 expensive diagnoses for MEN (inpatient + outpatient)
--"Crnry athrscl natve vssl"	6,752,410
--"Septicemia NOS"				6,583,590
--"Rehabilitation proc NEC"		6,266,430
--"Subendo infarct, initial"	4,134,520
--"Pneumonia, organism NOS"		3,605,360
--"Loc osteoarth NOS-l/leg"		3,136,050
--"Acute respiratry failure"	3,056,790
--"Aortic valve disorder"		2,402,260
--"Atrial fibrillation"			2,332,240
--"CHF NOS"						2,206,230