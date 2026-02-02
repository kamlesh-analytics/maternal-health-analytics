# Entity relationship diagram
```mermaid
erDiagram
    PATIENTS ||--o{ PREGNANCIES : has
    PREGNANCIES ||--o{ PRENATAL_VISITS : includes
    PREGNANCIES ||--|| DELIVERIES : results_in
    DELIVERIES ||--o{ BIRTH_OUTCOMES : produces
    
    PATIENTS {
        varchar patient_id PK
        varchar first_name
        varchar last_name
        date birth_date
        varchar region
        varchar education_level
        boolean has_health_insurance
    }
    
    PREGNANCIES {
        varchar pregnancy_id PK
        varchar patient_id FK
        int pregnancy_number
        date lmp_date
        date delivery_date
        int maternal_age
        decimal pre_pregnancy_bmi
        boolean gestational_diabetes
        boolean preeclampsia
    }
    
    PRENATAL_VISITS {
        varchar visit_id PK
        varchar pregnancy_id FK
        int visit_number
        date visit_date
        int gestational_week
        varchar provider_type
        int bp_systolic
        int risk_score_at_visit
    }
    
    DELIVERIES {
        varchar delivery_id PK
        varchar pregnancy_id FK
        date delivery_date
        varchar facility_type
        varchar delivery_mode
        boolean epidural
        int labor_duration_minutes
    }
    
    BIRTH_OUTCOMES {
        varchar outcome_id PK
        varchar delivery_id FK
        varchar pregnancy_id FK
        int infant_number
        int birth_weight_grams
        int apgar_5min
        boolean preterm_birth
    }
```

## Relationships

**One-to-Many:**
- 1 patient → many pregnancies
- 1 pregnancy → many prenatal visits
- 1 delivery → 1-2 birth outcomes (twins)

**One-to-One:**
- 1 pregnancy → 1 delivery

## Key constraints

- All foreign keys validated in dbt with `relationships` tests
- Primary keys tested for uniqueness
- Date sequences validated (visit before delivery)