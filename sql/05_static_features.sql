-- AKI Pipeline Stage 05: Build baseline/static features.
-- Intended output table: `{project_id}.{dataset_id}.{static_features_table}`
-- Intended inputs:
--   - `{project_id}.{dataset_id}.{base_cohort_table}`
--   - `{project_id}.{dataset_id}.{prediction_anchors_table}`
--
-- Only baseline-safe administrative and demographic fields are included here.
-- Full-stay summaries such as ICU LOS are intentionally excluded from features.

CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.{static_features_table}` AS
SELECT
    cohort.subject_id,
    cohort.hadm_id,
    cohort.stay_id,
    cohort.admission_age,
    cohort.gender,
    cohort.race,
    cohort.admission_type,
    cohort.admission_location,
    cohort.insurance,
    cohort.language,
    cohort.marital_status,
    cohort.first_icu_stay,
    cohort.first_hosp_stay
FROM `{project_id}.{dataset_id}.{base_cohort_table}` AS cohort
INNER JOIN `{project_id}.{dataset_id}.{prediction_anchors_table}` AS anchors
    ON cohort.stay_id = anchors.stay_id
WHERE anchors.eligible_for_prediction = 1;
