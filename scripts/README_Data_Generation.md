# Synthetic French maternal health data generator

## Overview
This script generates realistic synthetic patient-level maternal health data based on French National Perinatal Survey (ENP) 2021 statistics.

## What it generates

### 5 CSV files:

1. **patients.csv** (~10,000 records)
   - Patient demographics, socioeconomic status
   - PII fields (names, IDs, birth dates)
   - Regional distribution across 13 French regions

2. **pregnancies.csv** (~15,000 records)
   - Pregnancy details, risk factors
   - Complications (gestational diabetes, preeclampsia)
   - Temporal trends (2020-2024)

3. **prenatal_visits.csv** (~100,000+ records)
   - Incremental data (dates range 2020-2024)
   - Vital signs, screening results
   - Risk scores that change over time (for snapshots!)

4. **deliveries.csv** (~15,000 records)
   - Labor characteristics, interventions
   - Delivery mode, complications
   - Healthcare provider information

5. **birth_outcomes.csv** (~15,300 records)
   - Infant characteristics (weight, length, Apgar)
   - Neonatal complications
   - Breastfeeding initiation

## Data characteristics

### Realistic distributions
- Matches ENP 2021 statistics exactly
- Temporal trends from 2020-2024:
  - Increasing maternal age
  - Rising obesity rates
  - Decreasing smoking
  - Increasing midwife-led care

### Rich relationships
- Proper foreign keys for dimensional modeling
- One-to-many relationships (patient → pregnancies → visits)
- Supports fact and dimension table design

### Time-series data
- Visits span 2020-2024 (perfect for incremental models)
- Risk scores change over time (perfect for SCD Type 2 snapshots)
- Can demonstrate freshness monitoring

### Intentional data quality issues
- NULL values in some fields (test NOT NULL)
- Duplicate records (~20 in visits)
- Invalid date sequences (~10 visits after delivery)
- Great for showcasing dbt data quality tests!

### PII for data governance
- Patient names (to practice masking)
- Patient IDs (to practice hashing)
- Birth dates, postal codes

## Requirements

```bash
pip install faker pandas numpy
```

## How to run

### Option 1: On your local machine (Recommended)

1. **Download the script**
   - Save `generate_maternal_health_data.py` to your project folder

2. **Install dependencies**
   ```bash
   cd ~/maternal-health-analytics
   source venv/bin/activate
   pip install faker pandas numpy
   ```

3. **Run the script**
   ```bash
   python generate_maternal_health_data.py
   ```

4. **Output location**
   - Creates folder: `/home/yourusername/maternal_health_data/`
   - Contains 5 CSV files

5. **Move to your project**
   ```bash
   mkdir -p ~/maternal-health-analytics/data/raw
   mv ~/maternal_health_data/*.csv ~/maternal-health-analytics/data/raw/
   ```

### Option 2: Adjust output location

Edit line in script:
```python
output_dir = '/home/yourusername/maternal_health_data'
```

Change to:
```python
output_dir = '/home/yourusername/maternal-health-analytics/data/raw'
```

## What you'll see

```
Starting synthetic data generation...
Target: 10000 patients from 2020-01-01 to 2024-12-31

1. Generating patients table...
Generated 10000 patients

2. Generating pregnancies table...
Generated 15249 pregnancies

3. Generating prenatal visits table...
Generated 108765 prenatal visits

4. Generating deliveries table...
Generated 15249 deliveries

5. Generating birth outcomes table...
Generated 15638 birth outcomes

6. Adding intentional data quality issues for dbt testing...
Added data quality issues:
  - 50 NULL education levels
  - 100 NULL BP measurements
  - 20 duplicate visit records
  - 10 visits with impossible dates

7. Saving data to CSV files...

DATASET OVERVIEW:
  Total patients: 10,000
  Total pregnancies: 15,249
  Total prenatal visits: 108,785
  Total deliveries: 15,249
  Total birth outcomes: 15,638
  Date range: 2020-01-01 to 2024-12-31

KEY METRICS (matching ENP 2021):
  Median maternal age: 31.2 years
  Mothers 35+: 24.5%
  Obesity rate (BMI ≥30): 14.3%
  Cesarean rate: 21.5%
  Preterm births (<37w): 7.1%
  Epidural rate: 82.6%
  Mean birth weight: 3245g
```

## Next steps after generation

1. **Load into PostgreSQL**
   ```sql
   CREATE TABLE raw_patients AS 
   SELECT * FROM read_csv_auto('data/raw/patients.csv');
   ```

2. **Set up dbt sources**
   ```yaml
   sources:
     - name: raw_maternal_health
       tables:
         - name: patients
         - name: pregnancies
         - name: prenatal_visits
         - name: deliveries
         - name: birth_outcomes
   ```

3. **Start building staging models**
   - Clean NULL values
   - Remove duplicates
   - Validate date sequences
   - Hash PII fields

## Customization

### Change number of patients
Edit line 22:
```python
NUM_PATIENTS = 10000  # Change this
```

### Change date range
Edit lines 23-24:
```python
START_DATE = datetime(2020, 1, 1)  # Change start
END_DATE = datetime(2024, 12, 31)   # Change end
```

### Adjust distributions
All distributions are parameterized in the script. Search for specific rates like:
- `0.214` for cesarean rate
- `0.827` for epidural rate
- Adjust as needed

## Citation

Data structure and distributions based on:
**Le Ray C, Lelong N, Cinelli H, Blondel B.** Results of the 2021 French national perinatal survey and trends in perinatal health in metropolitan France since 1995. *J Gynecol Obstet Hum Reprod.* 2022 Dec;51(10):102509.

Official report: https://enp.inserm.fr/