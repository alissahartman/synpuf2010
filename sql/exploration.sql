---Data Exploration

--Check for duplicates
SELECT desynpuf_id, COUNT(*)
FROM beneficiary_summary_10
GROUP BY desynpuf_id
HAVING COUNT(*) >1
;

SELECT clm_id, COUNT(*)
--FROM inpatient_claims
FROM outpatient_claims
GROUP BY clm_id
HAVING COUNT(*) >1
;

SELECT *
--FROM inpatient_claims
FROM outpatient_claims
WHERE clm_id = '542562280982645'
;
--Why two rows for each of these claims? Claims can have 2 segments
--Effective with Version 'I', the system generated number used in conjunction 
--with the NCH daily process date to keep records/segments belonging to a specific 
--claim together. This field was added to ensure that records/ segments that come 
--in on the same batch with the same identifying information in the link group are 
--not mixed with each other.

--fixing column data types for claim payments
ALTER TABLE inpatient_claims
--ALTER COLUMN clm_pmt_amt 
--ALTER COLUMN nch_prmry_pyr_clm_pd_amt
--ALTER COLUMN clm_pass_thru_per_diem_amt
--ALTER COLUMN nch_bene_ip_ddctbl_amt
--ALTER COLUMN nch_bene_pta_coinsrnc_lblty_am
ALTER COLUMN nch_bene_blood_ddctbl_lblty_am
TYPE decimal(12,2)
USING clm_pmt_amt::decimal(12,2);

ALTER TABLE outpatient_claims
--ALTER COLUMN clm_pmt_amt 
--ALTER COLUMN nch_prmry_pyr_clm_pd_amt
--ALTER COLUMN nch_bene_ptb_ddctbl_amt
--ALTER COLUMN nch_bene_ptb_coinsrnc_amt
ALTER COLUMN nch_bene_blood_ddctbl_lblty_am
TYPE decimal(12,2)
USING clm_pmt_amt::decimal(12,2);

------------------------------------------
--Aggregations (2010 data)

SELECT 
ROUND(SUM(clm_pmt_amt)) as total_clm_pmt
,COUNT(DISTINCT clm_id) as clm_count
,ROUND(SUM(clm_pmt_amt)/COUNT(DISTINCT clm_id)) as pmt_per_clm
,ROUND(MIN(clm_pmt_amt)) as min_clm_pmt
,ROUND(MAX(clm_pmt_amt)) as max_clm_pmt
--FROM inpatient_claims
FROM outpatient_claims
WHERE clm_from_dt >= '2010-01-01'
	AND clm_from_dt <= '2010-12-31'
;

--INPATIENT CLAIMS 2010
--Claim count: 13,572
--Claim payments: $132,669,330
--Payments per claim: $9,775
--Minimum payment: -$3,000
--Maximum payment: $57,000

--OUTPATIENT CLAIMS 2010
--Claim count: 173,971
--Claim payments: $47,913,710
--Payments per claim: $275
--Minimum payment: -$100
--Maximum payment: $3,300

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
,COUNT(DISTINCT desynpuf_id)
FROM beneficiary_summary_10
GROUP BY 1--, 2
;

--MEMBER INFO
--Total Members: 112,754

--Female: 62,368 (55.3%)
--Male: 50,386 (44.7%)

--White: 93,343 (82.8%)
--Black: 11,962 (10.6%)
--Hispanic: 2,656 (2.4%)
--Others: 4,793 (4.3%)

------------------------------------
--Diagnosis Codes
SELECT a.icd9_dgns_cd_1, b.short_desc, COUNT(DISTINCT a.clm_id)
-- FROM outpatient_claims a
FROM inpatient_claims a
LEFT JOIN dgns_codes b ON a.icd9_dgns_cd_1 = b.dgns_cd
WHERE a.icd9_dgns_cd_1 IS NOT NULL 
	AND a.icd9_dgns_cd_1 != 'OTHER'
GROUP BY 1,2
ORDER BY 3 DESC
;

--remove leading 0s. some codes have letters so it has to be varchar.

SELECT icd9_dgns_cd_1
--FROM inpatient_claims
FROM outpatient_claims
WHERE icd9_dgns_cd_1 LIKE '0%'
GROUP BY 1
;

--UPDATE inpatient_claims
UPDATE outpatient_claims
SET icd9_dgns_cd_1 = TRIM(LEADING '0' FROM icd9_dgns_cd_1)
WHERE icd9_dgns_cd_1 LIKE '0%';