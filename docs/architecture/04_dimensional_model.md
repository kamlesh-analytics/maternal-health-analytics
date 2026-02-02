# Dimensional model (Star schema)
```mermaid
graph TD
    subgraph "FACT TABLES"
        F1[fact_deliveries<br/>━━━━━━━━━━<br/>delivery_key PK<br/>patient_key FK<br/>time_key FK<br/>facility_key FK<br/>━━━━━━━━━━<br/>delivery_mode<br/>labor_duration_min<br/>blood_loss_ml<br/>cesarean_flag<br/>complication_flag]
        
        F2[fact_prenatal_visits<br/>━━━━━━━━━━<br/>visit_key PK<br/>patient_key FK<br/>time_key FK<br/>pregnancy_key FK<br/>━━━━━━━━━━<br/>gestational_week<br/>bp_systolic<br/>risk_score<br/>provider_type]
    end
    
    subgraph "DIMENSION TABLES"
        D1[dim_patients<br/>━━━━━━━━━━<br/>patient_key PK<br/>━━━━━━━━━━<br/>patient_id_hash<br/>age_group<br/>bmi_category<br/>education_level<br/>region<br/>insurance_status]
        
        D2[dim_time<br/>━━━━━━━━━━<br/>time_key PK<br/>━━━━━━━━━━<br/>date<br/>year<br/>quarter<br/>month<br/>week<br/>day_of_week]
        
        D3[dim_facilities<br/>━━━━━━━━━━<br/>facility_key PK<br/>━━━━━━━━━━<br/>facility_name<br/>facility_type<br/>region]
        
        D4[dim_pregnancy<br/>━━━━━━━━━━<br/>pregnancy_key PK<br/>━━━━━━━━━━<br/>pregnancy_number<br/>gestational_weeks<br/>risk_category<br/>complications]
    end
    
    F1 --> D1
    F1 --> D2
    F1 --> D3
    
    F2 --> D1
    F2 --> D2
    F2 --> D4
    
    style F1 fill:#ffe1e1
    style F2 fill:#ffe1e1
    style D1 fill:#e1f5ff
    style D2 fill:#e1f5ff
    style D3 fill:#e1f5ff
    style D4 fill:#e1f5ff
```

## Star schema design

**Fact Tables (Measures):**
- `fact_deliveries`: One row per delivery with metrics
- `fact_prenatal_visits`: One row per visit (117K rows)

**Dimension Tables (Context):**
- `dim_patients`: Who (demographics, age groups, BMI categories)
- `dim_time`: When (date hierarchy for time-series analysis)
- `dim_facilities`: Where (facility types, regions)
- `dim_pregnancy`: What (pregnancy characteristics, risk levels)

## Key features

✅ **Denormalized for performance:** Pre-joined for fast queries  
✅ **Surrogate keys:** Integer keys for efficient joins  
✅ **SCD Type 2 ready:** Track changing risk scores over time  
✅ **Dashboard optimized:** Pre-calculated metrics and categories