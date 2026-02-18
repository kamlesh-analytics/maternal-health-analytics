-- =====================================================================================================
-- DAY 11 : SPEED DRILL [WITHOUT DATABASE ACCESS]
-- Technical interview preparation for Resilience Care
-- Date: February 17, 2026
-- =====================================================================================================

-- Patients enrolled in remote monitoring
patients (
    patient_id      VARCHAR PRIMARY KEY,
    first_name      VARCHAR,
    last_name       VARCHAR,
    birth_date      DATE,
    region          VARCHAR,
    pathology       VARCHAR,  -- 'Oncology', 'Psychiatry', 'Gastroenterology'
    enrollment_date DATE,
    hospital_id     VARCHAR,
    is_active       BOOLEAN
)

-- Daily symptom reports submitted by patients via mobile app
symptom_reports (
    report_id       VARCHAR PRIMARY KEY,
    patient_id      VARCHAR,  -- FK to patients
    report_date     DATE,
    symptom_type    VARCHAR,  -- 'Fatigue', 'Pain', 'Nausea', 'Anxiety', 'Appetite loss'
    severity_score  INT,      -- 0 (none) to 10 (extreme)
    submitted_at    TIMESTAMP
)

-- Clinical interventions triggered by alerts
interventions (
    intervention_id   VARCHAR PRIMARY KEY,
    patient_id        VARCHAR,  -- FK to patients
    report_id         VARCHAR,  -- FK to symptom_reports
    intervention_date TIMESTAMP,
    intervention_type VARCHAR,  -- 'Teleconsultation', 'Hospitalization', 'Treatment adjustment'
    response_time_min INT,      -- Minutes from report to intervention
    clinician_id      VARCHAR,
    outcome           VARCHAR   -- 'Resolved', 'Escalated', 'Ongoing'
)

-- Partner hospitals
hospitals (
    hospital_id   VARCHAR PRIMARY KEY,
    hospital_name VARCHAR,
    region        VARCHAR,
    hospital_type VARCHAR  -- 'CHU', 'CHR', 'Clinique privée'
)

-- =====================================================================================================
-- SQL QUESTIONS (10 × 10 minutes)
-- =====================================================================================================

-- QUESTION 1
-- Scenario: Show me a list of all hospitals with the total number of active patients enrolled at each hospital.

-- Requirements:
-- Include hospital name, region, and hospital type
-- Count only active patients
-- Include hospitals even if they have zero active patients
-- Order by total patients (highest first)

-- Expected columns:
-- hospital_name | region | hospital_type | total_active_patients

-- Tables: patients-hospitals
-- JOIN : patients-hopitals on hospital_id

SELECT
    h.hospital_name,
    h.region,
    h.hospital_type,
    COUNT(
        CASE WHEN p.is_active = TRUE THEN 1
        END) AS total_active_patients
FROM hospitals as h
LEFT JOIN patients as p
    ON h.hospital_id = p.hospital_id
WHERE p.is_active = TRUE
GROUP BY 1, 2, 3
ORDER BY total_active_patients DESC;

-- =====================================================================================================

-- QUESTION 2
-- Scenario: We need to identify patients who haven't submitted a symptom report in the past 14 days,
-- these are "disengaged" patients requiring outreach.

-- Requirements:
-- Show patient ID, full name (first + last), pathology, and hospital name
-- Calculate days since last report
-- Only show patients who haven't reported in 14+ days
-- Add a column "outreach_priority": 'High' if no report in 30+ days, 'Medium' if 14-29 days
-- Order by days since last report (longest first)

-- Expected columns:
-- patient_id | full_name | pathology | hospital_name | days_since_report | outreach_priority

-- Tables: patients, symptom_reports, hospitals
-- LEFT JOIN patients and symptom_reports on patient_id
-- INNER JOIN patients and hospitals on hospital_id 

WITH all_tables AS(
    SELECT
        p.patient_id,
        (p.first_name || ' ' || p.last_name) AS full_name,
        p.pathology,
        h.hospital_name,
        MAX(sr.report_date) AS last_report_date,
        CURRENT_DATE - MAX(sr.report_date) AS days_since_report
    FROM patients as p
    LEFT JOIN symptom_reports AS sr
        ON p.patient_id = sr.patient_id
    INNER JOIN hospitals as h
        ON p.hospital_id = h.hospital_id 
    GROUP BY 1, 2, 3, 4
)

SELECT
    patient_id,
    full_name,
    pathology,
    hospital_name,
    days_since_report,
    (CASE
        WHEN days_since_report >= 30 THEN 'High'
        WHEN days_since_report >= 14 THEN 'Medium'
        ELSE 'Low'
    END) AS outreach_priority
FROM all_tables
ORDER BY days_since_report;

-- =====================================================================================================
-- QUESTION 3
-- Scenario: For each symptom type, calculate summary statistics to understand our monitoring landscape.

--Requirements:
-- Show symptom type
-- Total reports of that symptom
-- Average severity (rounded to 1 decimal)
-- Percentage of reports that are high impact (impact_daily_life >= 7)
-- Only include symptom types with at least 50 reports
-- Order by total reports (highest first)

-- Expected columns:
-- symptom_type | total_reports | avg_severity | high_impact_pct

-- Table: symptom_reports

SELECT
    symptom_type,
    COUNT(report_id) AS total_reports,
    ROUND(AVG(severity_score), 1) AS avg_severity,
    ROUND(100.0 * COUNT(CASE WHEN impact_daily_life >= 7 THEN 1
    END)/COUNT(report_id), 1) AS high_impact_pct
FROM symptom_reports
GROUP BY symptom_type
HAVING COUNT(report_id) >= 50
ORDER BY total_reports;

-- =====================================================================================================

-- QUESTION 4
-- Scenario: Compare symptom patterns across regions to identify geographic health trends.

-- Requirements:
-- For each region, calculate:
-- Total symptom reports
-- Count of 'Pain' symptom reports specifically
-- Count of 'Fatigue' symptom reports specifically
-- Percentage of reports that are Pain
-- Percentage of reports that are Fatigue

-- Expected columns:
-- region | total_reports | pain_reports | fatigue_reports | pain_pct | fatigue_pct

-- Tables: patients, symptom_reports

SELECT 
    p.region,
    COUNT(sr.report_id) AS total_reports,
    COUNT(
        CASE
            WHEN sr.symptom_type = 'Pain' THEN 1
        END) AS pain_reports,
    COUNT(
        CASE
            WHEN symptom_type = 'Fatigue' THEN 1
        END) AS fatigue_reports,
    ROUND(100.0 *
        COUNT(
            CASE
                WHEN sr.symptom_type = 'Pain' THEN 1
            END)/COUNT(sr.report_id), 1) AS pain_pct,
    ROUND(100.0 *    
        COUNT(
            CASE
                WHEN symptom_type = 'Fatigue' THEN 1
            END)/COUNT(sr.report_id), 1) AS fatigue_pct,
FROM patients as p
LEFT JOIN symptom_reports as sr
    ON p.patient_id = sr.patient_id
GROUP BY p.region
ORDER BY total_reports DESC;

-- =====================================================================================================0

-- QUESTION 5
-- Scenario: Show intervention activity for the past 7 days with daily breakdown.

-- Requirements: 
-- Show date, total interventions that day, average response time
-- Calculate how much faster/slower than 30-minute target: show difference in minutes
-- Add status: 'On Target' if avg <= 30 min, 'Needs Improvement' if > 30 min
-- Only last 7 days
-- Order chronologically (oldest to newest)

-- Expected columns:
-- intervention_date | total_interventions | avg_response_min | diff_from_target | status


SELECT
    intervention_date,
    COUNT(intervention_id) AS total_interventions,
    ROUND(AVG(response_time_min), 1) AS avg_response_min,
    ROUND(AVG(response_time_min) - 30, 1) AS diff_from_target,
    CASE
        WHEN AVG(response_time_min) <= 30 THEN 'On target'
        ELSE 'Needs Improvement'
    END AS status
FROM interventions
WHERE intervention_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY intervention_date
ORDER BY intervention_date ASC;

-- =====================================================================================================

-- QUESTION 6
-- Scenario: Show all interventions from the past 30 days with full context.

--Requirements:
-- Patient full name, hospital name, symptom type that triggered intervention
-- Intervention type, response time in minutes, outcome
-- Calculate "response_category": 'Immediate' (<15 min), 'Fast' (15-30 min), 'Delayed' (>30 min)
-- Only interventions from last 30 days
-- Order by response time (fastest first)

-- Expected columns:
-- patient_name | hospital_name | symptom_type | intervention_type | response_time_min |
-- response_category | outcome

Tables: patients, hospitals, symptom_reports, interventions

SELECT
    (p.first_name || ' ' || p.last_name) AS patient_name,
    h.hospital_name,
    sr.symptom_type,
    i.intervention_type,
    i.response_time_min,
    CASE
        WHEN i.response_time_min < 15 THEN 'Immediate'
        WHEN i.response_time_min BETWEEN 15 AND 30 THEN 'Fast'
        ELSE 'Delayed'
    END AS response_category,
    i.outcome
FROM patients as p
INNER JOIN hospitals AS h
    ON p.hospital_id = h.hospital_id
INNER JOIN symptom_reports AS sr
    ON i.report_id = sr.report_id
INNER JOIN interventions AS i
    ON p.patient_id = i.patient_id
WHERE i.intervention_date >= CURRENT_DATE - INterval '30 days'
ORDER BY i.response_time_min ASC; 

-- =====================================================================================================

-- QUESTION 7
-- Scenario:For each hospital, calculate what percentage of their total interventions
-- resulted in each outcome type.

-- Requirements:
-- Show hospital name and region
-- Count total interventions
-- Calculate percentage that were 'Resolved', 'Escalated', and 'Ongoing' separately
-- Only hospitals with at least 20 interventions
-- Round percentages to 1 decimal place
-- Order by 'Resolved' percentage (highest first)

-- Expected columns:
-- hospital_name | region | total_interventions | resolved_pct | escalated_pct | ongoing_pct

Tables: hospitals, patients, interventions

SELECT
    h.hospital_name,
    h.region,
    COUNT(i.interventions_id) as total_interventions
    ROUND(100 *
        COUNT(
            CASE
                WHEN i.outcome ='Resolved' THEN 1
            END)/COUNT(i.interventions_id), 1) AS resolved_pct,
    ROUND(100 *
        COUNT(
            CASE
                WHEN i.outcome ='Escalated' THEN 1
            END)/COUNT(i.interventions_id), 1) AS escalated_pct,
    ROUND(100 *    
        COUNT(
            CASE
                WHEN i.outcome ='Ongoing' THEN 1
            END)/COUNT(i.interventions_id), 1) AS ongoing_pct,
FROM hospitals as h
INNER JOIN patients as p
    ON h.hospital_id = p.hospital_id
INNER JOIN interventions AS i
    ON p.patient_id = i.patient_id
GROUP BY h.hospital_name, h.region
    HAVING COUNT(i.interventions_id)>= 20
ORDER BY resolved_pct DESC;

-- =====================================================================================================

-- QUESTION 8
-- Scenario: Identify "high-burden" patients - those with frequent high-severity symptom reports.

-- Requirements:
-- Show patient ID, full name, pathology, hospital name
-- Count total reports in past 60 days
-- Count high-severity reports (severity >= 8) in past 60 days
-- Calculate percentage that are high-severity
-- Only show patients with 10+ reports AND 50%+ are high-severity
-- Order by high-severity percentage (highest first)

-- Expected columns:
-- patient_id | full_name | pathology | hospital_name | 
-- total_reports_60d | high_severity_reports | high_severity_pct

Tables: patients, hospitals, reports

WITH working_data AS(
    SELECT
        p.patient_id,
        (p.first_name || ' ' || p.last_name) AS full_name,
        p.pathology,
        h.hospital_name,
        COUNT(sr.report_id) as total_reports,
        hifgh 
    FROM patients as p
    INNER JOIN hospitals as h
        ON p.hospital_id = h.patient_id
    INNER JOIN symptom_reports AS sr
        ON p.patient_id = sr.patient_id
)

-- =====================================================================================================

-- QUESTION 9
-- Scenario: Build a 3-layer CTE to identify underperforming hospitals.

-- Requirements:
-- Layer 1 - staging:
    -- Filter to active patients only
    -- Filter to interventions from past 90 days

-- Layer 2 - hospital_metrics:
-- For each hospital calculate:
    -- Total interventions
    -- Average response time
    -- Resolution rate (% with outcome = 'Resolved')

-- Layer 3 - categorized:
-- Add category: 'Underperforming' if resolution rate < 60% OR avg response > 45 min
-- Otherwise 'Performing'

-- Final SELECT:
-- Show underperforming hospitals only
-- Order by resolution rate (lowest first)

-- Expected columns:
-- hospital_name | total_interventions | avg_response_min | resolution_rate | category

-- =====================================================================================================

-- QUESTION 10
-- Scenario: Before building a dashboard, audit the interventions table for data issues.

-- Requirements:
-- Return ONE ROW with these metrics:
    -- Total intervention records
    -- Records with NULL response_time_min
    -- Records with response_time = 0 (impossible)
    -- Records with response_time > 1440 (more than 24 hours - suspicious)
    -- Records where intervention_date is BEFORE the corresponding report_date (impossible)
    -- Overall data quality score: percentage of records with NO issues

-- Expected columns:
-- total_records | null_response | zero_response | suspicious_response | 
-- impossible_date | data_quality_pct

-- =====================================================================================================
--                                        QUERY-BUILDING TIME
-- =====================================================================================================
-- Question 1: 8 minutes [10 minutes allocated]
-- Question 2: 23 minutes [10 minutes allocated]
-- Question 3: 8 minutes [10 minutes allocated]
-- Question 4: 8 minutes [10 minutes allocated]
-- Question 5: 13 minutes [10 minutes allocated]
-- Question 6: 21 minutes [10 minutes allocated]
-- Question 7: 14 minutes[10 minutes allocated]
-- Question 8: 5 minutes [before running out of time]
-- Question 9: Not attempted [out of time]
-- Question 10: Not attempted [out of time]