-- AKI Pipeline Stage 02: Build a time-resolved KDIGO stage series.
-- Intended output table: `{project_id}.{dataset_id}.{kdigo_stages_table}`
-- Intended inputs:
--   - `{project_id}.{dataset_id}.{base_cohort_table}`
--   - `physionet-data.mimiciv_2_2_derived.kdigo_stages`
--
-- This draft intentionally leans on the official MIMIC derived KDIGO concept
-- so the creatinine / urine-output / CRRT logic stays close to the reference
-- implementation. If your BigQuery project exposes a different MIMIC version,
-- update the source dataset path below before running in Colab.

CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.{kdigo_stages_table}` AS
WITH kdigo_reference AS (
    SELECT
        stay_id,
        charttime,
        aki_stage,
        aki_stage_smoothed,
        aki_stage_creat,
        aki_stage_uo,
        aki_stage_crrt
    FROM `physionet-data.mimiciv_2_2_derived.kdigo_stages`
),
cohort_filtered AS (
    SELECT
        kdigo.stay_id,
        kdigo.charttime,
        kdigo.aki_stage,
        kdigo.aki_stage_smoothed,
        kdigo.aki_stage_creat,
        kdigo.aki_stage_uo,
        kdigo.aki_stage_crrt
    FROM kdigo_reference AS kdigo
    INNER JOIN `{project_id}.{dataset_id}.{base_cohort_table}` AS cohort
        ON kdigo.stay_id = cohort.stay_id
    WHERE kdigo.charttime IS NOT NULL
)
SELECT
    stay_id,
    charttime,
    aki_stage,
    aki_stage_smoothed,
    aki_stage_creat,
    aki_stage_uo,
    aki_stage_crrt
FROM cohort_filtered;
