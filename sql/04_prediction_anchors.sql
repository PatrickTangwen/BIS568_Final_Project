-- AKI Pipeline Stage 04: Define leakage-safe prediction anchors.
-- Intended output table: `{project_id}.{dataset_id}.{prediction_anchors_table}`
-- Intended inputs:
--   - `{project_id}.{dataset_id}.{base_cohort_table}`
--   - `{project_id}.{dataset_id}.{aki_onset_table}`
--
-- Temporal contract for all downstream feature queries:
-- every observation-window event must satisfy `event_time <= anchor_time`.

CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.{prediction_anchors_table}` AS
WITH anchor_windows AS (
    SELECT
        cohort.stay_id,
        cohort.subject_id,
        cohort.hadm_id,
        cohort.icu_intime,
        cohort.icu_outtime,
        cohort.dischtime,
        cohort.icu_intime AS obs_window_start,
        DATETIME_ADD(cohort.icu_intime, INTERVAL 6 HOUR) AS obs_window_end
    FROM `{project_id}.{dataset_id}.{base_cohort_table}` AS cohort
),
labeled_windows AS (
    SELECT
        win.stay_id,
        win.subject_id,
        win.hadm_id,
        win.icu_intime,
        win.obs_window_start,
        win.obs_window_end,
        win.obs_window_end AS anchor_time,
        win.obs_window_end AS pred_window_start,
        DATETIME_ADD(win.obs_window_end, INTERVAL 24 HOUR) AS pred_window_end,
        onset.aki_onset_time
    FROM anchor_windows AS win
    LEFT JOIN `{project_id}.{dataset_id}.{aki_onset_table}` AS onset
        ON win.stay_id = onset.stay_id
)
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
    CASE
        WHEN aki_onset_time IS NOT NULL AND aki_onset_time <= anchor_time THEN 0
        ELSE 1
    END AS eligible_for_prediction,
    CASE
        WHEN aki_onset_time IS NOT NULL AND aki_onset_time <= anchor_time THEN NULL
        WHEN aki_onset_time > pred_window_start
         AND aki_onset_time <= pred_window_end THEN 1
        ELSE 0
    END AS future_aki_24h
FROM labeled_windows;
