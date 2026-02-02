#!/usr/bin/env python3
"""
Load maternal health CSV data into PostgreSQL raw schema
"""

import pandas as pd
import psycopg2
from sqlalchemy import create_engine
import sys

# Database credentials
DB_CONFIG = {
    'host': 'localhost',
    'database': 'maternal_health_db',
    'user': 'maternal_user',
    'password': 'maternal_dev_2026'
}

def create_connection():
    """Create PostgreSQL connection"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        print(f"Connection failed: {e}")
        sys.exit(1)

def create_schemas(conn):
    """Create database schemas"""
    cur = conn.cursor()
    
    print("\nCreating schemas...")
    schemas = ['raw', 'staging', 'analytics']
    
    for schema in schemas:
        cur.execute(f"CREATE SCHEMA IF NOT EXISTS {schema}")
    
    conn.commit()
    print("Schemas created")
    cur.close()

def create_tables(conn):
    """Create all raw tables"""
    cur = conn.cursor()
    
    print("\n Creating tables...")
    
    # 1. Patients
    cur.execute("""
    DROP TABLE IF EXISTS raw.patients CASCADE;
    CREATE TABLE raw.patients (
        patient_id VARCHAR(50) PRIMARY KEY,
        first_name VARCHAR(100),
        last_name VARCHAR(100),
        birth_date DATE,
        region VARCHAR(100),
        postal_code VARCHAR(10),
        education_level VARCHAR(50),
        is_employed BOOLEAN,
        has_partner BOOLEAN,
        receives_welfare BOOLEAN,
        has_health_insurance BOOLEAN,
        has_supplementary_insurance BOOLEAN,
        nationality VARCHAR(100)
    );
    """)
    
    # 2. Pregnancies
    cur.execute("""
    DROP TABLE IF EXISTS raw.pregnancies CASCADE;
    CREATE TABLE raw.pregnancies (
        pregnancy_id VARCHAR(50) PRIMARY KEY,
        patient_id VARCHAR(50),
        pregnancy_number INTEGER,
        lmp_date DATE,
        edd DATE,
        delivery_date DATE,
        maternal_age_at_delivery INTEGER,
        pre_pregnancy_bmi DECIMAL(5,2),
        gestational_weeks INTEGER,
        initial_risk_score INTEGER,
        gestational_diabetes BOOLEAN,
        preeclampsia BOOLEAN,
        placental_issues BOOLEAN,
        is_multiple_gestation BOOLEAN,
        smoking_3rd_trimester BOOLEAN,
        alcohol_use BOOLEAN,
        cannabis_use BOOLEAN,
        covid_infection BOOLEAN
    );
    """)
    
    # 3. Prenatal visits
    cur.execute("""
    DROP TABLE IF EXISTS raw.prenatal_visits CASCADE;
    CREATE TABLE raw.prenatal_visits (
        visit_id VARCHAR(50) PRIMARY KEY,
        pregnancy_id VARCHAR(50),
        visit_number INTEGER,
        visit_date DATE,
        gestational_week INTEGER,
        provider_type VARCHAR(50),
        bp_systolic INTEGER,
        bp_diastolic INTEGER,
        weight_kg DECIMAL(5,2),
        fundal_height_cm DECIMAL(5,2),
        fetal_heart_rate INTEGER,
        glucose_test BOOLEAN,
        down_syndrome_screening BOOLEAN,
        ultrasound_performed BOOLEAN,
        risk_score_at_visit INTEGER
    );
    """)
    
    # 4. Deliveries
    cur.execute("""
    DROP TABLE IF EXISTS raw.deliveries CASCADE;
    CREATE TABLE raw.deliveries (
        delivery_id VARCHAR(50) PRIMARY KEY,
        pregnancy_id VARCHAR(50),
        delivery_date DATE,
        delivery_time TIME,
        facility_type VARCHAR(50),
        facility_name VARCHAR(200),
        labor_induced BOOLEAN,
        spontaneous_labor BOOLEAN,
        artificial_rupture_membranes BOOLEAN,
        oxytocin_used BOOLEAN,
        epidural BOOLEAN,
        pain_level INTEGER,
        delivery_mode VARCHAR(50),
        delivery_method VARCHAR(100),
        episiotomy BOOLEAN,
        perineal_tear BOOLEAN,
        perineal_tear_degree VARCHAR(20),
        labor_duration_minutes INTEGER,
        blood_loss_ml INTEGER,
        maternal_complications TEXT,
        attending_obstetrician VARCHAR(200),
        attending_midwife VARCHAR(200)
    );
    """)
    
    # 5. Birth outcomes
    cur.execute("""
    DROP TABLE IF EXISTS raw.birth_outcomes CASCADE;
    CREATE TABLE raw.birth_outcomes (
        outcome_id VARCHAR(50) PRIMARY KEY,
        delivery_id VARCHAR(50),
        pregnancy_id VARCHAR(50),
        infant_number INTEGER,
        sex VARCHAR(10),
        birth_weight_grams INTEGER,
        birth_length_cm DECIMAL(5,2),
        head_circumference_cm DECIMAL(5,2),
        apgar_1min INTEGER,
        apgar_5min INTEGER,
        gestational_age_weeks INTEGER,
        low_birth_weight BOOLEAN,
        preterm_birth BOOLEAN,
        neonatal_complications TEXT,
        nicu_admission BOOLEAN,
        nicu_days INTEGER,
        breastfeeding_initiation BOOLEAN
    );
    """)
    
    conn.commit()
    print("All tables created")
    cur.close()

def load_csv_data():
    """Load CSV files into PostgreSQL using SQLAlchemy"""
    
    # Create SQLAlchemy engine
    engine = create_engine(
        f"postgresql://{DB_CONFIG['user']}:{DB_CONFIG['password']}@{DB_CONFIG['host']}/{DB_CONFIG['database']}"
    )
    
    print("\n Loading CSV files...")
    
    DATA_PATH = '../data/raw'
    
    # Define tables and their date columns
    tables_config = {
        'patients': {
            'file': 'patients.csv',
            'date_cols': ['birth_date']
        },
        'pregnancies': {
            'file': 'pregnancies.csv',
            'date_cols': ['lmp_date', 'edd', 'delivery_date']
        },
        'prenatal_visits': {
            'file': 'prenatal_visits.csv',
            'date_cols': ['visit_date']
        },
        'deliveries': {
            'file': 'deliveries.csv',
            'date_cols': ['delivery_date']
        },
        'birth_outcomes': {
            'file': 'birth_outcomes.csv',
            'date_cols': []
        }
    }
    
    # Load each table
    for table_name, config in tables_config.items():
        print(f"\n  Loading {table_name}...")
        
        try:
            # Read CSV
            df = pd.read_csv(f"{DATA_PATH}/{config['file']}")
            
            # Convert date columns
            for col in config['date_cols']:
                if col in df.columns:
                    df[col] = pd.to_datetime(df[col]).dt.date
            
            # Load to PostgreSQL
            df.to_sql(
                table_name,
                engine,
                schema='raw',
                if_exists='replace',
                index=False,
                method='multi',
                chunksize=1000
            )
            
            print(f"    Loaded {len(df):,} rows")
            
        except Exception as e:
            print(f"    Failed to load {table_name}: {e}")
    
    engine.dispose()

def verify_data(conn):
    """Verify row counts"""
    cur = conn.cursor()
    
    print("\n VERIFICATION - Row Counts:")
    print("=" * 50)
    
    tables = ['patients', 'pregnancies', 'prenatal_visits', 'deliveries', 'birth_outcomes']
    
    for table in tables:
        cur.execute(f"SELECT COUNT(*) FROM raw.{table}")
        count = cur.fetchone()[0]
        print(f"  {table:20s} → {count:>7,} rows")
    
    print("=" * 50)
    cur.close()

def main():
    """Main execution"""
    print("=" * 60)
    print("  MATERNAL HEALTH DATA LOADER")
    print("=" * 60)
    
    # Connect
    conn = create_connection()
    print("Connected to PostgreSQL")
    
    # Create schemas
    create_schemas(conn)
    
    # Create tables
    create_tables(conn)
    
    # Load data
    load_csv_data()
    
    # Verify
    verify_data(conn)
    
    # Close connection
    conn.close()
    
    print("\n DATA LOADING COMPLETE!\n")

if __name__ == "__main__":
    main()