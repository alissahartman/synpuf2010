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