-- =====================================================================================================
-- DAY 1 (SESSION 1): WARM-UP SESSION [SQL FOUNDATIONS]
-- Maternal Health Analytics - Technical interview preparation
-- Date: February 8, 2026
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

-- Quick check row count in each individual table:
SELECT COUNT(*) FROM raw.patients;
SELECT COUNT(*) FROM raw.pregnancies;
SELECT COUNT(*) FROM raw.prenatal_visits;
SELECT COUNT(*) FROM raw.deliveries;
SELECT COUNT(*) FROM raw.birth_outcomes;


-- Quick check row counts for all five tables in a go:
SELECT 'patients' AS table_name, COUNT(*) AS rows FROM raw.patients
UNION ALL
SELECT 'pregnancies', COUNT(*) FROM raw.pregnancies
UNION ALL
SELECT 'prenatal_visits', COUNT(*) FROM raw.prenatal_visits
UNION ALL
SELECT 'deliveries', COUNT(*) FROM raw.deliveries
UNION ALL
SELECT 'birth_outcomes', COUNT(*) FROM raw.birth_outcomes;

-- See columns in each table:
\d raw.patients
\d raw.pregnancies
\d raw.prenatal_visits
\d raw.deliveries
\d raw.birth_outcomes

-- =====================================================================================================
--                  PART 1: STRUCTURED QUERY LANGUAGE FUNDAMENTALS REVIEW
-- =====================================================================================================

-- BUSINESS QUESTIONS IN PLAIN ENGLISH AND ASSOCIATED SQL QUERIES

-- =====================================================================================================

-- Question 1
-- Show me the first 10 rows of the 'patients' table with patient_id, first_name, last_name and region

SELECT 
    patient_id,
    first_name,
    last_name,
    region
FROM raw.patients
ORDER BY patient_id
LIMIT 10;

-- =====================================================================================================

-- Question 2
-- Show me all deliveries from Type III facilities where the delivery mode was Cesarean

SELECT *
FROM raw.deliveries
WHERE facility_type = 'Type III'
    AND delivery_mode = 'Cesarean';

-- =====================================================================================================

-- Question 3
-- How many patients are there in each region?

SELECT
    region AS Region,
    COUNT(*) AS Patient_count
FROM raw.patients
GROUP BY region
ORDER BY Patient_count DESC;

-- =====================================================================================================

-- Question 4
-- Find the 5 youngest mothers (by maternal age at delivery)

SELECT
    pregnancy_id,
    patient_id,
    maternal_age_at_delivery
FROM raw.pregnancies
ORDER BY maternal_age_at_delivery ASC
LIMIT 5;

-- =====================================================================================================

-- Question 5
-- Show me all patients who don't have health insurance

SELECT
    patient_id,
    first_name,
    last_name
FROM raw.patients
WHERE has_health_insurance = FALSE;

-- =====================================================================================================

-- Question 6
-- What's the average birth weight by infant sex?

SELECT
    sex,
    ROUND(AVG(birth_weight_grams), 2) AS Average_birth_weight_in_grams
FROM raw.birth_outcomes
GROUP BY sex
ORDER BY Average_birth_weight_in_grams DESC;

-- =====================================================================================================

-- Question 7
-- Find the 10 longest labor durations

SELECT
    delivery_id,
    pregnancy_id,
    labor_duration_minutes
FROM raw.deliveries
ORDER BY labor_duration_minutes DESC
LIMIT 10;

-- =====================================================================================================
--                   DAY 1 - SESSION 1 COMPLETE (WARM-UP - FUNDAMENTALS REVIEW)
-- =====================================================================================================

-- Topics covered:
--   ✅ SELECT basics
--   ✅ WHERE filtering
--   ✅ ORDER BY sorting
--   ✅ LIMIT
--   ✅ GROUP BY
--   ✅ COUNT(), AVG() aggregates
--   ✅ ROUND() function
--   ✅ Boolean filtering

-- =====================================================================================================

-- =====================================================================================================
--                                 DAY 1 (SESSION 2): JOINs PROFICIENCY
--                                      Date: February 9, 2026
-- =====================================================================================================

-- BUSINESS QUESTIONS IN PLAIN ENGLISH AND ASSOCIATED SQL QUERIES USING JOINS

-- =====================================================================================================

-- Question 1
-- I need to see patient details along with their pregnancy data

-- Deconstruction:
--   - Need: patient details (from patients table)
--   - Need: pregnancy details (from pregnancies table)
--   - Connection: patient_id links both tables
--   - Join type: INNER (only patients who HAVE pregnancies)

SELECT
    pat.patient_id,
    pat.first_name,
    pat.last_name,
    pat.birth_date,
    pat.region,
    preg.*
FROM raw.patients AS pat
INNER JOIN raw.pregnancies preg
    ON pat.patient_id = preg.patient_id
LIMIT 5;
-- =====================================================================================================

-- Question 2
-- How many pregnancies does each patient have?

SELECT
    pat.patient_id,
    pat.first_name,
    pat.last_name,
    COUNT(preg.pregnancy_id) AS nb_pregnancy
FROM raw.patients AS pat
INNER JOIN raw.pregnancies AS preg
    ON pat.patient_id = preg.patient_id
GROUP BY pat.patient_id, pat.first_name, pat.last_name
ORDER BY nb_pregnancy DESC
LIMIT 5;

-- =====================================================================================================

-- Question 3
-- Show me only patients who had 2 or more pregnancies

SELECT
    pat.patient_id,
    pat.first_name,
    pat.last_name,
    COUNT(preg.pregnancy_id) AS nb_pregnancy
FROM raw.patients AS pat
INNER JOIN raw.pregnancies preg
    ON pat.patient_id = preg.patient_id
GROUP BY pat.patient_id, pat.first_name, pat.last_name
HAVING COUNT(preg.pregnancy_id) > 1
ORDER BY nb_pregnancy DESC
LIMIT 5;

-- =====================================================================================================

-- Question 4
-- Get all patients, including those without pregnancies

-- Deconstruction:
--   - Need: patient details (from patients table)
--   - Need: pregnancy details (from pregnancies table)
--   - Connection: patient_id links both tables
--   - Join type: LEFT (all patients, even those without pregnancies, will be listed)

SELECT
    pat.patient_id,
    pat.first_name,
    pat.last_name,
    pat.birth_date,
    pat.region,
    preg.*
FROM raw.patients AS pat
LEFT JOIN raw.pregnancies AS preg
    ON pat.patient_id = preg.patient_id
LIMIT 5;

-- =====================================================================================================

-- Question 5
-- How many pregnancies does each patient have?

SELECT
    pat.patient_id,
    pat.first_name,
    pat.last_name,
    pat.birth_date,
    pat.region,
    COUNT(preg.pregnancy_id) AS nb_pregnancy
FROM raw.patients AS pat
LEFT JOIN raw.pregnancies AS preg
    ON pat.patient_id = preg.patient_id
GROUP BY pat.patient_id, pat.first_name, pat.last_name, pat.birth_date, pat.region
ORDER BY nb_pregnancy DESC
LIMIT 5;

-- =====================================================================================================

-- Question 6
-- Find patients with multiple pregnancies

SELECT
    pat.patient_id,
    pat.first_name,
    pat.last_name,
    pat.birth_date,
    pat.region,
    COUNT(preg.pregnancy_id) AS nb_pregnancy
FROM raw.patients AS pat
LEFT JOIN raw.pregnancies AS preg
    ON pat.patient_id = preg.patient_id
GROUP BY pat.patient_id, pat.first_name, pat.last_name, pat.birth_date, pat.region
HAVING COUNT(preg.pregnancy_id) > 0
ORDER BY nb_pregnancy DESC
LIMIT 5;


-- =====================================================================================================

-- Question 7
-- Which patients are in our database but have never been pregnant?

SELECT
    pat.patient_id,
    pat.first_name,
    pat.last_name,
    pat.birth_date,
    pat.region
FROM raw.patients AS pat
LEFT JOIN raw.pregnancies AS preg
    ON pat.patient_id = preg.patient_id
WHERE preg.pregnancy_id IS NULL
LIMIT 5;

-- =====================================================================================================

-- Question 8
-- Comparing INNER JOIN and LEFT JOIN

-- INNER JOIN count (only patients with pregnancies)
SELECT
    COUNT(DISTINCT pat.patient_id) AS patients_with_pregnancies
FROM raw.patients AS pat
INNER JOIN raw.pregnancies AS preg
    ON pat.patient_id = preg.patient_id;

-- LEFT JOIN count (All patients)
SELECT
    COUNT(DISTINCT pat.patient_id) AS all_patients
FROM raw.patients AS pat
LEFT JOIN raw.pregnancies AS preg
    ON pat.patient_id = preg.patient_id;

-- ===================================================================
--      DATA QUALITY OBSERVATION FOLLOWING PRECEEDING QUERIES
-- ===================================================================

-- Finding: In this dataset, every patient has at least one pregnancy
-- Evidence:
--   1. LEFT JOIN orphan check returns 0 rows
--   2. INNER JOIN count = LEFT JOIN count (both 10,000)
--   3. No NULL pregnancy_ids when using LEFT JOIN

-- Real-world expectation:
--   - Production data would have patients without pregnancies
--   - Possible causes: new registrations, cancellations, data entry delays
--   - LEFT JOIN patterns are still critical for data quality checks

-- This is a characteristic of the synthetic dataset, not an SQL issue
-- The query pattern is correct for real-world scenarios

-- =====================================================================================================

-- Question 9
-- Show me patient demographics with their delivery details







-- =====================================================================================================

-- Question 10
-- fdffd

-- =====================================================================================================

-- Question 11
-- fdffd

-- =====================================================================================================

-- Question 12
-- fdffd

-- =====================================================================================================