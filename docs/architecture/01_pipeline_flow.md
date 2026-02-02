# High-level data pipeline flow
```mermaid
graph LR
    A[Python Script<br/>generate_maternal_health_data.py] -->|Generates| B[CSV Files<br/>186K records<br/>2020-2024]
    B -->|load_data_to_postgres.py| C[(PostgreSQL<br/>Raw Schema)]
    C -->|dbt run| D[dbt Models<br/>Staging → Intermediate → Marts]
    D -->|Analytics Schema| E[(PostgreSQL<br/>Analytics Schema)]
    E -->|JDBC Connection| F[Metabase<br/>Dashboards]
    
    G[ENP 2021<br/>Statistics] -.->|Validates| A
    H[GitHub Actions<br/>CI/CD] -.->|Tests & Deploys| D
    
    style A fill:#e1f5ff
    style B fill:#fff4e1
    style C fill:#ffe1e1
    style D fill:#e1ffe1
    style E fill:#ffe1f5
    style F fill:#f5e1ff
    style G fill:#f0f0f0
    style H fill:#f0f0f0
```

## Key components

**Data generation:**
- Synthetic data based on French National Perinatal Survey 2021
- 5 tables: patients, pregnancies, prenatal_visits, deliveries, birth_outcomes

**Storage:**
- PostgreSQL 14 with 3 schemas: raw, staging, analytics

**Transformation:**
- dbt for data modeling and testing
- Layered approach: Bronze (raw) → Silver (staging) → Gold (analytics)

**Visualization:**
- Metabase for self-service BI dashboards

**Quality assurance:**
- GitHub Actions for automated testing
- dbt tests for data quality