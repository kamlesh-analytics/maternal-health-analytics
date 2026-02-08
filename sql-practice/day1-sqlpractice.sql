-- ============================================================
-- DAY 1: WARM-UP SESSION [SQL FOUNDATIONS]
-- Maternal Health Analytics - Technical interview preparation
-- Date: February 9, 2026
-- ============================================================

-- ============================================================
-- SETUP CHECK
-- ============================================================

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
SELECT 'patients' as table_name, COUNT(*) as rows FROM raw.patients
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
-- PART 1: STRUCTURED QUERY LANGUAGE FUNDAMENTALS REVIEW
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
    region as Region,
    COUNT(*) as Patient_count
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

==============================================================================

-- Question 6
-- What's the average birth weight by infant sex?

SELECT
    sex,
    ROUND(AVG(birth_weight_grams), 2) as Average_birth_weight_in_grams
FROM raw.birth_outcomes
GROUP BY sex
ORDER BY Average_birth_weight_in_grams DESC;

-- =====================================================================================================

-- Question 7
-- Find the 10 longest labor durations?

SELECT
    delivery_id,
    pregnancy_id,
    labor_duration_minutes
FROM raw.deliveries
ORDER BY labor_duration_minutes DESC
LIMIT 10;

-- =====================================================================================================
-- DAY 1 - SESSION 1 COMPLETE (WARM-UP)
-- =====================================================================================================

-- Date: February 8, 2026
-- Duration: ~1 hour
-- Status: Warm-up session - fundamentals reviewed
-- Queries written: 7
-- Topics covered:
--   ✅ SELECT basics
--   ✅ WHERE filtering
--   ✅ ORDER BY sorting
--   ✅ LIMIT
--   ✅ GROUP BY
--   ✅ COUNT(), AVG() aggregates
--   ✅ ROUND() function
--   ✅ Boolean filtering
--
-- Next session: Complete Day 1 (JOINs focus)
-- Estimated completion: February 9, 2026

-- =====================================================================================================