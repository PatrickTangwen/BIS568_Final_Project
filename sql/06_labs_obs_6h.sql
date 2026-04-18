-- AKI Pipeline Stage 06: Aggregate lab features from the observation window.
-- Intended output table: `{project_id}.{dataset_id}.{labs_features_table}`
-- Intended inputs:
--   - `{project_id}.{dataset_id}.{prediction_anchors_table}`
--   - `physionet-data.mimiciv_2_2_hosp.labevents`
--
-- Leakage guard:
-- every included lab event must satisfy
--   charttime >= icu_intime
--   charttime <= anchor_time
-- We do not use first-day summary tables here because their timing can extend
-- beyond the 6-hour observation window.

CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.{labs_features_table}` AS
WITH eligible_anchors AS (
    SELECT
        stay_id,
        hadm_id,
        icu_intime,
        anchor_time
    FROM `{project_id}.{dataset_id}.{prediction_anchors_table}`
    WHERE eligible_for_prediction = 1
),
lab_item_map AS (
    SELECT 50912 AS itemid, 'creatinine' AS lab_name UNION ALL
    SELECT 51006 AS itemid, 'bun' AS lab_name UNION ALL
    SELECT 50882 AS itemid, 'bicarbonate' AS lab_name UNION ALL
    SELECT 50971 AS itemid, 'potassium' AS lab_name UNION ALL
    SELECT 50983 AS itemid, 'sodium' AS lab_name UNION ALL
    SELECT 50902 AS itemid, 'chloride' AS lab_name UNION ALL
    SELECT 50893 AS itemid, 'calcium' AS lab_name UNION ALL
    SELECT 50931 AS itemid, 'glucose' AS lab_name UNION ALL
    SELECT 50809 AS itemid, 'glucose' AS lab_name UNION ALL
    SELECT 50813 AS itemid, 'lactate' AS lab_name UNION ALL
    SELECT 51222 AS itemid, 'hemoglobin' AS lab_name UNION ALL
    SELECT 51221 AS itemid, 'hematocrit' AS lab_name UNION ALL
    SELECT 51265 AS itemid, 'platelets' AS lab_name UNION ALL
    SELECT 51300 AS itemid, 'wbc' AS lab_name
),
filtered_labs AS (
    SELECT
        anchors.stay_id,
        map.lab_name,
        le.charttime,
        CAST(le.valuenum AS FLOAT64) AS lab_value
    FROM eligible_anchors AS anchors
    INNER JOIN `physionet-data.mimiciv_2_2_hosp.labevents` AS le
        ON anchors.hadm_id = le.hadm_id
    INNER JOIN lab_item_map AS map
        ON le.itemid = map.itemid
    WHERE le.valuenum IS NOT NULL
      AND le.charttime >= anchors.icu_intime
      AND le.charttime <= anchors.anchor_time
),
lab_summary AS (
    SELECT
        stay_id,
        lab_name,
        ARRAY_AGG(lab_value ORDER BY charttime ASC LIMIT 1)[SAFE_OFFSET(0)] AS first_value,
        ARRAY_AGG(lab_value ORDER BY charttime DESC LIMIT 1)[SAFE_OFFSET(0)] AS last_value,
        MIN(lab_value) AS min_value,
        MAX(lab_value) AS max_value,
        AVG(lab_value) AS mean_value,
        COUNT(*) AS count_value
    FROM filtered_labs
    GROUP BY stay_id, lab_name
)
SELECT
    anchors.stay_id,
    MAX(IF(lab_name = 'creatinine', first_value, NULL)) AS creatinine_first_6h,
    MAX(IF(lab_name = 'creatinine', last_value, NULL)) AS creatinine_last_6h,
    MAX(IF(lab_name = 'creatinine', min_value, NULL)) AS creatinine_min_6h,
    MAX(IF(lab_name = 'creatinine', max_value, NULL)) AS creatinine_max_6h,
    MAX(IF(lab_name = 'creatinine', mean_value, NULL)) AS creatinine_mean_6h,
    MAX(IF(lab_name = 'creatinine', count_value, NULL)) AS creatinine_count_6h,
    MAX(IF(lab_name = 'creatinine', last_value - first_value, NULL)) AS creatinine_delta_6h,
    MAX(IF(lab_name = 'bun', first_value, NULL)) AS bun_first_6h,
    MAX(IF(lab_name = 'bun', last_value, NULL)) AS bun_last_6h,
    MAX(IF(lab_name = 'bun', min_value, NULL)) AS bun_min_6h,
    MAX(IF(lab_name = 'bun', max_value, NULL)) AS bun_max_6h,
    MAX(IF(lab_name = 'bun', mean_value, NULL)) AS bun_mean_6h,
    MAX(IF(lab_name = 'bun', count_value, NULL)) AS bun_count_6h,
    MAX(IF(lab_name = 'bun', last_value - first_value, NULL)) AS bun_delta_6h,
    MAX(IF(lab_name = 'bicarbonate', first_value, NULL)) AS bicarbonate_first_6h,
    MAX(IF(lab_name = 'bicarbonate', last_value, NULL)) AS bicarbonate_last_6h,
    MAX(IF(lab_name = 'bicarbonate', min_value, NULL)) AS bicarbonate_min_6h,
    MAX(IF(lab_name = 'bicarbonate', max_value, NULL)) AS bicarbonate_max_6h,
    MAX(IF(lab_name = 'bicarbonate', mean_value, NULL)) AS bicarbonate_mean_6h,
    MAX(IF(lab_name = 'bicarbonate', count_value, NULL)) AS bicarbonate_count_6h,
    MAX(IF(lab_name = 'bicarbonate', last_value - first_value, NULL)) AS bicarbonate_delta_6h,
    MAX(IF(lab_name = 'potassium', first_value, NULL)) AS potassium_first_6h,
    MAX(IF(lab_name = 'potassium', last_value, NULL)) AS potassium_last_6h,
    MAX(IF(lab_name = 'potassium', min_value, NULL)) AS potassium_min_6h,
    MAX(IF(lab_name = 'potassium', max_value, NULL)) AS potassium_max_6h,
    MAX(IF(lab_name = 'potassium', mean_value, NULL)) AS potassium_mean_6h,
    MAX(IF(lab_name = 'potassium', count_value, NULL)) AS potassium_count_6h,
    MAX(IF(lab_name = 'potassium', last_value - first_value, NULL)) AS potassium_delta_6h,
    MAX(IF(lab_name = 'sodium', first_value, NULL)) AS sodium_first_6h,
    MAX(IF(lab_name = 'sodium', last_value, NULL)) AS sodium_last_6h,
    MAX(IF(lab_name = 'sodium', min_value, NULL)) AS sodium_min_6h,
    MAX(IF(lab_name = 'sodium', max_value, NULL)) AS sodium_max_6h,
    MAX(IF(lab_name = 'sodium', mean_value, NULL)) AS sodium_mean_6h,
    MAX(IF(lab_name = 'sodium', count_value, NULL)) AS sodium_count_6h,
    MAX(IF(lab_name = 'sodium', last_value - first_value, NULL)) AS sodium_delta_6h,
    MAX(IF(lab_name = 'chloride', first_value, NULL)) AS chloride_first_6h,
    MAX(IF(lab_name = 'chloride', last_value, NULL)) AS chloride_last_6h,
    MAX(IF(lab_name = 'chloride', min_value, NULL)) AS chloride_min_6h,
    MAX(IF(lab_name = 'chloride', max_value, NULL)) AS chloride_max_6h,
    MAX(IF(lab_name = 'chloride', mean_value, NULL)) AS chloride_mean_6h,
    MAX(IF(lab_name = 'chloride', count_value, NULL)) AS chloride_count_6h,
    MAX(IF(lab_name = 'chloride', last_value - first_value, NULL)) AS chloride_delta_6h,
    MAX(IF(lab_name = 'calcium', first_value, NULL)) AS calcium_first_6h,
    MAX(IF(lab_name = 'calcium', last_value, NULL)) AS calcium_last_6h,
    MAX(IF(lab_name = 'calcium', min_value, NULL)) AS calcium_min_6h,
    MAX(IF(lab_name = 'calcium', max_value, NULL)) AS calcium_max_6h,
    MAX(IF(lab_name = 'calcium', mean_value, NULL)) AS calcium_mean_6h,
    MAX(IF(lab_name = 'calcium', count_value, NULL)) AS calcium_count_6h,
    MAX(IF(lab_name = 'calcium', last_value - first_value, NULL)) AS calcium_delta_6h,
    MAX(IF(lab_name = 'glucose', first_value, NULL)) AS glucose_first_6h,
    MAX(IF(lab_name = 'glucose', last_value, NULL)) AS glucose_last_6h,
    MAX(IF(lab_name = 'glucose', min_value, NULL)) AS glucose_min_6h,
    MAX(IF(lab_name = 'glucose', max_value, NULL)) AS glucose_max_6h,
    MAX(IF(lab_name = 'glucose', mean_value, NULL)) AS glucose_mean_6h,
    MAX(IF(lab_name = 'glucose', count_value, NULL)) AS glucose_count_6h,
    MAX(IF(lab_name = 'glucose', last_value - first_value, NULL)) AS glucose_delta_6h,
    MAX(IF(lab_name = 'lactate', first_value, NULL)) AS lactate_first_6h,
    MAX(IF(lab_name = 'lactate', last_value, NULL)) AS lactate_last_6h,
    MAX(IF(lab_name = 'lactate', min_value, NULL)) AS lactate_min_6h,
    MAX(IF(lab_name = 'lactate', max_value, NULL)) AS lactate_max_6h,
    MAX(IF(lab_name = 'lactate', mean_value, NULL)) AS lactate_mean_6h,
    MAX(IF(lab_name = 'lactate', count_value, NULL)) AS lactate_count_6h,
    MAX(IF(lab_name = 'lactate', last_value - first_value, NULL)) AS lactate_delta_6h,
    MAX(IF(lab_name = 'hemoglobin', first_value, NULL)) AS hemoglobin_first_6h,
    MAX(IF(lab_name = 'hemoglobin', last_value, NULL)) AS hemoglobin_last_6h,
    MAX(IF(lab_name = 'hemoglobin', min_value, NULL)) AS hemoglobin_min_6h,
    MAX(IF(lab_name = 'hemoglobin', max_value, NULL)) AS hemoglobin_max_6h,
    MAX(IF(lab_name = 'hemoglobin', mean_value, NULL)) AS hemoglobin_mean_6h,
    MAX(IF(lab_name = 'hemoglobin', count_value, NULL)) AS hemoglobin_count_6h,
    MAX(IF(lab_name = 'hemoglobin', last_value - first_value, NULL)) AS hemoglobin_delta_6h,
    MAX(IF(lab_name = 'hematocrit', first_value, NULL)) AS hematocrit_first_6h,
    MAX(IF(lab_name = 'hematocrit', last_value, NULL)) AS hematocrit_last_6h,
    MAX(IF(lab_name = 'hematocrit', min_value, NULL)) AS hematocrit_min_6h,
    MAX(IF(lab_name = 'hematocrit', max_value, NULL)) AS hematocrit_max_6h,
    MAX(IF(lab_name = 'hematocrit', mean_value, NULL)) AS hematocrit_mean_6h,
    MAX(IF(lab_name = 'hematocrit', count_value, NULL)) AS hematocrit_count_6h,
    MAX(IF(lab_name = 'hematocrit', last_value - first_value, NULL)) AS hematocrit_delta_6h,
    MAX(IF(lab_name = 'platelets', first_value, NULL)) AS platelets_first_6h,
    MAX(IF(lab_name = 'platelets', last_value, NULL)) AS platelets_last_6h,
    MAX(IF(lab_name = 'platelets', min_value, NULL)) AS platelets_min_6h,
    MAX(IF(lab_name = 'platelets', max_value, NULL)) AS platelets_max_6h,
    MAX(IF(lab_name = 'platelets', mean_value, NULL)) AS platelets_mean_6h,
    MAX(IF(lab_name = 'platelets', count_value, NULL)) AS platelets_count_6h,
    MAX(IF(lab_name = 'platelets', last_value - first_value, NULL)) AS platelets_delta_6h,
    MAX(IF(lab_name = 'wbc', first_value, NULL)) AS wbc_first_6h,
    MAX(IF(lab_name = 'wbc', last_value, NULL)) AS wbc_last_6h,
    MAX(IF(lab_name = 'wbc', min_value, NULL)) AS wbc_min_6h,
    MAX(IF(lab_name = 'wbc', max_value, NULL)) AS wbc_max_6h,
    MAX(IF(lab_name = 'wbc', mean_value, NULL)) AS wbc_mean_6h,
    MAX(IF(lab_name = 'wbc', count_value, NULL)) AS wbc_count_6h,
    MAX(IF(lab_name = 'wbc', last_value - first_value, NULL)) AS wbc_delta_6h
FROM eligible_anchors AS anchors
LEFT JOIN lab_summary AS summary
    ON anchors.stay_id = summary.stay_id
GROUP BY anchors.stay_id;
