# Connect to Bigquery
from google.colab import auth
from google.cloud import bigquery
from google.colab import userdata
import pandas as pd
import io

# Authenticate your Google account
auth.authenticate_user()

# Set your project ID and create the BigQuery client
# Note: Ensure 'project_id' is set in your Colab secrets or replace with string directly
project_id = userdata.get('project_id') 
dataset_id = 'BIS_638_Final_Project'
disease_table = 'pneumonia'

client = bigquery.Client(project=project_id)

def query_bigquery(sql_query: str) -> pd.DataFrame:
  """Runs BigQuery SQL and returns a pandas DataFrame."""
  print("Running query...")
  try:
      query_job = client.query(sql_query)
      df = query_job.to_dataframe()
      print(f"Query successful! Retrieved {len(df)} rows.")
      return df
  except Exception as e:
      print(f"Error running query: {e}")
      return pd.DataFrame()

# Constructing the SQL Query
# We use f-strings to dynamically insert your specific project and dataset variables
# We select * to grab all columns, though in production you might want to specify columns to avoid duplicates (e.g., subject_id appears in every table)

sql_query = f"""
SELECT 
    -- Select all columns from the joined tables
    t.Group_Name,
    t.Term,
    t.DOID,
    t.ICD10Code,
    icu.*,
    adm.admittime, adm.dischtime, adm.deathtime, adm.admission_type, adm.admission_location,adm.insurance, adm.language, adm.marital_status, adm.race,
    pat.gender, pat.anchor_age, pat.anchor_year, pat.dod,
    
    -- Derived Data (First Day Vitals, Labs, etc.)
    fd_lab.* EXCEPT (subject_id, stay_id),
    fd_vital.* EXCEPT (subject_id, stay_id),
    fd_bg.* EXCEPT (subject_id, stay_id),
    inf.* EXCEPT (subject_id, hadm_id),
    fd_urine.* EXCEPT (subject_id, stay_id),
    fd_height.* EXCEPT (subject_id, stay_id),
    fd_weight.* EXCEPT (subject_id, stay_id)

FROM `physionet-data.mimiciv_2_2_hosp.diagnoses_icd` AS d

-- 1. JOIN to your Custom Pneumonia Identifier Table (Filter Cohort)
INNER JOIN `{project_id}.{dataset_id}.{disease_table}` AS t
  ON UPPER(REPLACE(d.icd_code, '.', '')) = UPPER(REPLACE(t.ICD10Code, '.', ''))

-- 2. JOIN to ICU Stay Details (The backbone for ICU data)
INNER JOIN `physionet-data.mimiciv_2_2_derived.icustay_detail` AS icu
  ON d.hadm_id = icu.hadm_id

-- 3. JOIN to Core Hospital Tables (Admissions and Patients)
INNER JOIN `physionet-data.mimiciv_2_2_hosp.admissions` AS adm
  ON icu.hadm_id = adm.hadm_id
INNER JOIN `physionet-data.mimiciv_2_2_hosp.patients` AS pat
  ON icu.subject_id = pat.subject_id

-- 4. LEFT JOIN to Derived Clinical Tables
-- We use LEFT JOIN so we don't lose patients who might be missing specific lab/vital values
LEFT JOIN `physionet-data.mimiciv_2_2_derived.first_day_lab` AS fd_lab
  ON icu.stay_id = fd_lab.stay_id

LEFT JOIN `physionet-data.mimiciv_2_2_derived.first_day_vitalsign` AS fd_vital
  ON icu.stay_id = fd_vital.stay_id

LEFT JOIN `physionet-data.mimiciv_2_2_derived.first_day_bg` AS fd_bg
  ON icu.stay_id = fd_bg.stay_id

LEFT JOIN `physionet-data.mimiciv_2_2_derived.inflammation` AS inf
  ON icu.hadm_id = inf.hadm_id

LEFT JOIN `physionet-data.mimiciv_2_2_derived.first_day_urine_output` AS fd_urine
  ON icu.stay_id = fd_urine.stay_id

LEFT JOIN `physionet-data.mimiciv_2_2_derived.first_day_height` AS fd_height
  ON icu.stay_id = fd_height.stay_id

LEFT JOIN `physionet-data.mimiciv_2_2_derived.first_day_weight` AS fd_weight
  ON icu.stay_id = fd_weight.stay_id

-- Optional: Order by subject and time
ORDER BY icu.subject_id, icu.admittime
"""

# Execute the query
df_pneumonia = query_bigquery(sql_query)

# Display first few rows to verify
print(df_pneumonia.head())

# Export to CSV
csv_filename = 'mimic_pneumonia_cohort_full.csv'
df_pneumonia.to_csv(csv_filename, index=False)
print(f"Data exported successfully to {csv_filename}")