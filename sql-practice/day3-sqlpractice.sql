-- =====================================================================================================
-- DAY 3 : CASE STATEMENTS, SUBQUERIES, DATE FUNCTIONS
-- Maternal Health Analytics - Technical interview preparation
-- Date: February 11 and February 12, 2026
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

-- Question 1
-- Classify all pregnancies by pre-pregnancy BMI category (Underweight <18.5, Normal 18.5-24.9, Overweight 25-29.9, Obese ≥30).
-- How many pregnancies fall into each category?"

-- Deconstruction:
--   - Need: pregnancy_id and pre_pregnancy_bmi (from pregnancies table)
--   - Granularity: national
--   - Functions to be used: COUNT(), CASE WHEN... THEN


SELECT
    COUNT
        (CASE
            WHEN pre_pregnancy_bmi < 18.5 THEN 1
        END) AS underweight,
    COUNT    
        (CASE
            WHEN pre_pregnancy_bmi BETWEEN 18.5 AND 24.9 THEN 1
        END) AS normal,
    COUNT
        (CASE
            WHEN pre_pregnancy_bmi BETWEEN 25 AND 29.9 THEN 1
        END) AS overweight,
    COUNT
        (CASE
            WHEN pre_pregnancy_bmi >= 30 THEN 1
        END) AS obese
FROM raw.pregnancies;


-- =====================================================================================================

-- Question 2
-- Show all deliveries where labor duration was longer than the overall average.
-- Include patient info and how much longer than average.

-- Deconstruction:
--   - Need: patient info (from patients table)
--   - Need: pregnancy_id (from pregnancies table)
--   - Need: labour_duration_minutes (from deliveries table)
--   - Connection 1: patient_id links patients table to pregnancies table
--   - Connection 2: pregnancy_id links pregnancies table to deliveries table
--   - Join type 1: INNER (only patients with deliveries will be listed)
--   - Join type 2: INNER (only patients who completed pregnancies with delivery records will be listed)
--   - Granularity: national
--   - Functions to be used: ROUND(), AVG()

SELECT
    pat.patient_id,
    pat.first_name,
    pat.last_name,
    EXTRACT(YEAR FROM AGE(del.delivery_date, pat.birth_date)) AS patient_age_at_delivery,
    del.labor_duration_minutes,
    -- Calculate overall average labor duration
    (SELECT
        ROUND(AVG(labor_duration_minutes), 2)
    FROM raw.deliveries) AS avg_labor_duration_minutes,
    del.labor_duration_minutes - (SELECT ROUND(AVG(labor_duration_minutes),2) FROM raw.deliveries) AS longer_than_average_in_minutes
FROM raw.patients AS pat
INNER JOIN raw.pregnancies AS preg
    ON pat.patient_id = preg.patient_id
INNER JOIN raw.deliveries AS del
    ON preg.pregnancy_id = del.pregnancy_id
WHERE del.labor_duration_minutes > (SELECT ROUND(AVG(labor_duration_minutes),2) FROM raw.deliveries)
ORDER BY longer_than_average_in_minutes DESC
LIMIT 10;

-- =====================================================================================================

-- Question 3
-- Calculate a pregnancy risk score (0-10) based on: maternal age (0-3 points),
-- BMI (0-3 points), gestational diabetes (0-2 points), preeclampsia (0-2 points).
-- Categorize as Low (0-3), Moderate (4-6), High (7-10).

-- Deconstruction:
--   - Need: pregnancy info (from pregnancies table)
--   - Granularity: national
--   - Function to be used: CASE WHEN... THEN
--   - Technique chosen: subquery

SELECT
    -- Retrieve all the fields of the inner query (pregnancy_scores)
    *,
    -- Establish risk_category based on total_risk_score
    CASE
        WHEN total_risk_score BETWEEN 0 AND 3 THEN 'Low risk'
        WHEN total_risk_score BETWEEN 4 AND 6 THEN 'Moderate risk'
        WHEN total_risk_score BETWEEN 7 AND 10 THEN 'High risk'
        ELSE 'Unknown'  -- Sanity check
    END AS risk_category
FROM(
    -- Inner query which calculates individual scores
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
        END AS preeclampsia_score,
        -- Total risk score (sum of all 4 scores)
        CASE
            WHEN maternal_age_at_delivery < 20 THEN 1
            WHEN maternal_age_at_delivery between 35 and 39 THEN 2
            WHEN maternal_age_at_delivery >= 40 THEN 3
            ELSE 0
        END
        +
        CASE
            WHEN pre_pregnancy_bmi < 18.5 THEN 1
            WHEN pre_pregnancy_bmi between 30 and 34.9 THEN 2
            WHEN pre_pregnancy_bmi >= 35 THEN 3
            ELSE 0
        END
        +
        CASE
            WHEN has_gestational_diabetes = 't' THEN 2
            ELSE 0
        END
        +
        CASE
            WHEN has_preeclampsia = 't' THEN 2
            ELSE 0
        END AS total_risk_score
    FROM raw.pregnancies) AS pregnancy_scores
    -- Filter out pregnancies with missing data
    WHERE maternal_age_at_delivery IS NOT NULL
      AND pre_pregnancy_bmi IS NOT NULL
    ORDER BY total_risk_score DESC
    LIMIT 10;

-- =====================================================================================================

-- Question 4
-- Show monthly delivery counts for 2024. Compare each month to the same month in 2023. Calculate percentage change.

-- Deconstruction:
--   - Need: deliveries info (from deliveries table)
--   - Granularity: national
--   - Function to be used: CASE WHEN... THEN, ROUND(), SUM(), GROUP BY

SELECT
    EXTRACT(MONTH FROM delivery_date) AS month_number,
    TO_CHAR(DATE_TRUNC('month', delivery_date), 'Month') AS month_name,
    SUM(
        CASE WHEN EXTRACT(YEAR FROM delivery_date) = 2023 THEN 1
            ELSE 0
        END
    ) AS deliveries_2023,
    SUM(
        CASE WHEN EXTRACT(YEAR FROM delivery_date) = 2024 THEN 1
            ELSE 0
        END
    ) AS deliveries_2024,
    ROUND(
        (100*(SUM(
            CASE WHEN EXTRACT(YEAR FROM delivery_date) = 2024 THEN 1
                ELSE 0
            END
        )
        -
        SUM(
            CASE WHEN EXTRACT(YEAR FROM delivery_date) = 2023 THEN 1
                ELSE 0
            END
        )))
        /
        SUM(
            CASE WHEN EXTRACT(YEAR FROM delivery_date) = 2023 THEN 1
                ELSE 0
            END
        ), 2
        ) AS percentage_change
FROM raw.deliveries
WHERE delivery_date >= '2023-01-01'
    AND delivery_date < '2025-01-01'
GROUP BY month_number, month_name
ORDER BY month_number;

-- =====================================================================================================

-- =====================================================================================================
--                   DAY 3 - COMPLETE (CASE STATEMENTS, SUBQUERIES, DATE FUNCTIONS)
-- =====================================================================================================

-- Topics covered:
--   ✅ Simple CASE WHEN for categorization (Q1: BMI categories)
--   ✅ Subqueries in WHERE clause (Q2: filter by average)
--   ✅ Subqueries in FROM clause/Derived tables (Q3: multi-step calculations)
--   ✅ Nested CASE WHEN for complex scoring (Q3: risk score calculation)
--   ✅ Multi-factor composite scores (Q3: sum of 4 CASE statements)
--   ✅ Date/time functions
--   ✅ String functions - TO_CHAR() (Q4: format month names)
--   ✅ Year-over-year analysis (Q4: 2023 vs 2024 comparison)
--   ✅ Percentage change calculations (Q4: growth rate formula)

-- =====================================================================================================