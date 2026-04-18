-- AKI Pipeline Stage 03: Collapse KDIGO stage rows into one onset record per stay.
-- Intended output table: `{project_id}.{dataset_id}.{aki_onset_table}`
-- Intended inputs:
--   - `{project_id}.{dataset_id}.{base_cohort_table}`
--   - `{project_id}.{dataset_id}.{kdigo_stages_table}`

CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.{aki_onset_table}` AS
WITH positive_stage_events AS (
    SELECT
        stay_id,
        charttime,
        aki_stage_smoothed
    FROM `{project_id}.{dataset_id}.{kdigo_stages_table}`
    WHERE aki_stage_smoothed >= 1
),
onset_by_stay AS (
    SELECT
        stay_id,
        ARRAY_AGG(
            STRUCT(charttime, aki_stage_smoothed)
            ORDER BY charttime, aki_stage_smoothed DESC
            LIMIT 1
        )[SAFE_OFFSET(0)] AS first_positive_stage,
        MAX(aki_stage_smoothed) AS aki_stage_max
    FROM positive_stage_events
    GROUP BY stay_id
)
SELECT
    cohort.stay_id,
    onset.first_positive_stage.charttime AS aki_onset_time,
    onset.first_positive_stage.aki_stage_smoothed AS aki_onset_stage,
    onset.aki_stage_max,
    CASE
        WHEN onset.first_positive_stage.charttime IS NULL THEN 0
        ELSE 1
    END AS has_aki_anytime
FROM `{project_id}.{dataset_id}.{base_cohort_table}` AS cohort
LEFT JOIN onset_by_stay AS onset
    ON cohort.stay_id = onset.stay_id;
