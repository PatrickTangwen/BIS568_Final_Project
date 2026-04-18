-- AKI Pipeline Stage 99: Debug and sanity-check queries.
-- Intended output table: none; run each section manually in BigQuery / Colab.
-- Intended inputs:
--   - `{project_id}.{dataset_id}.{base_cohort_table}`
--   - `{project_id}.{dataset_id}.{prediction_anchors_table}`
--   - `{project_id}.{dataset_id}.{kdigo_stages_table}`
--   - `{project_id}.{dataset_id}.{aki_onset_table}`
--   - `{project_id}.{dataset_id}.{final_dataset_table}`

-- Section 1: Base cohort size and uniqueness.
-- Catch accidental duplicate stay rows or overly aggressive cohort filters.
SELECT
    COUNT(*) AS base_rows,
    COUNT(DISTINCT subject_id) AS unique_subject_id,
    COUNT(DISTINCT hadm_id) AS unique_hadm_id,
    COUNT(DISTINCT stay_id) AS unique_stay_id
FROM `{project_id}.{dataset_id}.{base_cohort_table}`;

-- Section 2: First-ICU-stay restriction effect.
-- Confirm the MVP cohort still reports itself as first ICU stay.
SELECT
    first_icu_stay,
    first_hosp_stay,
    COUNT(*) AS n_stays
FROM `{project_id}.{dataset_id}.{base_cohort_table}`
GROUP BY first_icu_stay, first_hosp_stay
ORDER BY first_icu_stay DESC, first_hosp_stay DESC;

-- Section 3: KDIGO stage coverage.
-- Check whether the stage time series is populated after filtering to the cohort.
SELECT
    COUNT(*) AS kdigo_rows,
    COUNT(DISTINCT stay_id) AS kdigo_stays,
    MIN(charttime) AS first_charttime,
    MAX(charttime) AS last_charttime
FROM `{project_id}.{dataset_id}.{kdigo_stages_table}`;

-- Section 4: AKI onset prevalence.
-- Review how many stays ever become AKI-positive at any time in the stay.
SELECT
    has_aki_anytime,
    COUNT(*) AS n_stays
FROM `{project_id}.{dataset_id}.{aki_onset_table}`
GROUP BY has_aki_anytime
ORDER BY has_aki_anytime DESC;

-- Section 5: Prediction-anchor eligibility and label prevalence.
-- Check how many stays are excluded before the anchor and the final positive rate.
SELECT
    eligible_for_prediction,
    future_aki_24h,
    COUNT(*) AS n_stays
FROM `{project_id}.{dataset_id}.{prediction_anchors_table}`
GROUP BY eligible_for_prediction, future_aki_24h
ORDER BY eligible_for_prediction DESC, future_aki_24h DESC;

-- Section 6: Timing rule audit.
-- Catch impossible windows or labels that violate the anchor boundary.
SELECT
    COUNTIF(anchor_time != obs_window_end) AS anchor_mismatch_rows,
    COUNTIF(pred_window_start != anchor_time) AS pred_start_mismatch_rows,
    COUNTIF(pred_window_end <= pred_window_start) AS bad_prediction_windows,
    COUNTIF(eligible_for_prediction = 0 AND future_aki_24h IS NOT NULL) AS ineligible_with_label
FROM `{project_id}.{dataset_id}.{prediction_anchors_table}`;

-- Section 7: Final table duplicate stay check.
-- The final exported modeling table should have exactly one row per stay_id.
SELECT
    COUNT(*) AS final_rows,
    COUNT(DISTINCT stay_id) AS final_unique_stays,
    COUNT(*) - COUNT(DISTINCT stay_id) AS duplicate_rows
FROM `{project_id}.{dataset_id}.{final_dataset_table}`;

-- Section 8: Simple non-null coverage for major feature groups.
-- Gives a fast sense of whether feature joins succeeded.
SELECT
    COUNT(*) AS final_rows,
    COUNTIF(admission_age IS NOT NULL) AS static_rows,
    COUNTIF(creatinine_last_6h IS NOT NULL) AS lab_rows,
    COUNTIF(heart_rate_mean_6h IS NOT NULL) AS vital_rows,
    COUNTIF(urine_total_6h IS NOT NULL) AS urine_rows,
    COUNTIF(ckd_flag IS NOT NULL) AS comorbidity_rows
FROM `{project_id}.{dataset_id}.{final_dataset_table}`;

-- Section 9: Sample positive rows for manual inspection.
SELECT
    stay_id,
    subject_id,
    hadm_id,
    anchor_time,
    future_aki_24h,
    creatinine_last_6h,
    urine_total_6h,
    heart_rate_mean_6h
FROM `{project_id}.{dataset_id}.{final_dataset_table}`
WHERE future_aki_24h = 1
LIMIT 20;

-- Section 10: Sample negative rows for manual inspection.
SELECT
    stay_id,
    subject_id,
    hadm_id,
    anchor_time,
    future_aki_24h,
    creatinine_last_6h,
    urine_total_6h,
    heart_rate_mean_6h
FROM `{project_id}.{dataset_id}.{final_dataset_table}`
WHERE future_aki_24h = 0
LIMIT 20;
