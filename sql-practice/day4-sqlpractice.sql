-- =====================================================================================================
-- DAY 4 : COMMON TABLE EXPRESSIONS
-- Maternal Health Analytics - Technical interview preparation
-- Date: February 15, 2026
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

WITH total_pregnancies_patient AS(
    -- CTE to calculate number of pregnancies per patient
    SELECT
        patient_id,
        COUNT(pregnancy_id) AS nb_preg_patient,
        MIN(lmp_date) AS first_preg_date,
        MAX(lmp_date) AS last_preg_date
    FROM raw.pregnancies
    GROUP BY patient_id
    HAVING COUNT(pregnancy_id) >= 2
),

number_months_pregnancies AS(
    -- Calculate number of months between pregnancies in months and number of pregnancy period(s)
    SELECT
        total_preg.patient_id,
        pat.first_name,
        pat.last_name,
        total_preg.first_preg_date,
        total_preg.last_preg_date,
        total_preg.nb_preg_patient AS tot_num_preg,
        EXTRACT(YEAR FROM AGE (last_preg_date, first_preg_date))*12 + EXTRACT(MONTH FROM AGE (last_preg_date, first_preg_date)) AS diff_preg_date_months,
        (total_preg.nb_preg_patient - 1) AS preg_period
    FROM total_pregnancies_patient AS total_preg
    INNER JOIN raw.patients AS pat
    ON total_preg.patient_id = pat.patient_id
),

average_month_preg AS(
        -- Calculate average number of months between pregnancies
    SELECT
        num_month_preg.patient_id,
        num_month_preg.first_name,
        num_month_preg.last_name,
        num_month_preg.tot_num_preg AS total_num_preg,
        num_month_preg.first_preg_date,
        num_month_preg.last_preg_date,
        num_month_preg.diff_preg_date_months,
        ROUND((num_month_preg.diff_preg_date_months * 1.0)/(num_month_preg.preg_period), 2) AS avg_month_bet_preg
FROM number_months_pregnancies AS num_month_preg
),

categorize_pregnancies AS(
    SELECT
        *,
        CASE
            -- When controlling the output, it has been noticed that some patients have pregnancies between 0 and 27 days apart.
            -- Therefore, the average number of months between pregnancies is returned as zero by the query.
            -- Medical literature states that pregnancies between 0 and 15 days apart are medically impossible.
            -- Furthermore, average number of months between pregnancies which are less than 9 months are medically suspicious.
            -- The averages calculated are mathematically correct but do not show variability: they do not tell the true story.
            -- These edge cases have therefore been flagged as a data quality issue which would require further investigation
            WHEN avg_preg.avg_month_bet_preg = 0
                THEN 'Investigate data ⚠️'
            WHEN avg_preg.avg_month_bet_preg < 9
                THEN 'Investigate data ⚠️'
            WHEN avg_preg.avg_month_bet_preg <= 18
                THEN 'Frequent'
            ELSE 'Spaced'
        END AS pregnancy_category
    FROM average_month_preg AS avg_preg
)

-- Final output rearranged in order of relevance
SELECT
        cat_preg.patient_id,
        cat_preg.first_name,
        cat_preg.last_name,
        cat_preg.total_num_preg,
        cat_preg.pregnancy_category,
        cat_preg.first_preg_date,
        cat_preg.last_preg_date,
        cat_preg.diff_preg_date_months,
        cat_preg.avg_month_bet_preg
FROM categorize_pregnancies AS cat_preg
ORDER BY cat_preg.avg_month_bet_preg DESC;

-- =====================================================================================================

-- Question 5

-- Build a complete dbt-style transformation:
-- (1) Source layer: raw pregnancies,
-- (2) Staging layer: clean and standardize,
-- (3) Intermediate layer: calculate risk scores,
-- (4) Marts layer: business-ready metrics with categories.
-- Final output: pregnancy_id, patient demographics, risk scores, risk category, ready for dashboard.


-- Pull raw data in the source layer from raw.pregnancies table
WITH source_layer AS(
    SELECT
        *
    FROM raw.pregnancies AS source
),

-- Verify and filter raw data to ensure data integrity
-- INNER JOIN raw.pregnancies to raw.patients to retrieve patient demographics
staging_layer AS(
    SELECT
        preg.pregnancy_id,
        preg.patient_id,
        pat.first_name,
        pat.last_name,
        pat.region,
        preg.pregnancy_number,
        preg.lmp_date AS first_preg_date,
        preg.edd AS estimated_delivery_date,
        preg.delivery_date,
        preg.maternal_age_at_delivery,
        preg.pre_pregnancy_bmi,
        preg.gestational_weeks,
        preg.initial_risk_score,
        preg.has_gestational_diabetes,
        preg.has_preeclampsia,
        preg.has_placental_issues,
        preg.is_multiple_gestation,
        preg.smoking_3rd_trimester,
        preg.alcohol_during_pregnancy,
        preg.cannabis_use,
        preg.covid_infection
    FROM source_layer AS preg
    INNER JOIN raw.patients AS pat
        ON pat.patient_id =preg.patient_id 
    WHERE preg.pregnancy_id IS NOT NULL
        AND preg.maternal_age_at_delivery IS NOT NULL
        AND preg.pre_pregnancy_bmi IS NOT NULL
),

-- Transform numeric and boolean columns in individual risk score to compute total risk score
-- and drop irrelevant columns
intermediate_risk_score AS(
    SELECT
        pregnancy_id,
        patient_id,
        first_name,
        last_name,
        region,
        maternal_age_at_delivery,
        pre_pregnancy_bmi,
        -- Calculate age_score (0-3 points) from maternal_age_at_delivery
        CASE
            WHEN maternal_age_at_delivery < 20 THEN 1
            WHEN maternal_age_at_delivery BETWEEN 35 and 39 THEN 2
            WHEN maternal_age_at_delivery >= 40 THEN 3
            ELSE 0
        END AS age_score,
        -- Calculate bmi_score (0-3 points) from pre_pregnancy_bmi
        CASE
            WHEN pre_pregnancy_bmi < 18.5 THEN 1
            WHEN pre_pregnancy_bmi BETWEEN 30 and 34.9 THEN 2
            WHEN pre_pregnancy_bmi >= 35 THEN 3
        ELSE 0
        END AS bmi_score,
        -- Calculate diabetes_score (0-2 points) from has_gestational_diabetes
        CASE
            WHEN has_gestational_diabetes = 't' THEN 2
            ELSE 0
        END AS diabetes_score,
        -- Calculate has_preeclampsia_score (0-2 points) from has_has_preeclampsia
        CASE
            WHEN has_preeclampsia = 't' THEN 2
            ELSE 0
        END AS preeclampsia_score
    FROM staging_layer
),

-- Calculate total risk score
calculate_risk_score AS(
    SELECT 
        tot_risk_score.*,
        (tot_risk_score.age_score + tot_risk_score.bmi_score + tot_risk_score.diabetes_score + tot_risk_score.preeclampsia_score) AS total_risk_score
    FROM intermediate_risk_score AS tot_risk_score
),

-- Categorize risk_score
categorize_risk_score AS(
    SELECT
        risk_cat.*,
        CASE
            WHEN risk_cat.total_risk_score <= 3 THEN 'Low'
            WHEN risk_cat.total_risk_score BETWEEN 4 AND 6 THEN 'Moderate'
            WHEN risk_cat.total_risk_score >= 7 THEN 'High'
        END AS risk_category
    FROM calculate_risk_score AS risk_cat
)

-- Dashboard-ready final select with columns in order of relevance
SELECT
    patient_id,
    pregnancy_id,
    first_name,
    last_name,
    region,
    risk_category,
    total_risk_score,
    age_score,
    bmi_score,
    diabetes_score,
    preeclampsia_score,
    maternal_age_at_delivery,
    pre_pregnancy_bmi    
FROM categorize_risk_score
ORDER BY total_risk_score DESC;

-- =====================================================================================================

-- =====================================================================================================
--                   DAY 4 - COMPLETE (COMMON TABLE EXPRESSIONS)
-- =====================================================================================================

-- Topics covered:
-- ✅ CTE basics
-- ✅ Multi-stage CTEs
-- ✅ dbt layering (source → staging → intermediate → marts)
-- ✅ Data quality awareness
 
-- =====================================================================================================-- 