--COST

SELECT 
a.DESYNPUF_ID
,a.CLM_FROM_DT
,a.CLM_THRU_DT
,a.CLM_PMT_AMT as allowed_amount
,b.BENE_HI_CVRAGE_TOT_MONS as part_a_cvrage_mths
,b.BENE_HI_CVRAGE_TOT_MONS as part_b_cvrage_mths
,b.BENE_BIRTH_DT
,b.BENE_DEATH_DT
,c.short_desc as state
,b.MEDREIMB_IP
FROM inpatient_claims a
LEFT JOIN beneficiary_summary_10 b ON a.DESYNPUF_ID = b.DESYNPUF_ID
LEFT JOIN state_codes c ON b.sp_state_code = c.state_cd
WHERE 
a.CLM_FROM_DT BETWEEN '2010-01-01' AND '2010-12-31'
GROUP BY 1,2,3,4,5,6,7,8,9,10
LIMIT 10;


CREATE TEMP TABLE member_months AS(
  SELECT 
  DESYNPUF_ID
  ,CASE 
  	WHEN BENE_DEATH_DT IS NOT NULL AND DATE_PART('year',BENE_DEATH_DT) = 2010
	  	THEN DATE_PART('month',BENE_DEATH_DT)
    ELSE 12
    END AS months_enrolled
  FROM beneficiary_summary_10
);

CREATE TEMP TABLE costs_out AS(
  SELECT 
  DESYNPUF_ID
  ,SUM(CLM_PMT_AMT) AS total_cost
--  FROM inpatient_claims
  FROM outpatient_claims
  WHERE CLM_FROM_DT BETWEEN '2010-01-01' AND '2010-12-31'
  GROUP BY DESYNPUF_ID
);

SELECT 
  SUM(c.total_cost) / SUM(m.months_enrolled) AS PMPM
FROM costs_out c
INNER JOIN member_months m ON c.DESYNPUF_ID = m.DESYNPUF_ID;

--PER MEMBER PER MONTH
--2010 Inpatient PMPM: $947
--2010 Outpatient PMPM: $73


--Query for new table
-- Step 1: Estimate member-months from beneficiary file
WITH member_months AS (
  SELECT 
    DESYNPUF_ID,
    CASE 
      WHEN BENE_DEATH_DT IS NOT NULL 
           AND DATE_PART('year',BENE_DEATH_DT) = 2010
           THEN DATE_PART('month',BENE_DEATH_DT)
      ELSE 12
    END AS months_enrolled
  FROM beneficiary_summary_10), 

-- Step 2: Standardize inpatient claims
inpatient_costs AS (
  SELECT 
    DESYNPUF_ID,
    DATE_TRUNC('month', CLM_FROM_DT) AS claim_month,
    CLM_PMT_AMT AS allowed_amount,
    'Inpatient' AS claim_type
  FROM inpatient_claims
  WHERE CLM_FROM_DT BETWEEN '2010-01-01' AND '2010-12-31'), 

-- Step 3: Standardize outpatient claims
outpatient_costs AS (
  SELECT 
    DESYNPUF_ID,
    DATE_TRUNC('month', CLM_FROM_DT) AS claim_month,
    CLM_PMT_AMT AS allowed_amount,
    'Outpatient' AS claim_type
  FROM outpatient_claims
  WHERE CLM_FROM_DT BETWEEN '2010-01-01' AND '2010-12-31'), 

-- Step 5: Combine all claims
all_claims AS (
  SELECT * FROM inpatient_costs
  UNION ALL
  SELECT * FROM outpatient_costs), 

-- Step 6: Aggregate by member and month
monthly_costs AS (
  SELECT 
    DESYNPUF_ID AS member_id,
    claim_month,
    claim_type,
    SUM(allowed_amount) AS total_monthly_cost
  FROM all_claims
  GROUP BY DESYNPUF_ID, claim_month, claim_type) 

-- Step 7: Join with member-months to compute PMPM
SELECT
  mc.member_id,
  mc.claim_month,
  mc.claim_type,
  mc.total_monthly_cost,
  mm.months_enrolled
INTO monthly_member_cost
FROM monthly_costs mc
JOIN member_months mm ON mc.member_id = mm.DESYNPUF_ID
--LIMIT 10
;

SELECT
claim_type,
claim_month,
ROUND(SUM(total_monthly_cost) / SUM(months_enrolled)) as PMPM
FROM monthly_member_cost
GROUP BY 1,2
ORDER BY 1 ASC, 2 ASC;

----------------------------------
--PROCEDURES

SELECT
a.icd9_prcdr_cd_1
,c.short_desc
--,COUNT(DISTINCT a.clm_id) as inpatient_claim_ct
,ROUND(SUM(clm_pmt_amt))
FROM outpatient_claims a
LEFT JOIN prcdr_codes c ON a.icd9_prcdr_cd_1 = c.prcdr_cd
WHERE a.clm_from_dt >= '2010-01-01'
AND a.icd9_prcdr_cd_1 IS NOT NULL
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10;

--Top 10 Inpatient Procedures by Cost
--"Total knee replacement"		$4,783,100
--"PTCA"						$3,817,000
--"Cont inv mec ven 96+ hrs"	$3,014,000
--"Packed cell transfusion"		$2,832,000
--"Venous cath NEC"				$2,303,700
--"Hemodialysis"				$2,112,000
--"Total hip replacement"		$1,710,000
--"Cont inv mec ven <96 hrs"	$1,676,000
--"Lumb/lmbsac fus ant/post"	$1,608,000
--"Left heart cardiac cath"		$1,485,800

--Top 10 Outpatient Procedures by Cost
--"Spinal canal explor NEC"		$3,000
--"Hemodialysis"				$1,680
--"Closed bronchial biopsy"		$1,260
--"Egd with closed biopsy"		$1,200
--"Percutan aspiration gb"		$1,100
--"Temporary tracheostomy"		$900
--"Endo polpectomy lrge int"	$700
--"Venous cath NEC"				$520
--"Left heart cardiac cath"		$500
--"Cl reduc disloc-shoulder"	$500

--Export common codes for Tableau reference
SELECT
icd9_dgns_cd_1
,ROUND(SUM(clm_pmt_amt))
FROM outpatient_claims
WHERE clm_from_dt >= '2010-01-01'
AND icd9_prcdr_cd_1 IS NOT NULL
GROUP BY 1
HAVING SUM(clm_pmt_amt) > 0
ORDER BY 2 DESC
;


----------------------------------------
--How much of total costs are driven by the top 5% of members

WITH ranked_members AS (
  SELECT
    member_id,
	claim_type,
    total_monthly_cost,
    NTILE(20) OVER (ORDER BY total_monthly_cost DESC) AS cost_percentile
  FROM monthly_member_cost
  WHERE total_monthly_cost > 0
),

final_agg AS (
  SELECT
  	claim_type,
    SUM(CASE WHEN cost_percentile = 1 THEN total_monthly_cost ELSE 0 END) AS top_5_cost,
    SUM(total_monthly_cost) AS total_cost_all
  FROM ranked_members
  GROUP BY 1
)

SELECT 
  claim_type,
  top_5_cost,
  total_cost_all,
  ROUND(100.0 * top_5_cost / total_cost_all, 2) AS pct_of_total_cost_from_top_5
FROM final_agg
;

--Percent of Total Medicare Costs Driven by the Top 5% of Members
--Outpatient: 2% of $47,927,270
--Inpatient: 83% of $132,675,010

-----------------------------------------------------------

--UTILIZATION

--Visits per 1,000 members

SELECT
COUNT(DISTINCT a.clm_id) as clm_ct
,COUNT(DISTINCT b.desynpuf_id) as member_ct
,COUNT(DISTINCT a.clm_id)/(COUNT(DISTINCT b.desynpuf_id)/1000) as clms_per_1000_members
FROM outpatient_claims a
FULL OUTER JOIN beneficiary_summary_10 b ON a.desynpuf_id = b.desynpuf_id
WHERE a.clm_from_dt >= '2010-01-01'
;

--Inpatient: 1,233 claims per 1,000 members
--Outpatient: 3,221 claims per 1,000 members

SELECT
COUNT(DISTINCT a.clm_id)+COUNT(DISTINCT b.clm_id) as clm_ct
,COUNT(DISTINCT c.desynpuf_id) as member_ct
,(COUNT(DISTINCT a.clm_id)+COUNT(DISTINCT b.clm_id)) / COUNT(DISTINCT c.desynpuf_id)
	as claims_per_member
FROM inpatient_claims a
FULL OUTER JOIN outpatient_claims b
	ON a.desynpuf_id = b.desynpuf_id
FULL OUTER JOIN beneficiary_summary_10 c 
	ON a.desynpuf_id = c.desynpuf_id
	AND b.desynpuf_id = c.desynpuf_id
WHERE a.clm_from_dt >= '2010-01-01'
AND b.clm_from_dt >= '2010-01-01'
;

--Total services per member: 4

--CLAIM TYPE COST COMPARISON
SELECT
SUM(a.clm_pmt_amt) as inpatient_cost
,COUNT(DISTINCT a.clm_id) as inpatient_clms
,ROUND(SUM(a.clm_pmt_amt) / COUNT(DISTINCT a.clm_id)) as inpatient_cost_per_clm
,SUM(b.clm_pmt_amt) as outpatient_cost
,COUNT(DISTINCT b.clm_id) as outpatient_clms
,ROUND(SUM(b.clm_pmt_amt) / COUNT(DISTINCT b.clm_id)) as outpatient_cost_per_clm
FROM inpatient_claims a
FULL OUTER JOIN outpatient_claims b
	ON a.desynpuf_id = b.desynpuf_id
WHERE a.clm_from_dt >= '2010-01-01'
AND b.clm_from_dt >= '2010-01-01'
;

--Average claim costs
--Inpatient: $36,641
--Outpatient: $384