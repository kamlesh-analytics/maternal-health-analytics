# SQL FUNDAMENTALS REFRESHER

**Purpose:** Quick reference guide when I am stuck during practice sessions  
**Audience:** SQL learners needing PostgreSQL refresh   

---

## TABLE OF CONTENTS

1. [SQL Basics - What is SQL?](#1-sql-basics)
2. [Database Structure - Tables, Rows, Columns](#2-database-structure)
3. [SELECT Statement - Getting Data](#3-select-statement)
4. [WHERE Clause - Filtering Data](#4-where-clause)
5. [ORDER BY - Sorting Results](#5-order-by)
6. [LIMIT - Controlling Output](#6-limit)
7. [Aggregate Functions - COUNT, SUM, AVG, MIN, MAX](#7-aggregate-functions)
8. [NULL Handling](#8-null-handling)
9. [Data Types in PostgreSQL](#9-data-types)
10. [PostgreSQL-Specific Commands](#10-postgresql-commands)
11. [BigQuery vs PostgreSQL Cheat Sheet](#11-bigquery-vs-postgresql)
12. [Common Errors & How to Fix Them](#12-common-errors)
13. [Quick Reference Card](#13-quick-reference)

---

<a name="1-sql-basics"></a>
## 1. SQL BASICS - WHAT IS SQL?

### Definition

**SQL = Structured Query Language**

A language for:
- Retrieving data from databases (SELECT)
- Modifying data (INSERT, UPDATE, DELETE)
- Defining database structure (CREATE, ALTER, DROP)
- Controlling access (GRANT, REVOKE)

**For analytics work, you'll use SELECT 95% of the time.**

---

### SQL is Declarative

**You tell SQL WHAT you want, not HOW to get it:**
```sql
-- You say: "Give me all patients from Paris"
SELECT * FROM patients WHERE city = 'Paris';

-- SQL figures out HOW (which indexes to use, how to scan the table, etc.)
```

**Compare to Python (imperative):**
```python
# You tell Python exactly HOW to do it
patients = []
for row in all_patients:
    if row['city'] == 'Paris':
        patients.append(row)
```

---

### SQL Statement Structure

**Every SQL statement has:**
1. **Keywords** (SELECT, FROM, WHERE) - reserved words
2. **Identifiers** (table names, column names)
3. **Operators** (=, <, >, AND, OR)
4. **Literals** (values like 'Paris', 42, TRUE)

**SQL is NOT case-sensitive** (but convention: UPPERCASE keywords, lowercase names)
```sql
-- All three are equivalent:
SELECT first_name FROM patients;
select first_name from patients;
SeLeCt FiRsT_nAmE fRoM pAtIeNtS;  -- Don't do this!

-- Convention (recommended):
SELECT first_name FROM patients;
```

---

<a name="2-database-structure"></a>
## 2. DATABASE STRUCTURE - TABLES, ROWS, COLUMNS

### Hierarchy
```
Database (maternal_health_db)
  └── Schema (raw, staging, analytics)
       └── Table (patients, pregnancies, deliveries)
            └── Columns (patient_id, first_name, birth_date)
                 └── Rows (individual records)
```

---

### Table = Spreadsheet

**Think of a table like an Excel sheet:**

| patient_id | first_name | last_name | birth_date | region |
|------------|------------|-----------|------------|--------|
| 1 | Marie | Dupont | 1985-03-15 | Île-de-France |
| 2 | Jean | Martin | 1990-07-22 | Provence-Alpes-Côte d'Azur |
| 3 | Sophie | Bernard | 1988-11-30 | Auvergne-Rhône-Alpes |

- **Table:** `patients`
- **Columns:** `patient_id`, `first_name`, `last_name`, `birth_date`, `region`
- **Rows:** 3 records (Marie, Jean, Sophie)

---

### Primary Key

**A column (or combination) that uniquely identifies each row:**
```sql
-- patient_id is the primary key
patient_id | first_name
-----------|------------
1          | Marie
2          | Jean
3          | Sophie

-- Each patient_id appears exactly once
-- No NULLs allowed
-- No duplicates allowed
```

---

### Foreign Key

**A column that references a primary key in another table:**
```sql
-- pregnancies table
pregnancy_id | patient_id | delivery_date
-------------|------------|---------------
101          | 1          | 2024-01-15
102          | 1          | 2025-06-20
103          | 2          | 2024-03-10

-- patient_id here is a FOREIGN KEY
-- It references patient_id in the patients table
-- This creates a relationship: pregnancies belong to patients
```

---

<a name="3-select-statement"></a>
## 3. SELECT STATEMENT - GETTING DATA

### Basic Syntax
```sql
SELECT column1, column2, column3
FROM table_name;
```

---

### Example 1: Select Specific Columns
```sql
SELECT first_name, last_name, region
FROM raw.patients;
```

**Returns:**
```
first_name | last_name | region
-----------|-----------|------------------
Marie      | Dupont    | Île-de-France
Jean       | Martin    | Provence-Alpes...
Sophie     | Bernard   | Auvergne-Rhône...
...
```

---

### Example 2: Select All Columns
```sql
SELECT * FROM raw.patients;
```

**`*` = wildcard = all columns**

**WARNING: In production, avoid SELECT ***
- Retrieves unnecessary data
- Slower performance
- Less readable

**Better: List columns explicitly**

---

### Example 3: Select with Alias
```sql
SELECT 
    first_name AS prenom,
    last_name AS nom,
    region AS region_residence
FROM raw.patients;
```

**Returns:**
```
prenom | nom     | region_residence
-------|---------|------------------
Marie  | Dupont  | Île-de-France
```

**AS creates an alias (temporary rename for display)**

---

### Example 4: Calculated Columns
```sql
SELECT 
    first_name,
    last_name,
    birth_date,
    EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM birth_date) AS age_approx
FROM raw.patients;
```

**You can create new columns on-the-fly with calculations.**

---

<a name="4-where-clause"></a>
## 4. WHERE CLAUSE - FILTERING DATA

### Basic Syntax
```sql
SELECT column1, column2
FROM table_name
WHERE condition;
```

**WHERE filters rows BEFORE returning results.**

---

### Comparison Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Equal | `WHERE region = 'Île-de-France'` |
| `!=` or `<>` | Not equal | `WHERE region != 'Île-de-France'` |
| `>` | Greater than | `WHERE age > 35` |
| `<` | Less than | `WHERE age < 20` |
| `>=` | Greater or equal | `WHERE age >= 35` |
| `<=` | Less or equal | `WHERE age <= 40` |

---

### Examples
```sql
-- Equal
SELECT * FROM raw.patients WHERE region = 'Île-de-France';

-- Not equal
SELECT * FROM raw.patients WHERE education_level <> 'No Diploma';

-- Greater than
SELECT * FROM raw.pregnancies WHERE maternal_age_at_delivery > 35;

-- Between (inclusive range)
SELECT * FROM raw.pregnancies WHERE maternal_age_at_delivery BETWEEN 35 AND 40;
-- Equivalent to: WHERE maternal_age_at_delivery >= 35 AND maternal_age_at_delivery <= 40
```

---

### Logical Operators

**AND - Both conditions must be true:**
```sql
SELECT * FROM raw.patients
WHERE region = 'Île-de-France' 
  AND has_health_insurance = TRUE;
```

---

**OR - Either condition can be true:**
```sql
SELECT * FROM raw.patients
WHERE region = 'Île-de-France' 
   OR region = 'Provence-Alpes-Côte d''Azur';
```

---

**NOT - Negate a condition:**
```sql
SELECT * FROM raw.patients
WHERE NOT (region = 'Île-de-France');
-- Same as: WHERE region != 'Île-de-France'
```

---

### IN Operator (List of Values)
```sql
-- Instead of multiple ORs:
SELECT * FROM raw.patients
WHERE region = 'Île-de-France' 
   OR region = 'Provence-Alpes-Côte d''Azur'
   OR region = 'Auvergne-Rhône-Alpes';

-- Use IN:
SELECT * FROM raw.patients
WHERE region IN ('Île-de-France', 'Provence-Alpes-Côte d''Azur', 'Auvergne-Rhône-Alpes');
```

**Cleaner and more readable!**

---

### LIKE Operator (Pattern Matching)

**Wildcards:**
- `%` = any number of characters (including zero)
- `_` = exactly one character
```sql
-- Find patients whose first name starts with 'M'
SELECT * FROM raw.patients WHERE first_name LIKE 'M%';
-- Matches: Marie, Marc, Mathilde, etc.

-- Find patients whose first name ends with 'ie'
SELECT * FROM raw.patients WHERE first_name LIKE '%ie';
-- Matches: Marie, Sophie, Amelie, etc.

-- Find patients whose first name is exactly 5 characters
SELECT * FROM raw.patients WHERE first_name LIKE '_____';  -- 5 underscores
```

---

**ILIKE - Case-Insensitive LIKE (PostgreSQL only):**
```sql
SELECT * FROM raw.patients WHERE first_name ILIKE 'm%';
-- Matches: Marie, marie, MARIE, Marc, marc, etc.
```

---

<a name="5-order-by"></a>
## 5. ORDER BY - SORTING RESULTS

### Basic Syntax
```sql
SELECT column1, column2
FROM table_name
ORDER BY column1;
```

**Default: Ascending (A→Z, 0→9, oldest→newest)**

---

### Ascending vs Descending
```sql
-- Ascending (default)
SELECT first_name, birth_date FROM raw.patients ORDER BY birth_date;
-- Oldest first

-- Descending (newest first)
SELECT first_name, birth_date FROM raw.patients ORDER BY birth_date DESC;
-- Youngest first
```

---

### Multiple Columns
```sql
SELECT region, last_name, first_name
FROM raw.patients
ORDER BY region ASC, last_name ASC, first_name ASC;

-- Sorts by:
-- 1. Region (alphabetically)
-- 2. Within each region, by last name
-- 3. Within same region + last name, by first name
```

---

### Order by Position
```sql
-- Instead of column name, use column position (1-indexed)
SELECT region, last_name, first_name
FROM raw.patients
ORDER BY 1, 2, 3;

-- 1 = first column in SELECT (region)
-- 2 = second column (last_name)
-- 3 = third column (first_name)
```

**WARNING: Less readable - avoid in production code**

---

<a name="6-limit"></a>
## 6. LIMIT - CONTROLLING OUTPUT

### Basic Syntax
```sql
SELECT column1, column2
FROM table_name
LIMIT n;
```

**Returns only the first `n` rows**

---

### Examples
```sql
-- Get first 10 patients
SELECT * FROM raw.patients LIMIT 10;

-- Get 5 oldest patients
SELECT first_name, birth_date 
FROM raw.patients 
ORDER BY birth_date ASC 
LIMIT 5;

-- Get 5 youngest patients
SELECT first_name, birth_date 
FROM raw.patients 
ORDER BY birth_date DESC 
LIMIT 5;
```

---

### OFFSET (Skip Rows)
```sql
-- Skip first 10 rows, then return next 10
SELECT * FROM raw.patients LIMIT 10 OFFSET 10;

-- Useful for pagination:
-- Page 1: LIMIT 10 OFFSET 0   (rows 1-10)
-- Page 2: LIMIT 10 OFFSET 10  (rows 11-20)
-- Page 3: LIMIT 10 OFFSET 20  (rows 21-30)
```

---

<a name="7-aggregate-functions"></a>
## 7. AGGREGATE FUNCTIONS - COUNT, SUM, AVG, MIN, MAX

### COUNT() - Count Rows
```sql
-- Count all rows
SELECT COUNT(*) FROM raw.patients;
-- Returns: 10000

-- Count non-NULL values in a column
SELECT COUNT(education_level) FROM raw.patients;
-- Returns: number of patients with non-NULL education

-- Count DISTINCT values
SELECT COUNT(DISTINCT region) FROM raw.patients;
-- Returns: number of unique regions (e.g., 13)
```

**Key difference:**
- `COUNT(*)` = all rows (including NULLs)
- `COUNT(column)` = non-NULL values only
- `COUNT(DISTINCT column)` = unique non-NULL values

---

### SUM() - Add Up Values
```sql
-- Total labor duration across all deliveries
SELECT SUM(labor_duration_minutes) FROM raw.deliveries;

-- Sum with condition (using CASE)
SELECT SUM(CASE WHEN delivery_mode = 'Cesarean' THEN 1 ELSE 0 END) AS cesarean_count
FROM raw.deliveries;
```

---

### AVG() - Average
```sql
-- Average maternal age
SELECT AVG(maternal_age_at_delivery) FROM raw.pregnancies;
-- Returns: 29.4 (example)

-- Round to 1 decimal
SELECT ROUND(AVG(maternal_age_at_delivery), 1) FROM raw.pregnancies;
-- Returns: 29.4
```

---

### MIN() and MAX() - Extremes
```sql
-- Youngest and oldest maternal age
SELECT 
    MIN(maternal_age_at_delivery) AS youngest,
    MAX(maternal_age_at_delivery) AS oldest
FROM raw.pregnancies;

-- Earliest and latest delivery
SELECT 
    MIN(delivery_date) AS first_delivery,
    MAX(delivery_date) AS last_delivery
FROM raw.deliveries;
```

---

### Combining Multiple Aggregates
```sql
SELECT 
    COUNT(*) AS total_patients,
    COUNT(DISTINCT region) AS unique_regions,
    MIN(birth_date) AS oldest_birth_date,
    MAX(birth_date) AS youngest_birth_date
FROM raw.patients;
```

---

<a name="8-null-handling"></a>
## 8. NULL HANDLING

### What is NULL?

**NULL = absence of value**

**NOT the same as:**
- Empty string `''`
- Zero `0`
- FALSE

**NULL means "unknown" or "not applicable"**

---

### Testing for NULL
```sql
-- WRONG - This doesn't work!
SELECT * FROM raw.patients WHERE education_level = NULL;

-- CORRECT
SELECT * FROM raw.patients WHERE education_level IS NULL;

-- Find non-NULL values
SELECT * FROM raw.patients WHERE education_level IS NOT NULL;
```

**Why `= NULL` doesn't work:**
- NULL represents unknown
- You can't compare "unknown" with `=`
- Must use `IS NULL` or `IS NOT NULL`

---

### COALESCE - Provide Default for NULL
```sql
-- Replace NULL with default value
SELECT 
    patient_id,
    education_level,
    COALESCE(education_level, 'Unknown') AS education_clean
FROM raw.patients;

-- If education_level is NULL, use 'Unknown'
-- Otherwise, use actual value
```

---

### NULLIF - Turn Value into NULL
```sql
-- Convert empty string to NULL
SELECT 
    patient_id,
    NULLIF(education_level, '') AS education_clean
FROM raw.patients;

-- If education_level = '', return NULL
-- Otherwise, return actual value
```

---

### NULL in Calculations

**Any calculation with NULL = NULL:**
```sql
SELECT 5 + NULL;        -- Returns: NULL
SELECT 10 * NULL;       -- Returns: NULL
SELECT NULL / 2;        -- Returns: NULL
SELECT CONCAT('Hello', NULL);  -- Returns: NULL
```

**This is why you need to handle NULLs carefully in calculations!**

---

<a name="9-data-types"></a>
## 9. DATA TYPES IN POSTGRESQL

### Text Types

| Type | Description | Example |
|------|-------------|---------|
| `TEXT` | Variable length, unlimited | `'Any length string'` |
| `VARCHAR(n)` | Variable length, max n chars | `VARCHAR(100)` |
| `CHAR(n)` | Fixed length, padded with spaces | `CHAR(10)` |

**In analytics, use TEXT** (most flexible)

---

### Numeric Types

| Type | Description | Range | Example |
|------|-------------|-------|---------|
| `INTEGER` | Whole numbers | -2B to +2B | `42`, `-17` |
| `BIGINT` | Large whole numbers | -9 quintillion to +9 quintillion | `9223372036854775807` |
| `NUMERIC(p,s)` | Exact decimals | p=precision, s=scale | `NUMERIC(10,2)` = 12345678.90 |
| `REAL` | Floating point (6 digits) | Approximate | `3.14159` |
| `DOUBLE PRECISION` | Floating point (15 digits) | Approximate | `3.141592653589793` |

**For money/exact values:** Use `NUMERIC`  
**For measurements/scientific:** Use `DOUBLE PRECISION`

---

### Date/Time Types

| Type | Description | Example |
|------|-------------|---------|
| `DATE` | Date only (no time) | `'2024-01-15'` |
| `TIME` | Time only (no date) | `'14:30:00'` |
| `TIMESTAMP` | Date + time | `'2024-01-15 14:30:00'` |
| `TIMESTAMPTZ` | Date + time + timezone | `'2024-01-15 14:30:00+01'` |

**Format:** Always `'YYYY-MM-DD'` or `'YYYY-MM-DD HH:MM:SS'`

---

### Boolean Type
```sql
BOOLEAN -- TRUE, FALSE, or NULL

-- Examples
WHERE has_health_insurance = TRUE
WHERE gestational_diabetes = FALSE
WHERE smoking_status IS NULL
```

---

<a name="10-postgresql-commands"></a>
## 10. POSTGRESQL-SPECIFIC COMMANDS

### Meta-Commands (psql only)

**These start with `\` and are NOT SQL:**
```sql
\l                  -- List all databases
\c database_name    -- Connect to database
\dt                 -- List tables in current schema
\dt schema_name.*   -- List tables in specific schema
\d table_name       -- Describe table structure
\q                  -- Quit psql
\?                  -- Help on meta-commands
\h SELECT           -- Help on SQL command
```

---

### Schema Navigation
```sql
-- Show current schema
SHOW search_path;

-- Set default schema
SET search_path TO raw;

-- Now you can write:
SELECT * FROM patients;
-- Instead of:
SELECT * FROM raw.patients;
```

---

### Display Settings
```sql
\x                  -- Toggle expanded display (vertical format)
\pset pager off     -- Disable pager (show all results)
\timing on          -- Show query execution time
```

---

<a name="11-bigquery-vs-postgresql"></a>
## 11. BIGQUERY VS POSTGRESQL CHEAT SHEET

### Syntax Differences

| Feature | BigQuery | PostgreSQL |
|---------|----------|------------|
| **String delimiter** | `'text'` or `"text"` | `'text'` only |
| **Column identifier** | \`column_name\` | `"column_name"` |
| **Comments** | `--` or `/* */` | `--` or `/* */` (Same) |
| **Case sensitivity** | Case-insensitive | Case-insensitive (by default) (Same) |
| **LIMIT** | `LIMIT 10` | `LIMIT 10` (Same) |
| **String concat** | `CONCAT()` or `||` | `CONCAT()` or `||` (Same) |

---

### Function Differences

| Function | BigQuery | PostgreSQL |
|----------|----------|------------|
| **Case-insensitive search** | `UPPER(col) = 'VALUE'` | `ILIKE 'value'` |
| **Current date** | `CURRENT_DATE()` | `CURRENT_DATE` (no parens) |
| **Date arithmetic** | `DATE_ADD(date, INTERVAL 1 DAY)` | `date + INTERVAL '1 day'` |
| **String length** | `LENGTH(str)` | `LENGTH(str)` (Same) |
| **Substring** | `SUBSTR(str, pos, len)` | `SUBSTRING(str FROM pos FOR len)` |

---

### Date Functions
```sql
-- BigQuery
EXTRACT(YEAR FROM date_column)
DATE_TRUNC(date_column, MONTH)
DATE_DIFF(date1, date2, DAY)

-- PostgreSQL
EXTRACT(YEAR FROM date_column)  -- Same!
DATE_TRUNC('month', date_column)  -- Note: 'month' is a string
date2 - date1  -- Returns integer (days difference)
```

---

<a name="12-common-errors"></a>
## 12. COMMON ERRORS & HOW TO FIX THEM

### Error 1: Column Does Not Exist
```sql
-- ERROR: column "first_name" does not exist
SELECT first_name FROM patients;

-- FIX: Use schema-qualified table name
SELECT first_name FROM raw.patients;

-- OR: Use quotes if column has special chars
SELECT "First Name" FROM raw.patients;
```

---

### Error 2: Relation Does Not Exist
```sql
-- ERROR: relation "patients" does not exist
SELECT * FROM patients;

-- FIX 1: Include schema
SELECT * FROM raw.patients;

-- FIX 2: Check table actually exists
\dt raw.*
```

---

### Error 3: Syntax Error Near "..."
```sql
-- ERROR: syntax error at or near "GROUP"
SELECT region COUNT(*) FROM raw.patients GROUP BY region;

-- FIX: Missing comma
SELECT region, COUNT(*) FROM raw.patients GROUP BY region;
```

---

### Error 4: Column Must Appear in GROUP BY
```sql
-- ERROR: column "first_name" must appear in GROUP BY clause
SELECT region, first_name, COUNT(*) 
FROM raw.patients 
GROUP BY region;

-- FIX: Include all non-aggregated columns in GROUP BY
SELECT region, first_name, COUNT(*) 
FROM raw.patients 
GROUP BY region, first_name;
```

**Rule:** Every column in SELECT (except aggregates) must be in GROUP BY

---

### Error 5: Division by Zero
```sql
-- ERROR: division by zero
SELECT 100.0 / COUNT(*) FROM raw.patients WHERE region = 'NonExistent';

-- FIX: Use NULLIF
SELECT 100.0 / NULLIF(COUNT(*), 0) FROM raw.patients WHERE region = 'NonExistent';
-- Returns NULL instead of error
```

---

### Error 6: Invalid Input Syntax for Type
```sql
-- ERROR: invalid input syntax for type date: "2024-15-01"
SELECT * FROM raw.deliveries WHERE delivery_date = '2024-15-01';

-- FIX: Use correct date format (YYYY-MM-DD)
SELECT * FROM raw.deliveries WHERE delivery_date = '2024-01-15';
```

---

<a name="13-quick-reference"></a>
## 13. QUICK REFERENCE CARD

### Basic Query Structure
```sql
SELECT column1, column2                    -- What columns?
FROM schema_name.table_name                -- From which table?
WHERE condition                            -- Filter rows
GROUP BY column1                           -- Group for aggregation
HAVING aggregate_condition                 -- Filter groups
ORDER BY column1 DESC                      -- Sort results
LIMIT 10                                   -- Limit output
OFFSET 20;                                 -- Skip rows
```

**Order matters! You can't put WHERE after GROUP BY.**

---

### Operators Cheat Sheet

**Comparison:**
```sql
=    !=   <>   >    <    >=   <=
```

**Logical:**
```sql
AND   OR   NOT
```

**Pattern Matching:**
```sql
LIKE 'M%'           -- Starts with M
LIKE '%son'         -- Ends with son
LIKE '%middle%'     -- Contains middle
ILIKE 'M%'          -- Case-insensitive (PostgreSQL)
```

**NULL:**
```sql
IS NULL
IS NOT NULL
```

**Lists:**
```sql
IN ('value1', 'value2', 'value3')
NOT IN ('value1', 'value2')
```

**Ranges:**
```sql
BETWEEN 35 AND 40   -- Inclusive
```

---

### Aggregate Functions
```sql
COUNT(*)                -- Count all rows
COUNT(column)           -- Count non-NULL
COUNT(DISTINCT column)  -- Count unique
SUM(column)             -- Sum numeric values
AVG(column)             -- Average
MIN(column)             -- Minimum
MAX(column)             -- Maximum
ROUND(value, decimals)  -- Round to decimals
```

---

### Date Functions
```sql
EXTRACT(YEAR FROM date_column)
EXTRACT(MONTH FROM date_column)
EXTRACT(DAY FROM date_column)
DATE_TRUNC('month', date_column)
AGE(later_date, earlier_date)
CURRENT_DATE
CURRENT_TIMESTAMP
```

---

### String Functions
```sql
UPPER(text)                 -- UPPERCASE
LOWER(text)                 -- lowercase
INITCAP(text)               -- Title Case
LENGTH(text)                -- String length
TRIM(text)                  -- Remove spaces
CONCAT(str1, str2)          -- Concatenate
str1 || str2                -- Concatenate (operator)
SUBSTRING(text FROM 1 FOR 5)  -- Extract substring
```

---

### NULL Functions
```sql
COALESCE(value, default)    -- Use default if NULL
NULLIF(value, match)        -- Return NULL if match
```

---

### Common Patterns

**Rate calculation:**
```sql
ROUND(100.0 * SUM(CASE WHEN condition THEN 1 ELSE 0 END) / COUNT(*), 1) AS rate_pct
```

**Age from birthdate:**
```sql
EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) AS age
```

**Data quality check:**
```sql
SUM(CASE WHEN column IS NULL THEN 1 ELSE 0 END) AS null_count
```

---
