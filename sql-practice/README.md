# SQL practice for technical interview preparation

**Purpose:** Intensive SQL training for Resilience Care Junior Analytics Engineer technical test  
**Candidate:** Kamlesh Seeruttun  
**Test date:** February 26, 2026  
**Interview round:** Technical & business test (1 h 15 - Round 2 of 4)  
**Interviewer:** Jean-Baptiste Pajot (Data Analytics Lead)  

---

## Preparation overview

**Total duration:** 18 days (February 9-26, 2026)  
**Daily commitment:** 2-4 hours  
**Dataset:** Maternal Health Analytics (186K records, 5 tables, PostgreSQL)  
**Tech stack:** PostgreSQL 14, dbt, Metabase (Resilience Care stack)  

---

## Complete training schedule

### **Phase 1: SQL Fundamentals (Days 1-7) - Feb 8-14**

| Day | Date | Topic | Duration | Status |
|-----|------|-------|----------|--------|
| **Day 1** | Feb 8-9 | SQL Fundamentals + JOINs proficiency | 4-5 hours | 🔄 In Progress |
| **Day 2** | Feb 10 | Advanced aggregations + GROUP BY | 3-4 hours | ⏳ Planned |
| **Day 3** | Feb 11 | CASE statements + subqueries | 3-4 hours | ⏳ Planned |
| **Day 4** | Feb 12 | CTEs (Common table expressions) | 3-4 hours | ⏳ Planned |
| **Day 5** | Feb 13 | Window functions | 3-4 hours | ⏳ Planned |
| **Day 6** | Feb 14 | Data quality checks | 2-3 hours | ⏳ Planned |

### **Phase 2: Consolidation & speed (Days 8-13) - Feb 15-20**

| Day | Date | Activity | Duration | Status |
|-----|------|----------|----------|--------|
| **Day 7** | Feb 15 | Review weak areas + speed drills | 3 hours | ⏳ Planned |
| **Day 8** | Feb 16 | Business analysis scenarios | 3 hours | ⏳ Planned |
| **Day 9** | Feb 17 | Mock test #1 (full 75 mins) | 2 hours | ⏳ Planned |
| **Day 10** | Feb 18 | Mock test #1 review + fixes | 2 hours | ⏳ Planned |
| **Day 11** | Feb 19 | Advanced patterns practice | 3 hours | ⏳ Planned |
| **Day 12** | Feb 20 | Mock test #2 (full 75 mins) | 2 hours | ⏳ Planned |

### **Phase 3: Peak performance (Days 14-19) - Feb 21-26**

| Day | Date | Activity | Duration | Status |
|-----|------|----------|----------|--------|
| **Day 13** | Feb 21 | Mock test #2 review | 2 hours | ⏳ Planned |
| **Day 14** | Feb 22 | Healthcare analytics patterns | 2 hours | ⏳ Planned |
| **Day 15** | Feb 23 | Mock test #3 | 2 hours | ⏳ Planned |
| **Day 16** | Feb 24 | Light review + rest | 1 hour | ⏳ Planned |
| **Day 17** | Feb 25 AM | Final mental prep + review notes | 30 mins | ⏳ Planned |
| **Day 18** | **Feb 26 AM** | **🔥 TECHNICAL TEST 🔥** | **75 mins** | **GOAL** |

---

## Learning objectives by day

### **Day 1: SQL fundamentals + JOINs proficiency**

**Session 1 (Warm-up - Feb 8):** ✅ Complete
- SELECT, WHERE, ORDER BY, LIMIT
- GROUP BY, HAVING
- COUNT(), AVG(), ROUND()
- Boolean filtering
- **Queries completed:** 7

**Session 2 (JOINs - Feb 9):** ✅ Complete
- INNER JOIN (matching rows only)
- LEFT JOIN (keep all from left table)
- Multiple JOINs (3-4 table chains)
- JOIN + aggregation patterns
- NULL handling (IS NULL, IS NOT NULL)
- DISTINCT, IN, BETWEEN operators
- Healthcare analytics patterns (rate calculations)
- **Target queries:** 20+

**Key skills gained:**
- Basic SELECT syntax
- Filtering with WHERE
- Sorting and limiting results
- Connecting tables with JOINs
- Finding missing data (LEFT JOIN + WHERE IS NULL)
- Multi-table analysis

---

### **Day 2: Advanced aggregations + GROUP BY**

**Topics:**
- Aggregate functions deep dive (COUNT, SUM, AVG, MIN, MAX)
- GROUP BY single vs multiple columns
- HAVING clause (filter aggregated results)
- WHERE vs HAVING comparison
- CASE WHEN for categorization
- Multi-metric dashboard queries
- Regional/facility-level analysis

**Healthcare examples:**
- Cesarean rate by region
- Preterm birth rate by age group
- Facility performance metrics
- Insurance coverage analysis

**Target queries:** 15+

---

### **Day 3: CASE statements + subqueries**

**Topics:**
- Advanced CASE WHEN (nested conditions)
- CASE for calculated fields (risk scoring)
- Subqueries in WHERE clause
- Subqueries in SELECT clause
- Subqueries in FROM clause
- Correlated subqueries
- Date/time functions (EXTRACT, DATE_TRUNC, AGE)
- String functions (UPPER, LOWER, CONCAT, LIKE/ILIKE)

**Healthcare examples:**
- Risk categorization (low/medium/high)
- Composite risk scores (0-10 scale)
- Comparing to benchmarks (above/below average)
- Temporal analysis (gestational age calculations)

**Target queries:** 15+

---

### **Day 4: CTEs (Common table expressions)**

**Topics:**
- Basic CTEs (WITH clause)
- Multiple CTEs (chaining logic)
- CTEs vs subqueries (when to use each)
- Recursive CTEs (optional/advanced)
- dbt-style layered approach (staging → marts)

**Why CTEs matter:**
- dbt uses CTEs extensively
- Makes complex queries readable
- Essential for analytics engineering
- Interview favorite topic

**Healthcare examples:**
- Multi-step calculations (staged transformations)
- Patient cohort analysis
- Benchmark comparisons with CTEs

**Target queries:** 12+

---

### **Day 5: Window functions**

**Topics:**
- ROW_NUMBER(), RANK(), DENSE_RANK()
- PARTITION BY (grouping within window)
- ORDER BY (sorting within window)
- Aggregate window functions (SUM/AVG/COUNT OVER)
- Running totals and cumulative sums
- Moving averages (7-day, 30-day rolling)
- LAG() and LEAD() (previous/next row values)
- ROWS BETWEEN (frame specification)

**Healthcare examples:**
- Pregnancy sequence numbering (1st, 2nd, 3rd pregnancy)
- Monthly delivery trends (cumulative)
- Rolling averages (cesarean rate over time)
- Month-over-month comparisons

**Target queries:** 12+

---

### **Day 6: Data quality checks**

**Topics:**
- NULL detection and counting
- Duplicate detection (duplicated() patterns)
- Referential integrity checks (orphan records)
- Business logic validation (dates, ranges)
- Outlier detection (statistical methods)
- Data profiling queries

**Healthcare examples:**
- Find visits after delivery date (data quality issue)
- Detect impossible values (negative birth weight)
- Check primary/foreign key integrity
- Identify missing critical fields

**Target queries:** 10+

## Motivation

**This planned practice session is not just about passing a test. It's about:**
- Joining a mission-driven company (Resilience Care improves patient outcomes)
- Building a career in analytics engineering (technical + business + impact)
- Working with healthcare data that saves lives
- Learning skills that compound over time

**The 18 days of focused practice will:**
- Transform intermediate SQL → confident analytics engineer SQL
- Build muscle memory for common patterns
- Develop business translation skills
- Prove I can learn quickly and systematically

**This is an investment in my future as an analytics engineer.**

---

**Last updated:** February 9, 2026  
**Current status:** Day 1 Session 2 complete (JOINs proficiency) ✅  
**Upcoming session:** Day 2 (Advanced aggregations + GROUP BY) - February 10, 2026

---