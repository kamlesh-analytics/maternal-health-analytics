# dbt project architecture
```mermaid
graph TD
    subgraph "RAW LAYER (Bronze)"
        R1[raw.patients]
        R2[raw.pregnancies]
        R3[raw.prenatal_visits]
        R4[raw.deliveries]
        R5[raw.birth_outcomes]
    end
    
    subgraph "STAGING LAYER (Silver)"
        S1[stg_patients<br/>• Clean NULLs<br/>• Hash PII]
        S2[stg_pregnancies<br/>• Validate dates<br/>• Risk scoring]
        S3[stg_prenatal_visits<br/>• Remove duplicates<br/>• Date validation]
        S4[stg_deliveries<br/>• Standardize codes]
        S5[stg_birth_outcomes<br/>• Clean data]
    end
    
    subgraph "INTERMEDIATE LAYER"
        I1[int_patient_cohorts<br/>• Age groups<br/>• BMI categories]
        I2[int_pregnancy_risk<br/>• Risk calculations<br/>• Complication flags]
        I3[int_delivery_metrics<br/>• Labor duration<br/>• Outcome classification]
    end
    
    subgraph "MARTS LAYER (Gold)"
        M1[dim_patients<br/>Demographics]
        M2[dim_time<br/>Date dimension]
        M3[dim_facilities<br/>Facility data]
        M4[fact_deliveries<br/>Delivery events]
        M5[fact_prenatal_visits<br/>Visit history]
    end
    
    R1 --> S1
    R2 --> S2
    R3 --> S3
    R4 --> S4
    R5 --> S5
    
    S1 --> I1
    S2 --> I2
    S4 --> I3
    
    I1 --> M1
    I2 --> M4
    I3 --> M4
    S3 --> M5
    
    style R1 fill:#ffe1e1
    style R2 fill:#ffe1e1
    style R3 fill:#ffe1e1
    style R4 fill:#ffe1e1
    style R5 fill:#ffe1e1
    
    style S1 fill:#fff4e1
    style S2 fill:#fff4e1
    style S3 fill:#fff4e1
    style S4 fill:#fff4e1
    style S5 fill:#fff4e1
    
    style I1 fill:#e1f5ff
    style I2 fill:#e1f5ff
    style I3 fill:#e1f5ff
    
    style M1 fill:#e1ffe1
    style M2 fill:#e1ffe1
    style M3 fill:#e1ffe1
    style M4 fill:#e1ffe1
    style M5 fill:#e1ffe1
```

## Layer descriptions

**Raw (Bronze):** Unmodified source data from CSV files

**Staging (Silver):** Cleaned, standardized, deduplicated data with:
- NULL handling
- PII hashing
- Date validation
- Type casting

**Intermediate:** Business logic and calculations:
- Cohort definitions
- Risk scoring
- Metric calculations
- Reusable transformations

**Marts (Gold):** Analytics-ready dimensional models:
- Star schema design
- Denormalized for query performance
- Dashboard-ready metrics