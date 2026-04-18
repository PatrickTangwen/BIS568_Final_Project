-- AKI Pipeline Stage 01: Build the adult ICU base cohort.
-- Intended output table: `{project_id}.{dataset_id}.{base_cohort_table}`
-- Likely source tables:
--   - `physionet-data.mimiciv_2_2_derived.icustay_detail`
--   - `physionet-data.mimiciv_2_2_icu.icustays`
--   - `physionet-data.mimiciv_2_2_hosp.admissions`
--   - `physionet-data.mimiciv_2_2_hosp.patients`
--
-- This query is designed to be run from Google Colab / BigQuery.
-- It keeps one eligible ICU stay per patient for the MVP AKI prediction cohort.

CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.{base_cohort_table}` AS
WITH cohort_candidates AS (
    SELECT
        icu.subject_id,
        icu.hadm_id,
        icu.stay_id,
        icu.icu_intime,
        icu.icu_outtime,
        icu.admittime,
        icu.dischtime,
        icu.admission_age,
        icu.gender,
        icu.race,
        icu.admission_type,
        icu.admission_location,
        icu.insurance,
        icu.language,
        icu.marital_status,
        icu.hospital_expire_flag,
        icu.los_icu,
        icu.los_hospital,
        icu.first_icu_stay,
        icu.first_hosp_stay,
        ROW_NUMBER() OVER (
            PARTITION BY icu.subject_id
            ORDER BY icu.icu_intime, icu.stay_id
        ) AS patient_icu_stay_seq,
        DATETIME_DIFF(icu.icu_outtime, icu.icu_intime, HOUR) AS icu_los_hours
    FROM `physionet-data.mimiciv_2_2_derived.icustay_detail` AS icu
    WHERE icu.icu_intime IS NOT NULL
      AND icu.icu_outtime IS NOT NULL
      AND icu.admittime IS NOT NULL
      AND icu.dischtime IS NOT NULL
      -- Adult patients only.
      AND icu.admission_age >= 18
),
eligible_stays AS (
    SELECT
        subject_id,
        hadm_id,
        stay_id,
        icu_intime,
        icu_outtime,
        admittime,
        dischtime,
        admission_age,
        gender,
        race,
        admission_type,
        admission_location,
        insurance,
        language,
        marital_status,
        hospital_expire_flag,
        los_icu,
        los_hospital,
        first_icu_stay,
        first_hosp_stay
    FROM cohort_candidates
    WHERE patient_icu_stay_seq = 1
      -- Require enough ICU time for a 6h observation window plus a 24h prediction horizon.
      AND icu_los_hours >= 30
)
SELECT
    subject_id,
    hadm_id,
    stay_id,
    icu_intime,
    icu_outtime,
    admittime,
    dischtime,
    admission_age,
    gender,
    race,
    admission_type,
    admission_location,
    insurance,
    language,
    marital_status,
    hospital_expire_flag,
    los_icu,
    los_hospital,
    first_icu_stay,
    first_hosp_stay
FROM eligible_stays;
