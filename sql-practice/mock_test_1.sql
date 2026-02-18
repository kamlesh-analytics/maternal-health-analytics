-- =====================================================================================================
-- DAY 10 : PRACTICE FOR MOCK TEST [WITHOUT DATABASE ACCESS]
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

-- Question 1: Patient monitoring overview (Completed in 15 minutes)
-- Scenario: The medical director asks for a list of all currently active patients
-- along with their hospital name and number of symptom reports submitted since enrollment.
-- Write a query that returns:
-- patient_id
-- Full name (first + last in one column called full_name)
-- Pathology
-- Hospital name
-- Region
-- Enrollment date
-- Total symptom reports submitted

-- Requirements:
-- Active patients only
-- Include patients even if they have submitted zero reports
-- Order by total reports (highest first)

SELECT
    pat.patient_id,
    (pat.first_name || ' ' || pat.last_name) AS full_name,
    pat.pathology,
    hos.hospital_name,
    pat.region,
    pat.enrollment_date,
    COUNT(sym.report_id) AS nb_reports
FROM patients AS pat
LEFT JOIN symptom_reports AS sym
    ON pat. patient_id = sym.patient_id
INNER JOIN hospitals AS hos
    ON pat.hospital_id = hos.hospital_id
WHERE pat.is_active IS TRUE
GROUP BY 1, 2, 3, 4, 5, 6
ORDER BY nb_reports DESC;

-- =====================================================================================================

-- Question 2: Critical alert analysis by pathology (Completed in 25 minutes)
-- Scenario: A severity score of 8 or above is considered a critical alert.
-- The clinical team wants to understand the alert burden across pathologies.
--Write a query that returns for each pathology:
-- Total active patients
-- Total symptom reports
-- Total critical alerts (severity ≥ 8)
-- Critical alert rate (% of reports that are critical)
-- Average severity score across all reports

-- Requirements:
-- Only pathologies with at least 100 reports
-- Round all percentages and averages to 2 decimal places
-- Order by critical alert rate descending

SELECT
    pat.pathology,
    COUNT(
        CASE
            WHEN pat.is_active = TRUE THEN 1
        END) AS total_active_patients,
    COUNT(sym.report_id) AS total_reports,
    COUNT(
        CASE
            WHEN sym.severity_score >= 8 THEN 1
        END) AS total_critical_alerts,
    ROUND(100.0 * COUNT(
        CASE
            WHEN sym.severity_score >= 8 THEN 1
        END)/COUNT(sym.report_id), 2) AS critical_alert_rate,
    ROUND(AVG(sym.severity_score), 2) AS avg_severity_score
FROM patients AS pat
INNER JOIN symptom_reports AS sym
    ON pat.patient_id = sym.patient_id
GROUP BY pat.pathology
HAVING COUNT(sym.report_id) > 100
ORDER BY critical_alert_rate DESC;

-- =====================================================================================================


-- Question 3: Hospital performance dashboard [dbt-style] (Completed in 18 minutes)
-- Scenario: Build a hospital performance monitoring dashboard using a dbt-style CTE structure.
-- Build a multi-layer CTE query:
-- Layer 1 - source: pull raw data needed from all relevant tables

-- Layer 2 - staging: clean and filter:
    -- Active patients only
    -- Remove NULL response times
    -- Remove impossible response times (0 minutes or >1440 minutes - more than 24h)

-- Layer 3 - intermediate: for each hospital calculate:
    -- Total active patients
    -- Total interventions
    -- Average response time (minutes)
    -- Percentage of interventions resolved successfully (outcome = 'Resolved')

-- Layer 4 - marts:
-- Add performance categories:
-- Response time: 'Fast' (< 30 min), 'Moderate' (30-60 min), 'Slow' (> 60 min)
-- Resolution rate: 'High' (≥ 75%), 'Medium' (50-74%), 'Low' (< 50%)

-- Show all hospitals ordered by resolution rate descending in the final SELECT statement.

WITH raw_layer AS(
    SELECT
        p.patient_id,
        p.hospital_id,
        p.is_active,
        h.hospital_name,
        h.region,
        i.intervention_id,
        i.response_time_min,
        i.outcome
    FROM patients AS p
    INNER JOIN hospitals AS h
        ON p.hospital_id = h.hospital_id
    INNER JOIN interventions AS i
        ON p.patient_id = i.patient_id
),

staging_layer AS(
    SELECT
        *
    FROM source_layer
    WHERE is_active = TRUE
        AND response_time_min IS NOT NULL
        AND response_time_min > 0
        AND response_time_min <= 1440
),

intermediate_layer AS(
    SELECT
        hospital_id,
        hospital_name,
        region,
        COUNT (DISTINCT patient_id) AS nb_active_patients,
        COUNT(intervention_id) AS total_interventions,
        ROUND(AVG(response_time_min), 2) as average_response_time,
        COUNT(
            CASE
                WHEN outcome = 'Resolved'
                THEN 1
            END) AS nb_resolved
        
        ROUND(100. 0 * (CASE
                            WHEN outcome = 'Resolved'
                            THEN 1
                        END)/COUNTintervention_id) AS pct_resolved
    FROM staging_layer
    GROUP BY hospital_id, hospital_name, region
),

marts_layer AS(
    SELECT
        *,
        CASE
            WHEN average_response_time < 30 THEN 'Fast'
            WHEN average_response_time BETWEEN 30 AND 60 THEN 'Moderate'
            WHEN average_response_time > 60 THEN 'Slow'
        END AS response_category,
        CASE
            WHEN pct_resolved >= 75 THEN 'High'
            WHEN pct_resolved BETWEEN 50 AND 74 THEN 'Medium'
            WHEN pct_resolved < 50 THEN 'Low'
        END AS intervention_category
    FROM intermediate_layer
)

SELECT
    hospital_name,
    region,
    nb_active_patients,
    total_interventions,
    average_response_time,
    response_category,
    pct_resolved,
    intervention_category
FROM marts_layer
ORDER BY pct_resolved DESC;
