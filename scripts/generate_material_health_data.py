"""
Synthetic French maternal health data generator
Based on ENP 2021 (Enquête nationale périnatale 2021) Statistics

This script generates realistic patient-level data matching French National Perinatal Survey distributions.
Generates data for 10,000 patients from 2020-2024 with proper relationships and temporal trends.

Author: Kamlesh Seeruttun
Date: January 2026
"""

# Standard library imports
import os
import random
from datetime import datetime, timedelta

# Third-party imports
import pandas as pd
import numpy as np
from faker import Faker


# Initialize Faker with French locale
fake = Faker('fr_FR')
np.random.seed(42)  # For reproducibility
random.seed(42)

# Configuration
NUM_PATIENTS = 10000
START_DATE = datetime(2020, 1, 1)
END_DATE = datetime(2024, 12, 31)

print("Starting synthetic data generation...")
print(f"Target: {NUM_PATIENTS} patients from {START_DATE.date()} to {END_DATE.date()}")

# ============================================================================
# REFERENCE DATA - French regions
# ============================================================================

FRENCH_REGIONS = [
    ('Île-de-France', 0.20),  # 20% of population
    ('Auvergne-Rhône-Alpes', 0.12),
    ('Nouvelle-Aquitaine', 0.09),
    ('Occitanie', 0.09),
    ('Hauts-de-France', 0.09),
    ('Provence-Alpes-Côte d\'Azur', 0.08),
    ('Grand Est', 0.08),
    ('Pays de la Loire', 0.06),
    ('Bretagne', 0.05),
    ('Normandie', 0.05),
    ('Bourgogne-Franche-Comté', 0.04),
    ('Centre-Val de Loire', 0.04),
    ('Corse', 0.01)
]

FACILITY_TYPES = ['Type I', 'Type IIA', 'Type IIB', 'Type III', 'Birth Center']
FACILITY_TYPE_WEIGHTS = [0.30, 0.35, 0.15, 0.18, 0.02]

EDUCATION_LEVELS = ['No diploma', 'CAP/BEP', 'Baccalauréat', 'Bachelor', 'Master+']
EDUCATION_WEIGHTS = [0.10, 0.20, 0.20, 0.30, 0.20]

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def generate_birth_date(year_bias=None):
    """Generate realistic birth date with temporal trends"""
    if year_bias:
        # Bias towards specific year for temporal trends
        year = year_bias
        month = random.randint(1, 12)
        day = random.randint(1, 28)
        return datetime(year, month, day)
    
    # Random date within range
    days_between = (END_DATE - START_DATE).days
    random_days = random.randint(0, days_between)
    return START_DATE + timedelta(days=random_days)

def calculate_age_at_date(birth_date, reference_date):
    """Calculate age at reference date"""
    age = reference_date.year - birth_date.year
    if reference_date.month < birth_date.month or \
       (reference_date.month == birth_date.month and reference_date.day < birth_date.day):
        age -= 1
    return age

def generate_maternal_age_distribution(year):
    """
    Generate maternal age following ENP 2021 distribution with temporal trends
    - Increasing proportion of 35+ mothers over time
    """
    # Age categories and base weights (2021)
    age_ranges = [(15, 19), (20, 24), (25, 29), (30, 34), (35, 39), (40, 45)]
    base_weights = [0.015, 0.10, 0.30, 0.35, 0.192, 0.054]
    
    # Temporal adjustment: increase 35+ by 0.5% per year from 2020
    year_diff = year - 2020
    adjustment = year_diff * 0.005
    
    weights = base_weights.copy()
    weights[4] += adjustment * 0.7  # 35-39
    weights[5] += adjustment * 0.3  # 40+
    # Reduce younger ages proportionally
    weights[1] -= adjustment * 0.5  # 20-24
    weights[2] -= adjustment * 0.5  # 25-29
    
    # Normalize
    weights = np.array(weights) / sum(weights)
    
    # Select age range
    age_range = random.choices(age_ranges, weights=weights)[0]
    return random.randint(age_range[0], age_range[1])

def generate_bmi(year):
    """
    Generate BMI following ENP 2021 distribution with temporal trends
    - Increasing obesity rates over time
    """
    # BMI categories: underweight, normal, overweight, obese
    # 2021: 6%, 63%, 17%, 14.4%
    base_weights = [0.06, 0.63, 0.17, 0.144]
    
    # Temporal adjustment: increase obesity by 0.5% per year
    year_diff = year - 2020
    obesity_increase = year_diff * 0.005
    
    weights = base_weights.copy()
    weights[3] += obesity_increase  # Obese
    weights[1] -= obesity_increase  # Normal (decrease)
    
    weights = np.array(weights) / sum(weights)
    
    category = random.choices(['underweight', 'normal', 'overweight', 'obese'], weights=weights)[0]
    
    if category == 'underweight':
        return round(random.uniform(15.0, 18.4), 1)
    elif category == 'normal':
        return round(random.uniform(18.5, 24.9), 1)
    elif category == 'overweight':
        return round(random.uniform(25.0, 29.9), 1)
    else:  # obese
        return round(random.uniform(30.0, 45.0), 1)

def generate_smoking_status(year):
    """
    Smoking in 3rd trimester - decreasing trend
    2016: 16.3%, 2021: 12.2%
    """
    # Linear decrease
    base_rate = 0.163 - ((year - 2016) * 0.0082)  # ~0.82% per year
    return random.random() < base_rate

def generate_parity():
    """Parity distribution: ~40% primiparous, 60% multiparous"""
    return random.choices([1, 2, 3, 4], weights=[0.40, 0.35, 0.18, 0.07])[0]

# ============================================================================
# 1. GENERATE PATIENTS TABLE
# ============================================================================

print("\n1. Generating patients table...")

patients = []

for i in range(NUM_PATIENTS):
    patient_id = f"PAT_{str(i+1).zfill(6)}"
    
    # Birth date for patient (make them 15-50 years old)
    patient_birth_year = random.randint(1974, 2009)
    patient_birth_date = datetime(patient_birth_year, random.randint(1, 12), random.randint(1, 28))
    
    # Regional distribution
    region = random.choices([r[0] for r in FRENCH_REGIONS], 
                           weights=[r[1] for r in FRENCH_REGIONS])[0]
    
    # Generate French postal code (simplified: 5 digits starting with region code)
    region_codes = {
        'Île-de-France': ['75', '77', '78', '91', '92', '93', '94', '95'],
        'Auvergne-Rhône-Alpes': ['01', '03', '07', '15', '26', '38', '42', '43', '63', '69', '73', '74'],
        'Nouvelle-Aquitaine': ['16', '17', '19', '23', '24', '33', '40', '47', '64', '79', '86', '87'],
        'Occitanie': ['09', '11', '12', '30', '31', '32', '34', '46', '48', '65', '66', '81', '82'],
        'Hauts-de-France': ['02', '59', '60', '62', '80'],
        'Provence-Alpes-Côte d\'Azur': ['04', '05', '06', '13', '83', '84'],
        'Grand Est': ['08', '10', '51', '52', '54', '55', '57', '67', '68', '88'],
        'Pays de la Loire': ['44', '49', '53', '72', '85'],
        'Bretagne': ['22', '29', '35', '56'],
        'Normandie': ['14', '27', '50', '61', '76'],
        'Bourgogne-Franche-Comté': ['21', '25', '39', '58', '70', '71', '89', '90'],
        'Centre-Val de Loire': ['18', '28', '36', '37', '41', '45'],
        'Corse': ['2A', '2B']
    }
    postal_code_prefix = random.choice(region_codes.get(region, ['75']))
    postal_code = f"{postal_code_prefix}{str(random.randint(100, 999))}"
    
    # Education level
    education_level = random.choices(EDUCATION_LEVELS, weights=EDUCATION_WEIGHTS)[0]
    
    # Employment status
    is_employed = random.random() < 0.75  # ~75% employed
    
    # Partner status
    has_partner = random.random() < 0.87  # ~87% with partner (13% single)
    
    # Social benefits
    receives_welfare = random.random() < 0.09  # ~9% RSA
    
    # Health insurance (99% have basic coverage)
    has_health_insurance = random.random() < 0.99
    has_supplementary_insurance = random.random() < 0.93  # 93% have supplementary
    
    patients.append({
        'patient_id': patient_id,
        'first_name': fake.first_name_female(),
        'last_name': fake.last_name(),
        'birth_date': patient_birth_date.strftime('%Y-%m-%d'),
        'region': region,
        'postal_code': postal_code,
        'education_level': education_level,
        'is_employed': is_employed,
        'has_partner': has_partner,
        'receives_welfare': receives_welfare,
        'has_health_insurance': has_health_insurance,
        'has_supplementary_insurance': has_supplementary_insurance,
        'nationality': 'French' if random.random() < 0.85 else fake.country()
    })

patients_df = pd.DataFrame(patients)
print(f"Generated {len(patients_df)} patients")

# ============================================================================
# 2. GENERATE PREGNANCIES TABLE
# ============================================================================

print("\n2. Generating pregnancies table...")

pregnancies = []
pregnancy_counter = 1

for _, patient in patients_df.iterrows():
    patient_id = patient['patient_id']
    patient_birth_date = datetime.strptime(patient['birth_date'], '%Y-%m-%d')
    
    # Determine parity (number of pregnancies for this patient)
    parity = generate_parity()
    
    for pregnancy_num in range(1, parity + 1):
        pregnancy_id = f"PREG_{str(pregnancy_counter).zfill(6)}"
        pregnancy_counter += 1
        
        # Delivery date (spread across 2020-2024)
        delivery_date = generate_birth_date()
        
        # Calculate maternal age at delivery
        maternal_age = calculate_age_at_date(patient_birth_date, delivery_date)
        
        # Adjust if age is unrealistic
        if maternal_age < 15:
            years_to_add = 15 - maternal_age
            delivery_date = delivery_date + timedelta(days=365*years_to_add)
            maternal_age = 15
        elif maternal_age > 50:
            years_to_subtract = maternal_age - 45
            delivery_date = delivery_date - timedelta(days=365*years_to_subtract)
            maternal_age = 45

        # LMP (Last menstrual period) - ~40 weeks before delivery
        gestational_weeks = random.randint(22, 43)  # Include preterm and post-term
        lmp_date = delivery_date - timedelta(weeks=gestational_weeks)
        
        # Estimated due date (40 weeks from LMP)
        edd = lmp_date + timedelta(weeks=40)
        
        # BMI at start of pregnancy (year-dependent)
        pre_pregnancy_bmi = generate_bmi(delivery_date.year)
        
        # Initial risk score (will change over time for snapshots)
        # Based on age, BMI, parity
        risk_score = 0
        if maternal_age >= 35:
            risk_score += 2
        if maternal_age >= 40:
            risk_score += 3
        if pre_pregnancy_bmi >= 30:
            risk_score += 2
        if pregnancy_num == 1:  # Primiparous
            risk_score += 1
        
        # Complications (higher risk with higher score)
        has_gestational_diabetes = random.random() < (0.05 + risk_score * 0.01)
        has_preeclampsia = random.random() < (0.02 + risk_score * 0.008)
        has_placental_issues = random.random() < 0.015
        
        # Multiple gestation (twins)
        is_multiple = random.random() < 0.025  # ~2.5%
        
        pregnancies.append({
            'pregnancy_id': pregnancy_id,
            'patient_id': patient_id,
            'pregnancy_number': pregnancy_num,
            'lmp_date': lmp_date.strftime('%Y-%m-%d'),
            'edd': edd.strftime('%Y-%m-%d'),
            'delivery_date': delivery_date.strftime('%Y-%m-%d'),
            'maternal_age_at_delivery': maternal_age,
            'pre_pregnancy_bmi': pre_pregnancy_bmi,
            'gestational_weeks': gestational_weeks,
            'initial_risk_score': risk_score,
            'has_gestational_diabetes': has_gestational_diabetes,
            'has_preeclampsia': has_preeclampsia,
            'has_placental_issues': has_placental_issues,
            'is_multiple_gestation': is_multiple,
            'smoking_3rd_trimester': generate_smoking_status(delivery_date.year),
            'alcohol_during_pregnancy': random.random() < 0.03,
            'cannabis_use': random.random() < 0.011,  # 1.1% in 2021
            'covid_infection': random.random() < 0.057 if delivery_date.year >= 2020 else False
        })

pregnancies_df = pd.DataFrame(pregnancies)
print(f"Generated {len(pregnancies_df)} pregnancies")

# ============================================================================
# 3. GENERATE PRENATAL VISITS TABLE
# ============================================================================

print("\n3. Generating prenatal visits table...")

prenatal_visits = []
visit_counter = 1

for _, pregnancy in pregnancies_df.iterrows():
    pregnancy_id = pregnancy['pregnancy_id']
    lmp_date = datetime.strptime(pregnancy['lmp_date'], '%Y-%m-%d')
    delivery_date = datetime.strptime(pregnancy['delivery_date'], '%Y-%m-%d')
    
    # Number of prenatal visits (typically 7-10 for full-term)
    gestational_weeks = pregnancy['gestational_weeks']
    if gestational_weeks < 28:
        num_visits = random.randint(2, 4)
    elif gestational_weeks < 37:
        num_visits = random.randint(4, 7)
    else:
        num_visits = random.randint(7, 12)
    
    # Generate visit dates throughout pregnancy
    pregnancy_duration_days = (delivery_date - lmp_date).days
    
    for visit_num in range(1, num_visits + 1):
        visit_id = f"VISIT_{str(visit_counter).zfill(7)}"
        visit_counter += 1
        
        # Visit date (spread throughout pregnancy)
        visit_proportion = visit_num / (num_visits + 1)
        visit_days = int(pregnancy_duration_days * visit_proportion)
        visit_date = lmp_date + timedelta(days=visit_days)
        
        # Visit week
        visit_week = int((visit_date - lmp_date).days / 7)
        
        # Provider type (increasing midwife care over years)
        year = visit_date.year
        midwife_rate = 0.117 + (year - 2016) * 0.05  # From 11.7% in 2016 to 39% in 2021
        midwife_rate = min(midwife_rate, 0.40)
        provider_type = 'Midwife' if random.random() < midwife_rate else 'Obstetrician'
        
        # Vital signs (with some temporal progression)
        base_bp_systolic = random.randint(100, 130)
        base_bp_diastolic = random.randint(60, 85)
        
        # BP increases slightly in later pregnancy
        bp_increase = int(visit_week * 0.3)
        bp_systolic = base_bp_systolic + bp_increase + random.randint(-5, 5)
        bp_diastolic = base_bp_diastolic + int(bp_increase * 0.6) + random.randint(-3, 3)
        
        # Preeclampsia risk
        if pregnancy['has_preeclampsia'] and visit_week > 20:
            bp_systolic = max(bp_systolic, random.randint(140, 160))
            bp_diastolic = max(bp_diastolic, random.randint(90, 105))
        
        # Weight gain throughout pregnancy (typical: 11-16kg)
        pre_pregnancy_weight = (pregnancy['pre_pregnancy_bmi'] / (1.65 ** 2)) * (1.65 ** 2)  # Assuming avg height 1.65m
        expected_weight_gain = random.uniform(9, 18)
        weight_gain_so_far = (visit_week / 40) * expected_weight_gain
        current_weight = pre_pregnancy_weight + weight_gain_so_far + random.uniform(-2, 2)
        
        # Fundal height (cm, approximately equals weeks after 20 weeks)
        fundal_height = max(0, visit_week - random.randint(0, 3)) if visit_week > 12 else None
        
        # Fetal heart rate (120-160 bpm normal)
        fetal_heart_rate = random.randint(120, 160) if visit_week > 10 else None
        
        # Screenings
        down_syndrome_screening = (visit_week >= 11 and visit_week <= 14) and random.random() < 0.918
        glucose_tolerance_test = (visit_week >= 24 and visit_week <= 28)
        
        # Risk score at this visit (can change - for snapshots!)
        # Base risk from pregnancy + new factors
        visit_risk_score = pregnancy['initial_risk_score']
        
        if bp_systolic >= 140 or bp_diastolic >= 90:
            visit_risk_score += 2
        if pregnancy['has_gestational_diabetes'] and visit_week > 24:
            visit_risk_score += 2
        if visit_week < 37 and visit_num == num_visits:  # Last visit before preterm
            visit_risk_score += 3
        
        prenatal_visits.append({
            'visit_id': visit_id,
            'pregnancy_id': pregnancy_id,
            'visit_number': visit_num,
            'visit_date': visit_date.strftime('%Y-%m-%d'),
            'gestational_week': visit_week,
            'provider_type': provider_type,
            'bp_systolic': bp_systolic,
            'bp_diastolic': bp_diastolic,
            'weight_kg': round(current_weight, 1),
            'fundal_height_cm': fundal_height,
            'fetal_heart_rate': fetal_heart_rate,
            'protein_in_urine': (bp_systolic >= 140) and random.random() < 0.3,
            'glucose_screening_done': glucose_tolerance_test,
            'down_syndrome_screening_done': down_syndrome_screening,
            'ultrasound_done': visit_num in [1, 3, 5, 7],  # Some visits have ultrasound
            'risk_score_at_visit': visit_risk_score,
            'notes_length': random.randint(50, 500)  # For simulating text field
        })

prenatal_visits_df = pd.DataFrame(prenatal_visits)
print(f"Generated {len(prenatal_visits_df)} prenatal visits")

# ============================================================================
# 4. GENERATE DELIVERIES TABLE
# ============================================================================

print("\n4. Generating deliveries table...")

deliveries = []

for _, pregnancy in pregnancies_df.iterrows():
    pregnancy_id = pregnancy['pregnancy_id']
    delivery_date = datetime.strptime(pregnancy['delivery_date'], '%Y-%m-%d')
    
    delivery_id = f"DEL_{pregnancy_id.split('_')[1]}"
    
    # Facility type
    facility_type = random.choices(FACILITY_TYPES, weights=FACILITY_TYPE_WEIGHTS)[0]
    
    # Facility name (synthetic)
    facility_name = f"{fake.city()} {facility_type} Maternity"
    
    # Labor characteristics
    # Induction rates increasing over time (20.2% in 1995 to 25.8% in 2021)
    year = delivery_date.year
    induction_rate = 0.202 + (year - 1995) * 0.0021
    induction_rate = min(induction_rate, 0.26)
    
    labor_induced = random.random() < induction_rate
    spontaneous_labor = not labor_induced
    
    # Mode of delivery
    # Cesarean: 21.4% (stable)
    # Instrumental: 12.4%
    # Spontaneous vaginal: remaining
    delivery_mode_choice = random.random()
    if delivery_mode_choice < 0.214:
        delivery_mode = 'Cesarean'
        delivery_method = random.choice(['Emergency cesarean', 'Planned cesarean'])
    elif delivery_mode_choice < 0.214 + 0.124:
        delivery_mode = 'Instrumental vaginal'
        delivery_method = random.choice(['Forceps', 'Vacuum extraction'])
    else:
        delivery_mode = 'Spontaneous vaginal'
        delivery_method = 'Spontaneous'
    
    # Interventions during labor
    artificial_rupture_membranes = spontaneous_labor and random.random() < 0.332  # 33.2% in 2021
    oxytocin_augmentation = spontaneous_labor and random.random() < 0.25
    
    # Epidural (82.7% in 2021)
    epidural = random.random() < 0.827
    
    # Pain level
    if epidural:
        pain_level = random.choices(['None', 'Mild', 'Moderate', 'Severe'], 
                                   weights=[0.30, 0.35, 0.169, 0.314])[0]
    else:
        pain_level = random.choices(['Moderate', 'Severe'], weights=[0.3, 0.7])[0]
    
    # Episiotomy (decreasing trend)
    parity = pregnancy['pregnancy_number']
    if delivery_mode == 'Spontaneous vaginal':
        if parity == 1:  # Primiparous
            episiotomy = random.random() < 0.165  # 16.5% in 2021
        else:  # Multiparous
            episiotomy = random.random() < 0.029  # 2.9% in 2021
    else:
        episiotomy = False
    
    # Perineal tear (if no episiotomy)
    perineal_tear = (not episiotomy) and (delivery_mode == 'Spontaneous vaginal') and random.random() < 0.30
    perineal_tear_degree = random.choice([1, 2, 3, 4]) if perineal_tear else None
    
    # Blood loss
    blood_loss_ml = random.randint(200, 500) if delivery_mode != 'Cesarean' else random.randint(400, 800)
    if random.random() < 0.05:  # 5% postpartum hemorrhage
        blood_loss_ml = random.randint(1000, 2000)
    
    # Duration of labor (minutes)
    if delivery_mode == 'Cesarean':
        labor_duration_minutes = random.randint(30, 180) if labor_induced else 0
    else:
        if parity == 1:
            labor_duration_minutes = random.randint(240, 960)  # 4-16 hours
        else:
            labor_duration_minutes = random.randint(120, 480)  # 2-8 hours
    
    # Complications
    maternal_complications = []
    if blood_loss_ml > 1000:
        maternal_complications.append('Postpartum hemorrhage')
    if random.random() < 0.02:
        maternal_complications.append('Infection')
    if delivery_mode == 'Cesarean' and random.random() < 0.03:
        maternal_complications.append('Surgical complications')
    
    complications_text = ', '.join(maternal_complications) if maternal_complications else None
    
    deliveries.append({
        'delivery_id': delivery_id,
        'pregnancy_id': pregnancy_id,
        'delivery_date': delivery_date.strftime('%Y-%m-%d'),
        'delivery_time': f"{random.randint(0, 23):02d}:{random.randint(0, 59):02d}",
        'facility_type': facility_type,
        'facility_name': facility_name,
        'labor_induced': labor_induced,
        'spontaneous_labor': spontaneous_labor,
        'artificial_rupture_membranes': artificial_rupture_membranes,
        'oxytocin_augmentation': oxytocin_augmentation,
        'epidural': epidural,
        'pain_level': pain_level,
        'delivery_mode': delivery_mode,
        'delivery_method': delivery_method,
        'episiotomy': episiotomy,
        'perineal_tear': perineal_tear,
        'perineal_tear_degree': perineal_tear_degree,
        'labor_duration_minutes': labor_duration_minutes,
        'blood_loss_ml': blood_loss_ml,
        'maternal_complications': complications_text,
        'attending_obstetrician': fake.name(),
        'attending_midwife': fake.name() if random.random() < 0.6 else None
    })

deliveries_df = pd.DataFrame(deliveries)
print(f"Generated {len(deliveries_df)} deliveries")

# ============================================================================
# 5. GENERATE BIRTH OUTCOMES TABLE
# ============================================================================

print("\n5. Generating birth outcomes table...")

birth_outcomes = []
outcome_counter = 1

for _, pregnancy in pregnancies_df.iterrows():
    pregnancy_id = pregnancy['pregnancy_id']
    is_multiple = pregnancy['is_multiple_gestation']
    gestational_weeks = pregnancy['gestational_weeks']
    
    # Number of infants (1 or 2)
    num_infants = 2 if is_multiple else 1
    
    for infant_num in range(1, num_infants + 1):
        outcome_id = f"OUT_{str(outcome_counter).zfill(6)}"
        outcome_counter += 1
        
        delivery_id = f"DEL_{pregnancy_id.split('_')[1]}"
        
        # Birth weight (influenced by gestational age)
        # Mean: 3,264g at term
        if gestational_weeks >= 37:  # Term
            birth_weight = int(np.random.normal(3264, 450))
        elif gestational_weeks >= 32:  # Moderate preterm
            birth_weight = int(np.random.normal(2200, 400))
        else:  # Very preterm
            birth_weight = int(np.random.normal(1500, 350))
        
        # Adjust for multiples (typically smaller)
        if is_multiple:
            birth_weight = int(birth_weight * 0.85)
        
        # Ensure realistic bounds
        birth_weight = max(500, min(birth_weight, 5500))
        
        # Low birth weight
        low_birth_weight = birth_weight < 2500
        
        # Birth length (cm)
        birth_length = round(45 + (birth_weight - 2500) / 100, 1)
        birth_length = max(35, min(birth_length, 58))
        
        # Head circumference (cm)
        head_circumference = round(32 + (birth_weight - 2500) / 150, 1)
        head_circumference = max(28, min(head_circumference, 38))
        
        # Apgar scores (1 min and 5 min)
        # Most babies have good scores (7-10)
        if gestational_weeks >= 37 and birth_weight >= 2500:
            apgar_1min = random.choices([7, 8, 9, 10], weights=[0.05, 0.15, 0.35, 0.45])[0]
            apgar_5min = random.choices([8, 9, 10], weights=[0.10, 0.30, 0.60])[0]
        else:  # Preterm or low birth weight
            apgar_1min = random.choices([4, 5, 6, 7, 8, 9], weights=[0.05, 0.10, 0.15, 0.25, 0.25, 0.20])[0]
            apgar_5min = random.choices([6, 7, 8, 9, 10], weights=[0.05, 0.10, 0.25, 0.35, 0.25])[0]
        
        # Sex
        sex = random.choice(['Male', 'Female'])
        
        # Neonatal complications
        neonatal_complications = []
        
        if gestational_weeks < 37:
            if random.random() < 0.30:
                neonatal_complications.append('Respiratory distress')
        
        if low_birth_weight and random.random() < 0.20:
            neonatal_complications.append('Hypoglycemia')
        
        if apgar_5min < 7 and random.random() < 0.40:
            neonatal_complications.append('Birth asphyxia')
        
        if random.random() < 0.03:
            neonatal_complications.append('Jaundice requiring phototherapy')
        
        complications_text = ', '.join(neonatal_complications) if neonatal_complications else None
        
        # NICU admission
        nicu_admission = (gestational_weeks < 34) or (birth_weight < 1800) or (apgar_5min < 6) or \
                        (len(neonatal_complications) > 0 and random.random() < 0.50)
        
        nicu_days = random.randint(3, 30) if nicu_admission else 0
        
        # Breastfeeding initiation (in hospital)
        # 56.3% exclusive breastfeeding in 2021
        breastfeeding_status = random.choices(
            ['Exclusive', 'Mixed', 'Formula only'],
            weights=[0.563, 0.25, 0.187]
        )[0]
        
        birth_outcomes.append({
            'outcome_id': outcome_id,
            'delivery_id': delivery_id,
            'pregnancy_id': pregnancy_id,
            'infant_number': infant_num,
            'sex': sex,
            'birth_weight_grams': birth_weight,
            'birth_length_cm': birth_length,
            'head_circumference_cm': head_circumference,
            'apgar_1min': apgar_1min,
            'apgar_5min': apgar_5min,
            'gestational_age_weeks': gestational_weeks,
            'low_birth_weight': low_birth_weight,
            'preterm_birth': gestational_weeks < 37,
            'neonatal_complications': complications_text,
            'nicu_admission': nicu_admission,
            'nicu_days': nicu_days,
            'breastfeeding_initiation': breastfeeding_status
        })

birth_outcomes_df = pd.DataFrame(birth_outcomes)
print(f"Generated {len(birth_outcomes_df)} birth outcomes")

# ============================================================================
# 6. ADD DATA QUALITY ISSUES (for dbt testing)
# ============================================================================

print("\n6. Adding intentional data quality issues for dbt testing...")

# Add some NULL values
patients_df.loc[random.sample(range(len(patients_df)), 50), 'education_level'] = None
prenatal_visits_df.loc[random.sample(range(len(prenatal_visits_df)), 100), 'bp_systolic'] = None

# Add some duplicates in visits (for deduplication testing)
duplicate_visits = prenatal_visits_df.sample(n=20).copy()
prenatal_visits_df = pd.concat([prenatal_visits_df, duplicate_visits], ignore_index=True)

# Add date inconsistency (visit after delivery - should be caught by test)
bad_visits = prenatal_visits_df.sample(n=10).copy()
for idx in bad_visits.index:
    bad_date = datetime.strptime(prenatal_visits_df.loc[idx, 'visit_date'], '%Y-%m-%d') + timedelta(days=400)
    prenatal_visits_df.loc[idx, 'visit_date'] = bad_date.strftime('%Y-%m-%d')

print("Added data quality issues:")
print(f"  - {50} NULL education levels")
print(f"  - {100} NULL BP measurements")
print(f"  - {20} duplicate visit records")
print(f"  - {10} visits with impossible dates")

# ============================================================================
# 7. SAVE TO CSV FILES
# ============================================================================

print("\n7. Saving data to CSV files...")

output_dir = os.path.expanduser('~/maternal-health-analytics/data/raw')
os.makedirs(output_dir, exist_ok=True)

patients_df.to_csv(f'{output_dir}/patients.csv', index=False)
pregnancies_df.to_csv(f'{output_dir}/pregnancies.csv', index=False)
prenatal_visits_df.to_csv(f'{output_dir}/prenatal_visits.csv', index=False)
deliveries_df.to_csv(f'{output_dir}/deliveries.csv', index=False)
birth_outcomes_df.to_csv(f'{output_dir}/birth_outcomes.csv', index=False)

print(f"\nFiles saved to {output_dir}/")
print(f"  - patients.csv ({len(patients_df)} records)")
print(f"  - pregnancies.csv ({len(pregnancies_df)} records)")
print(f"  - prenatal_visits.csv ({len(prenatal_visits_df)} records)")
print(f"  - deliveries.csv ({len(deliveries_df)} records)")
print(f"  - birth_outcomes.csv ({len(birth_outcomes_df)} records)")

# ============================================================================
# 8. GENERATE SUMMARY STATISTICS
# ============================================================================

print("\n" + "="*80)
print("DATA GENERATION COMPLETE - SUMMARY STATISTICS")
print("="*80)

print("\n📊 DATASET OVERVIEW:")
print(f"  Total patients: {len(patients_df):,}")
print(f"  Total pregnancies: {len(pregnancies_df):,}")
print(f"  Total prenatal visits: {len(prenatal_visits_df):,}")
print(f"  Total deliveries: {len(deliveries_df):,}")
print(f"  Total birth outcomes: {len(birth_outcomes_df):,}")
print(f"  Date range: {START_DATE.date()} to {END_DATE.date()}")

print("\n KEY METRICS (matching ENP 2021):")
print(f"  Median maternal age: {pregnancies_df['maternal_age_at_delivery'].median():.1f} years")
print(f"  Mothers 35+: {(pregnancies_df['maternal_age_at_delivery'] >= 35).sum() / len(pregnancies_df) * 100:.1f}%")
print(f"  Obesity rate (BMI ≥30): {(pregnancies_df['pre_pregnancy_bmi'] >= 30).sum() / len(pregnancies_df) * 100:.1f}%")
print(f"  Cesarean rate: {(deliveries_df['delivery_mode'] == 'Cesarean').sum() / len(deliveries_df) * 100:.1f}%")
print(f"  Preterm births (<37w): {(pregnancies_df['gestational_weeks'] < 37).sum() / len(pregnancies_df) * 100:.1f}%")
print(f"  Epidural rate: {deliveries_df['epidural'].sum() / len(deliveries_df) * 100:.1f}%")
print(f"  Mean birth weight: {birth_outcomes_df['birth_weight_grams'].mean():.0f}g")

print("\n DATA QUALITY ISSUES (for dbt testing):")
print(f"  Patients with NULL education: {patients_df['education_level'].isna().sum()}")
print(f"  Visits with NULL BP: {prenatal_visits_df['bp_systolic'].isna().sum()}")
print(f"  Duplicate visit records: ~20")
print(f"  Invalid date sequences: ~10")

print("\n dbt FEATURES TO BE SHOWCASED:")
print("  ✓ Seeds (reference data)")
print("  ✓ Sources (raw data ingestion)")
print("  ✓ Staging models (data cleaning)")
print("  ✓ Incremental models (prenatal visits over time)")
print("  ✓ Snapshots (risk score changes - SCD Type 2)")
print("  ✓ Tests (NOT NULL, unique, relationships, custom)")
print("  ✓ Freshness monitoring")
print("  ✓ Macros (reusable logic)")
print("  ✓ Jinja templating")
print("  ✓ Documentation")
print("  ✓ Dimensional modeling (facts & dimensions)")
print("  ✓ PII handling (names, IDs to hash/mask)")
print("  ✓ Data quality checks")

print("\n" + "="*80)