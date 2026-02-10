-- =====================================================================================================
-- DAY 2 : AGGREGATIONS + GROUP BY
-- Maternal Health Analytics - Technical interview preparation
-- Date: February 10, 2026
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
-- What's the average age of mothers at delivery in each region? Are there regional differences in maternal age?

-- Deconstruction:
--   - Need: patient birth_date and region (from patients table)
--   - Need: pregnancy_id (from pregnancies table)
--   - Need: delivery_date (from deliveries table)
--   - Connection 1: patient_id links patients table to pregnancies table
--   - Connection 2: pregnancy_id links pregnancies table to deliveries table
--   - Join type 1: INNER (only patients with deliveries will be listed)
--   - Join type 2: INNER (only patients who completed pregnancies with delivery records will be listed)
--   - Granularity: region
--   - Functions to be used: EXTRACT (YEAR FROM AGE()) and AVG()

SELECT
    -- Patients details
    pat.region,
    COUNT(del.delivery_id) AS total_deliveries,
    -- Calculate patient's average age at delivery and round it to 2 decimal places
    ROUND(AVG(EXTRACT (YEAR FROM AGE(del.delivery_date, pat.birth_date))),1) AS patient_average_age_at_delivery
FROM raw.patients AS pat
INNER JOIN raw.pregnancies AS preg 
    ON pat.patient_id = preg.patient_id
INNER JOIN raw.deliveries AS del
    ON preg.pregnancy_id = del.pregnancy_id
GROUP BY pat.region
ORDER BY patient_average_age_at_delivery DESC;

-- =====================================================================================================
-- Question 2
-- How many deliveries occurred in each region, and what percentage of total deliveries does each region represent?

-- Deconstruction:
--   - Need: region (from patients table)
--   - Need: pregnancy_id (from pregnancies table)
--   - Need: delivery_date (from deliveries table)
--   - Connection 1: patient_id links patients table to pregnancies table
--   - Connection 2: pregnancy_id links pregnancies table to deliveries table
--   - Join type 1: INNER (only patients with deliveries will be listed)
--   - Join type 2: INNER (only patients who completed pregnancies with delivery records will be listed)
--   - Granularity: region
--   - Functions to be used: COUNT(deliveries)
--   - Percentage = (number of deliveries by region/total number of deliveries)*100.0

SELECT
    -- Patients details
    pat.region,
    -- Calculate number of deliveries by region
    COUNT(del.delivery_id) AS number_of_deliveries_by_region,
    -- Calculate percentage of total deliveries by region
    ROUND(COUNT(del.delivery_id)*100.0/(SELECT COUNT(delivery_id) FROM raw.deliveries), 2) AS percentage_of_deliveries
FROM raw.patients AS pat
INNER JOIN raw.pregnancies AS preg 
    ON pat.patient_id = preg.patient_id
INNER JOIN raw.deliveries AS del
    ON preg.pregnancy_id = del.pregnancy_id
GROUP BY pat.region
ORDER BY number_of_deliveries_by_region DESC;

-- =====================================================================================================

-- Question 3
-- How many deliveries fall into each maternal age group (<25, 25–29, 30–34, 35–39, 40+) per region?

-- Deconstruction:
--   - Need: region (from patients table)
--   - Need: pregnancy_id (from pregnancies table)
--   - Need: delivery_date (from deliveries table)
--   - Connection 1: patient_id links patients table to pregnancies table
--   - Connection 2: pregnancy_id links pregnancies table to deliveries table
--   - Join type 1: INNER (only patients with deliveries will be listed)
--   - Join type 2: INNER (only patients who completed pregnancies with delivery records will be listed)
--   - Granularity: region
--   - Functions to be used: COUNT(), EXTRACT (YEAR FROM AGE()) and CASE WHEN... THEN

SELECT
    -- Patients details
    pat.region,
    COUNT(del.delivery_id) AS total_deliveries,
    -- Calculate patient's age at delivery and place it in the appropriate age bucket
    COUNT(
        CASE
            WHEN EXTRACT (YEAR FROM AGE(del.delivery_date, pat.birth_date)) < 25 THEN 1
        END) AS under_25,
    COUNT(
        CASE
            WHEN EXTRACT (YEAR FROM AGE(del.delivery_date, pat.birth_date)) BETWEEN 25 AND 29 THEN 1
        END) AS age_25_29,
    COUNT(
        CASE
            WHEN EXTRACT (YEAR FROM AGE(del.delivery_date, pat.birth_date)) BETWEEN 30 AND 34 THEN 1
        END) AS age_30_34,
    COUNT(
        CASE
            WHEN EXTRACT (YEAR FROM AGE(del.delivery_date, pat.birth_date)) BETWEEN 35 AND 39 THEN 1
        END) AS age_35_39,
    COUNT(
        CASE
            WHEN EXTRACT (YEAR FROM AGE(del.delivery_date, pat.birth_date)) >= 40 THEN 1
        END) AS over_40
FROM raw.patients AS pat
INNER JOIN raw.pregnancies AS preg 
    ON pat.patient_id = preg.patient_id
INNER JOIN raw.deliveries AS del
    ON preg.pregnancy_id = del.pregnancy_id
GROUP BY pat.region;

-- =====================================================================================================

-- Question 4
-- What percentage of all deliveries were cesarean vs vaginal?


-- Deconstruction:
--   - Need: total number of deliveries (from deliveries table)
--   - Granularity: national
--   - Functions to be used: COUNT()

SELECT
    -- Count total number of deliveries
    COUNT(delivery_id) AS total_deliveries,
    -- Percentage of deliveries which were cesarean
    ROUND(
        COUNT(
            CASE
                WHEN delivery_mode = 'Cesarean' THEN 1
            END)*100.0/COUNT(delivery_id),
            2) AS percentage_cesarean,
    ROUND(
        COUNT(
            CASE
                WHEN delivery_mode = 'Spontaneous vaginal' OR delivery_mode = 'Instrumental vaginal' THEN 1
            END)*100.0/COUNT(delivery_id),
            2) AS percentage_vaginal
FROM raw.deliveries;

-- =====================================================================================================

-- Question 5
-- How many deliveries occurred at each facility type? What's the average labor duration for each type?

-- Deconstruction:
--   - Need: facility_types,labor_duration_minutes (from deliveries table)
--   - Granularity: per facility
--   - Functions to be used: COUNT() for total deliveries, AVG() for labor duration in minutes, GROUP BY facility_type

SELECT
    facility_type,
    COUNT(*) AS total_deliveries,
    ROUND(AVG(labor_duration_minutes)/60, 1) as average_labor_duration_in_hours
FROM raw.deliveries
GROUP BY facility_type
ORDER BY total_deliveries DESC;

-- =====================================================================================================

-- Question 6
-- What's the cesarean rate (%) in each region? Which regions are above the national average?

-- Deconstruction:
--   - Need: region (from patients table)
--   - Need: pregnancy_id (from pregnancies table)
--   - Need: delivery_mode (from deliveries table)
--   - Connection 1: patient_id links patients table to pregnancies table
--   - Connection 2: pregnancy_id links pregnancies table to deliveries table
--   - Join type 1: INNER (only patients with deliveries will be listed)
--   - Join type 2: INNER (only patients who completed pregnancies with delivery records will be listed)
--   - Granularity: region
--   - Functions to be used: COUNT(), AVG()

SELECT
    -- Patients details
    pat.region,
    -- Calculate number of deliveries by region
    COUNT(del.delivery_id) AS number_of_deliveries_by_region,
    -- Calculate regional average
    ROUND(
        (100.0 * COUNT(
                CASE
                    WHEN delivery_mode = 'Cesarean' THEN 1
                END))/COUNT(del.delivery_id),
                2) AS regional_cesarean_rate,
    -- Calculate national average
    (SELECT
        ROUND(100.0 * COUNT(CASE WHEN delivery_mode = 'Cesarean' THEN 1 END) / COUNT(*), 2)
    FROM raw.deliveries) AS national_average,
    -- Difference national average - regional average
    (SELECT
                        ROUND(100.0 * COUNT(CASE WHEN delivery_mode = 'Cesarean' THEN 1 END) / COUNT(*), 2)
                    FROM raw.deliveries) - ROUND(
                                                (100.0 * COUNT(
                                                            CASE
                                                                WHEN delivery_mode = 'Cesarean' THEN 1
                                                            END))/COUNT(del.delivery_id),
                                                            2) AS comparison_delta,    
    -- Comparison with national_average
    CASE 
        WHEN ROUND(
        (100.0 * COUNT(
                CASE
                    WHEN delivery_mode = 'Cesarean' THEN 1
                END))/COUNT(del.delivery_id),
                2) > (SELECT
                        ROUND(100.0 * COUNT(CASE WHEN delivery_mode = 'Cesarean' THEN 1 END) / COUNT(*), 2)
                    FROM raw.deliveries) THEN 'Above'
        WHEN ROUND(
        (100.0 * COUNT(
                CASE
                    WHEN delivery_mode = 'Cesarean' THEN 1
                END))/COUNT(del.delivery_id),
                2) < (SELECT
                        ROUND(100.0 * COUNT(CASE WHEN delivery_mode = 'Cesarean' THEN 1 END) / COUNT(*), 2)
                    FROM raw.deliveries) THEN 'Below'
        ELSE 'Equal'
    END AS comparison_benchmark
FROM raw.patients AS pat
INNER JOIN raw.pregnancies AS preg 
    ON pat.patient_id = preg.patient_id
INNER JOIN raw.deliveries AS del
    ON preg.pregnancy_id = del.pregnancy_id
GROUP BY pat.region
ORDER BY number_of_deliveries_by_region DESC;

-- =====================================================================================================
-- NOTE : THE FOLLOWING QUESTIONS WILL BE HANDLED WHEN CTEs AND WINDOWS FUNCTION WILL BE SEEN

-- Question 7
-- What's the epidural usage rate for each combination of facility type and region? Show only combinations with 50+ deliveries (statistical significance)

-- =====================================================================================================

-- Question 8
-- For each region, calculate:
-- (1) Total deliveries
-- (2) Cesarean rate
-- (3) Preterm birth rate
-- (4) Average birth weight
-- (5) Epidural usage rate
-- Average maternal age
-- Rank regions by overall quality score

-- =====================================================================================================


-- =====================================================================================================
--                   DAY 2 - COMPLETE (AGGREGATIONS + GROUP BY)
-- =====================================================================================================

-- Topics covered:
--   ✅ AGGREGATION AND GROUP BY
--   ✅ ORDER BY
--   ✅ ROUND(), AVG(), EXTRACT (YEAR FROM AGE())
--   ✅ JOINs REVISION

-- =====================================================================================================