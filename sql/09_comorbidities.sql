-- AKI Pipeline Stage 09: Build comorbidity flags.
-- Intended output table: `{project_id}.{dataset_id}.{comorbidities_table}`
-- Intended inputs:
--   - `{project_id}.{dataset_id}.{base_cohort_table}`
--   - `physionet-data.mimiciv_2_2_hosp.diagnoses_icd`
--
-- Assumption:
-- MIMIC diagnoses are hospital-level codes and may reflect discharge coding.
-- This MVP treats them as baseline context because a reliable pre-admission
-- problem list is not readily available in the same simple schema. Revisit this
-- if you need stricter baseline-only comorbidity definitions.

CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.{comorbidities_table}` AS
WITH diagnosis_rows AS (
    SELECT
        cohort.stay_id,
        dx.icd_version,
        UPPER(REPLACE(dx.icd_code, '.', '')) AS icd_code_clean
    FROM `{project_id}.{dataset_id}.{base_cohort_table}` AS cohort
    LEFT JOIN `physionet-data.mimiciv_2_2_hosp.diagnoses_icd` AS dx
        ON cohort.hadm_id = dx.hadm_id
),
aggregated AS (
    SELECT
        stay_id,
        MAX(
            CASE
                WHEN icd_version = 10
                 AND REGEXP_CONTAINS(icd_code_clean, r'^(N18|N19)') THEN 1
                WHEN icd_version = 9
                 AND REGEXP_CONTAINS(icd_code_clean, r'^(585|586)') THEN 1
                ELSE 0
            END
        ) AS ckd_flag,
        MAX(
            CASE
                WHEN icd_version = 10
                 AND REGEXP_CONTAINS(icd_code_clean, r'^E(0[89]|1[0-3])') THEN 1
                WHEN icd_version = 9
                 AND REGEXP_CONTAINS(icd_code_clean, r'^250') THEN 1
                ELSE 0
            END
        ) AS diabetes_flag,
        MAX(
            CASE
                WHEN icd_version = 10
                 AND REGEXP_CONTAINS(icd_code_clean, r'^I1[0-6]') THEN 1
                WHEN icd_version = 9
                 AND REGEXP_CONTAINS(icd_code_clean, r'^(401|402|403|404|405)') THEN 1
                ELSE 0
            END
        ) AS hypertension_flag,
        MAX(
            CASE
                WHEN icd_version = 10
                 AND REGEXP_CONTAINS(icd_code_clean, r'^I50') THEN 1
                WHEN icd_version = 9
                 AND REGEXP_CONTAINS(icd_code_clean, r'^428') THEN 1
                ELSE 0
            END
        ) AS chf_flag,
        MAX(
            CASE
                WHEN icd_version = 10
                 AND REGEXP_CONTAINS(icd_code_clean, r'^(K7[0-7]|B18|I85)') THEN 1
                WHEN icd_version = 9
                 AND REGEXP_CONTAINS(icd_code_clean, r'^(070|456|570|571|572)') THEN 1
                ELSE 0
            END
        ) AS liver_disease_flag,
        MAX(
            CASE
                WHEN icd_version = 10
                 AND REGEXP_CONTAINS(icd_code_clean, r'^(A40|A41|R652)') THEN 1
                WHEN icd_version = 9
                 AND REGEXP_CONTAINS(icd_code_clean, r'^(038|99591|99592|78552)') THEN 1
                ELSE 0
            END
        ) AS sepsis_infection_flag,
        MAX(
            CASE
                WHEN icd_version = 10
                 AND REGEXP_CONTAINS(icd_code_clean, r'^J4[0-7]') THEN 1
                WHEN icd_version = 9
                 AND REGEXP_CONTAINS(icd_code_clean, r'^(490|491|492|4932|494|495|496)') THEN 1
                ELSE 0
            END
        ) AS chronic_pulmonary_flag
    FROM diagnosis_rows
    GROUP BY stay_id
)
SELECT
    cohort.subject_id,
    cohort.hadm_id,
    cohort.stay_id,
    COALESCE(flags.ckd_flag, 0) AS ckd_flag,
    COALESCE(flags.diabetes_flag, 0) AS diabetes_flag,
    COALESCE(flags.hypertension_flag, 0) AS hypertension_flag,
    COALESCE(flags.chf_flag, 0) AS chf_flag,
    COALESCE(flags.liver_disease_flag, 0) AS liver_disease_flag,
    COALESCE(flags.sepsis_infection_flag, 0) AS sepsis_infection_flag,
    COALESCE(flags.chronic_pulmonary_flag, 0) AS chronic_pulmonary_flag
FROM `{project_id}.{dataset_id}.{base_cohort_table}` AS cohort
LEFT JOIN aggregated AS flags
    ON cohort.stay_id = flags.stay_id;
