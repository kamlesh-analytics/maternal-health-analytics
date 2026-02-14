-- =====================================================================================================
-- DAY 4 : COMMON TABLE EXPRESSIONS
-- Maternal Health Analytics - Technical interview preparation
-- Date: February 12, 2026
-- =====================================================================================================


-- =====================================================================================================
--                                          SETUP CHECK
-- =====================================================================================================

-- Connect to database
psql -U maternal_user -d maternal_health_db -h localhost

-- Enter password for maternal_user to access the database
-- If user is authenticated, the following prompt is displayed:
maternal_health db=>

-- Verify if tables exist
\dt raw.*

-- =====================================================================================================
--                  BUSINESS QUESTIONS IN PLAIN ENGLISH AND ASSOCIATED SQL QUERIES
-- =====================================================================================================

-- Question 1 :-- Show all deliveries where labor duration was longer than the overall average.
-- Include patient info and how much longer than average.
-- Refactor the Day 3 code (Question 2), written with subqueries, using a CTE for better efficiency

-- Deconstruction:
--   - Need: patient info (from patients table)
--   - Need: pregnancy_id (from pregnancies table)
--   - Need: labour_duration_minutes (from deliveries table)
--   - Connection 1: patient_id links patients table to pregnancies table
--   - Connection 2: pregnancy_id links pregnancies table to deliveries table
--   - Join type 1: INNER (only patients with deliveries will be listed)
--   - Join type 2: INNER (only patients who completed pregnancies with delivery records will be listed)
--   - Join type 3:CROSS JOIN attaches average_labor_duration_minutes to each delivery
--   - Granularity: national
--   - Functions to be used: ROUND(), AVG()

WITH average_labor AS(
    -- CTE to calculate average labor duration
    SELECT
        AVG(labor_duration_minutes) AS avg_labor
    FROM raw.deliveries
)

SELECT
    -- Retrieve the information needed from the CTE to calculate deliveries
    -- whode duration is greater han the average labor duration
    pat.patient_id,
    pat.first_name,
    pat.last_name,
    pat.region,
    del.labor_duration_minutes as effective_labor_duration_minutes,
    ROUND (avl.avg_labor, 2) as average_labor_duration_minutes,
    ROUND(del.labor_duration_minutes - avl.avg_labor, 2) AS difference_in_duration_minutes
FROM raw.patients AS pat
INNER JOIN raw.pregnancies AS preg
    ON pat.patient_id = preg.patient_id
INNER JOIN raw.deliveries as del
    ON preg.pregnancy_id = del.pregnancy_id
CROSS JOIN average_labor AS avl
WHERE del.labor_duration_minutes > avl.avg_labor
ORDER BY difference_in_duration_minutes DESC
LIMIT 10;

-- =====================================================================================================

-- Question 2
-- Calculate a pregnancy risk score (0-10) based on: maternal age (0-3 points),
-- BMI (0-3 points), gestational diabetes (0-2 points), preeclampsia (0-2 points).
-- Categorize as Low (0-3), Moderate (4-6), High (7-10).
-- Refactor the Day 3 code (Question 3) written with subqueries using a CTE

-- Deconstruction:
--   - Need: pregnancy info (from pregnancies table)
--   - Granularity: national
--   - Function to be used: CASE WHEN... THEN
--   - Technique chosen: CTEs

WITH individual_pregnancy_scores AS(
    -- CTE to calculate individual risk scores 
    SELECT
        pregnancy_id,
        maternal_age_at_delivery,
        -- Calculate age_score (0-3 points) from maternal_age_at_delivery
        CASE
            WHEN maternal_age_at_delivery < 20 THEN 1
            WHEN maternal_age_at_delivery between 35 and 39 THEN 2
            WHEN maternal_age_at_delivery >= 40 THEN 3
            ELSE 0
        END AS age_score,
        pre_pregnancy_bmi,
        -- Calculate bmi_score (0-3 points) from pre_pregnancy_bmi
        CASE
            WHEN pre_pregnancy_bmi < 18.5 THEN 1
            WHEN pre_pregnancy_bmi between 30 and 34.9 THEN 2
            WHEN pre_pregnancy_bmi >= 35 THEN 3
            ELSE 0
        END AS bmi_score,
        has_gestational_diabetes,
        -- Calculate diabetes_score (0-2 points) from has_gestational_diabetes
        CASE
            WHEN has_gestational_diabetes = 't' THEN 2
            ELSE 0
        END AS diabetes_score,
        has_preeclampsia,
        -- Calculate has_preeclampsia_score (0-2 points) from has_has_preeclampsia
        CASE
            WHEN has_preeclampsia = 't' THEN 2
            ELSE 0
        END AS preeclampsia_score
    FROM raw.pregnancies
    WHERE maternal_age_at_delivery IS NOT NULL
        AND pre_pregnancy_bmi IS NOT NULL
),
total_score AS(
    -- Calculte total risk score (sum of all 4 scores)
    SELECT
        *,
        (age_score + bmi_score + diabetes_score + preeclampsia_score) AS total_risk_score
    FROM individual_pregnancy_scores
),
categorized_total_score AS(
    -- Categorize total_risk_score as Low risk, Moderate risk and High risk
    SELECT
        *,
        CASE
            WHEN total_risk_score BETWEEN 0 AND 3 THEN 'Low risk'
            WHEN total_risk_score BETWEEN 4 AND 6 THEN 'Moderate risk'
            WHEN total_risk_score BETWEEN 7 AND 10 THEN 'High risk'
            ELSE 'Unknown'  -- Sanity check
        END AS risk_category
    FROM total_score
)

-- Select and rearrange final output with most important columns appearing first
-- Columns are explicitly listed instead of using a simple SELECT * statement to abide by
-- production-quality best practices and respect dbt standards, prevent cascading failures,
-- and improve code readability for stakeholders

SELECT
    pregnancy_id,
    risk_category,
    total_risk_score,
    age_score,
    bmi_score,
    diabetes_score,
    preeclampsia_score,
    maternal_age_at_delivery,
    pre_pregnancy_bmi,
    has_gestational_diabetes,
    has_preeclampsia   
FROM categorized_total_score
ORDER BY total_risk_score DESC
LIMIT 10;

-- =====================================================================================================

-- Question 3
-- For each region, calculate: total deliveries, cesarean rate, average maternal age, and average birth weight.
-- Then categorize regions as 'Above Average', 'Average', or 'Below Average' based on their cesarean rate
-- compared to the national average.

WITH national_statistics AS(
    -- CTE to calculate total deliveries, count number of deliveries where delivery mode
    -- is cesarean and calculate rate of caesarean on a national basis
    SELECT
        COUNT(*) AS total_deliveries,
        SUM(
            CASE WHEN delivery_mode = 'Cesarean'
                THEN 1
                Else 0
            END
        ) AS total_cesarean,
        ROUND(
            (100 * (SUM(
                    CASE WHEN delivery_mode = 'Cesarean'
                        THEN 1
                        Else 0
                        END)
                    )/COUNT(*)), 2
        ) AS nat_cesarean_rate
    FROM raw.deliveries
    WHERE delivery_id IS NOT NULL -- WHERE cause added for sanity check
),

birth_weights_per_delivery AS (
    -- Calculate average birth weight per delivery (for two or more babies in a delivery)
    -- This precaution is taken to account for deliveries with more than 1 baby 

    SELECT
        delivery_id,
        (ROUND(AVG(birth_weight_grams/1000.0), 2)) AS avg_birth_weight_kgs
    FROM raw.birth_outcomes
    GROUP BY delivery_id
),

regional_deliveries AS(
    -- Calculate total deliveries, total cesarean deliveries, average maternal age at delivery
    -- and average weight in kilogrammes for each region

    SELECT
        patient.region AS region,
        COUNT(*) AS reg_total_deliveries,
        SUM(
            CASE WHEN delivery_mode = 'Cesarean'
                THEN 1
                Else 0
            END
        ) AS reg_total_cesarean,
        (ROUND(AVG(maternal_age_at_delivery), 2)) AS reg_avg_mat_age,
        (ROUND(AVG(birth_weight.avg_birth_weight_kgs), 2)) AS reg_avg_birth_kgs
    FROM raw.patients AS patient
    INNER JOIN raw.pregnancies AS pregnant
        ON patient.patient_id = pregnant.patient_id
    INNER JOIN raw.deliveries AS deliver
        ON pregnant.pregnancy_id = deliver.pregnancy_id
    INNER JOIN birth_weights_per_delivery as birth_weight
        ON deliver.delivery_id = birth_weight.delivery_id
    GROUP BY patient.region
),

regional_cesarean_rate AS(
    
    -- Calculate regional rate and retrieve national cesarean rate calculated in the first CTE
        *,
        ROUND((100.0 * reg_del.reg_total_cesarean/reg_del.reg_total_deliveries), 2) AS reg_cesarean_rate,
        nat_stats.nat_cesarean_rate AS nat_ces_rate
    FROM regional_deliveries AS reg_del
    CROSS JOIN national_statistics as nat_stats
),

categorized_cesarean_rate AS(
    -- Create a category for each region with appropriate labels depending on regional/national comparison
    SELECT
        *,
        CASE
            WHEN reg_cesarean_rate > nat_ces_rate
                THEN 'Above average'
            WHEN reg_cesarean_rate = nat_ces_rate
                THEN 'Average'
            WHEN reg_cesarean_rate < nat_ces_rate
                THEN 'Below average'
        END AS cesarean_cat
    FROM regional_cesarean_rate
)

-- Final output rearranged in order of relevance
SELECT
    region,
    cesarean_cat,
    reg_cesarean_rate,
    nat_cesarean_rate,
    reg_total_deliveries,    
    reg_avg_mat_age,
    reg_avg_birth_kgs
FROM categorized_cesarean_rate
ORDER BY reg_cesarean_rate DESC;

-- =====================================================================================================

-- Question 4
-- Show patients who had multiple pregnancies. For each patient, show: total pregnancies, average time
-- between pregnancies (in months), first pregnancy date, last pregnancy date, and categorize as 'Frequent'
-- (≤18 months between) or 'Spaced' (>18 months between)."

WITH nb_pregnancies_patient AS (
    -- CTE to calculate number of pregnancies per patient 
    SELECT
        pregnancy_id,
        patient_id,
        lmp_date,
        delivery_date,
        COUNT(pregnancy_id) AS nb_pregnancies
    FROM raw.pregnancies
    GROUP BY pregnancy_id, patient_id, lmp_date, delivery_date
    LIMIT 9;

),

WITH nb_pregnancies_patient AS (
    SELECT
        *,
        pat.patient_id,
        COUNT(preg.pregnancy_id) AS nb_pregnancies
    FROM raw.patients AS pat
    INNER JOIN raw.pregnancies AS preg
    ON pat.patient_id = preg.patient_id
    GROUP BY pat.patient_id
    HAVING COUNT(pregnancy_id) >= 2
),



-- =====================================================================================================

-- Question 5
-- Rank facilities into quality tiers (Gold/Silver/Bronze) based on composite score: 30% cesarean rate
-- (lower is better), 40% preterm rate (lower is better), 30% average birth weight (2500-4000g is optimal).
-- Show top 10 facilities.

-- =====================================================================================================

-- Question 6
-- Compare pregnancy outcomes across 4 quarters of 2024. For each quarter, calculate: total
-- pregnancies, cesarean rate, preterm rate, average maternal age. Then calculate quarter-over-quarter
-- change for each metric.

-- =====================================================================================================

-- Question 7
-- Segment patients into 4 groups based on 2 dimensions: (1) Age: Young (<30) vs Mature (≥30),
-- (2) Risk: Low-risk (no diabetes, no preeclampsia) vs High-risk (has diabetes OR preeclampsia).
-- Show segment size and average birth weight for each segment.

-- =====================================================================================================

-- Question 8
-- Divide facilities into 3 equal groups (terciles) based on delivery volume:
-- High-volume (top 33%), Medium-volume (middle 33%), Low-volume (bottom 33%).
-- Compare cesarean rates across volume terciles.

-- =====================================================================================================

-- Question 9
-- Build a risk funnel showing how many pregnancies remain after each risk filter:
-- (1) Start with all pregnancies,
-- (2) Filter to age ≥35,
-- (3) Then filter to BMI ≥30,
-- (4) Then filter to has diabetes OR preeclampsia.
-- Show counts at each stage.

-- =====================================================================================================

-- Question 10
-- Build a complete dbt-style transformation:
-- (1) Source layer: raw pregnancies,
-- (2) Staging layer: clean and standardize,
-- (3) Intermediate layer: calculate risk scores,
-- (4) Marts layer: business-ready metrics with categories.
-- Final output: pregnancy_id, patient demographics, risk scores, risk category, ready for dashboard.

-- =====================================================================================================


-- =====================================================================================================
--                   DAY 4 - COMPLETE ()
-- =====================================================================================================

-- Topics covered:
--   ✅ 
--   ✅ 
--   ✅ 
--   ✅ 

-- =====================================================================================================