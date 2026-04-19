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
        detail.subject_id,
        detail.hadm_id,
        detail.stay_id,
        detail.icu_intime,
        detail.icu_outtime,
        adm.admittime,
        adm.dischtime,
        detail.admission_age,
        pat.gender,
        adm.race,
        adm.admission_type,
        adm.admission_location,
        adm.insurance,
        adm.language,
        adm.marital_status,
        adm.hospital_expire_flag,
        detail.los_icu,
        ROUND(CAST(DATETIME_DIFF(adm.dischtime, adm.admittime, HOUR) / 24.0 AS NUMERIC), 2) AS los_hospital,
        detail.first_icu_stay,
        detail.first_hosp_stay,
        ROW_NUMBER() OVER (
            PARTITION BY detail.subject_id
            ORDER BY detail.icu_intime, detail.stay_id
        ) AS patient_icu_stay_seq,
        DATETIME_DIFF(detail.icu_outtime, detail.icu_intime, HOUR) AS icu_los_hours
    FROM `physionet-data.mimiciv_2_2_derived.icustay_detail` AS detail
    INNER JOIN `physionet-data.mimiciv_2_2_hosp.admissions` AS adm
        ON detail.hadm_id = adm.hadm_id
    INNER JOIN `physionet-data.mimiciv_2_2_hosp.patients` AS pat
        ON detail.subject_id = pat.subject_id
    WHERE detail.icu_intime IS NOT NULL
      AND detail.icu_outtime IS NOT NULL
      AND adm.admittime IS NOT NULL
      AND adm.dischtime IS NOT NULL
      -- Adult patients only.
      AND detail.admission_age >= 18
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
