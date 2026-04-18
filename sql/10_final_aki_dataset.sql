-- AKI Pipeline Stage 10: Assemble the final AKI modeling dataset.
-- Intended output table: `{project_id}.{dataset_id}.{final_dataset_table}`
-- Intended inputs:
--   - `{project_id}.{dataset_id}.{base_cohort_table}`
--   - `{project_id}.{dataset_id}.{prediction_anchors_table}`
--   - `{project_id}.{dataset_id}.{static_features_table}`
--   - `{project_id}.{dataset_id}.{labs_features_table}`
--   - `{project_id}.{dataset_id}.{vitals_features_table}`
--   - `{project_id}.{dataset_id}.{urine_features_table}`
--   - `{project_id}.{dataset_id}.{comorbidities_table}`
--
-- Debug-only columns should stay out of this exported table unless you need
-- them for troubleshooting after the first Colab run.

CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.{final_dataset_table}` AS
WITH eligible_anchors AS (
    SELECT
        stay_id,
        subject_id,
        hadm_id,
        icu_intime,
        anchor_time,
        obs_window_start,
        obs_window_end,
        pred_window_start,
        pred_window_end,
        future_aki_24h
    FROM `{project_id}.{dataset_id}.{prediction_anchors_table}`
    WHERE eligible_for_prediction = 1
),
joined AS (
    SELECT
        anchors.subject_id,
        anchors.hadm_id,
        anchors.stay_id,
        anchors.icu_intime,
        anchors.anchor_time,
        anchors.obs_window_start,
        anchors.obs_window_end,
        anchors.pred_window_start,
        anchors.pred_window_end,
        anchors.future_aki_24h,
        static.admission_age,
        static.gender,
        static.race,
        static.admission_type,
        static.admission_location,
        static.insurance,
        static.language,
        static.marital_status,
        static.first_icu_stay,
        static.first_hosp_stay,
        comorb.ckd_flag,
        comorb.diabetes_flag,
        comorb.hypertension_flag,
        comorb.chf_flag,
        comorb.liver_disease_flag,
        comorb.sepsis_infection_flag,
        comorb.chronic_pulmonary_flag,
        labs.* EXCEPT (stay_id),
        vitals.* EXCEPT (stay_id),
        urine.* EXCEPT (stay_id)
    FROM eligible_anchors AS anchors
    LEFT JOIN `{project_id}.{dataset_id}.{static_features_table}` AS static
        ON anchors.stay_id = static.stay_id
    LEFT JOIN `{project_id}.{dataset_id}.{comorbidities_table}` AS comorb
        ON anchors.stay_id = comorb.stay_id
    LEFT JOIN `{project_id}.{dataset_id}.{labs_features_table}` AS labs
        ON anchors.stay_id = labs.stay_id
    LEFT JOIN `{project_id}.{dataset_id}.{vitals_features_table}` AS vitals
        ON anchors.stay_id = vitals.stay_id
    LEFT JOIN `{project_id}.{dataset_id}.{urine_features_table}` AS urine
        ON anchors.stay_id = urine.stay_id
)
SELECT *
FROM joined
QUALIFY ROW_NUMBER() OVER (PARTITION BY stay_id ORDER BY stay_id) = 1;
