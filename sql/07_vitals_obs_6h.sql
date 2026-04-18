-- AKI Pipeline Stage 07: Aggregate vital sign features from the observation window.
-- Intended output table: `{project_id}.{dataset_id}.{vitals_features_table}`
-- Intended inputs:
--   - `{project_id}.{dataset_id}.{prediction_anchors_table}`
--   - `physionet-data.mimiciv_2_2_derived.vitalsign`
--
-- We use the official `vitalsign` derived concept because it already maps the
-- raw chart events into named physiologic variables while preserving charttime.
-- All downstream joins still enforce the AKI observation-window boundary.

CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.{vitals_features_table}` AS
WITH eligible_anchors AS (
    SELECT
        stay_id,
        icu_intime,
        anchor_time
    FROM `{project_id}.{dataset_id}.{prediction_anchors_table}`
    WHERE eligible_for_prediction = 1
),
filtered_vitals AS (
    SELECT
        anchors.stay_id,
        vitals.charttime,
        CAST(vitals.heart_rate AS FLOAT64) AS heart_rate,
        CAST(vitals.sbp AS FLOAT64) AS sbp,
        CAST(vitals.dbp AS FLOAT64) AS dbp,
        CAST(vitals.mbp AS FLOAT64) AS mbp,
        CAST(vitals.resp_rate AS FLOAT64) AS resp_rate,
        CAST(vitals.temperature AS FLOAT64) AS temperature,
        CAST(vitals.spo2 AS FLOAT64) AS spo2
    FROM eligible_anchors AS anchors
    INNER JOIN `physionet-data.mimiciv_2_2_derived.vitalsign` AS vitals
        ON anchors.stay_id = vitals.stay_id
    WHERE vitals.charttime >= anchors.icu_intime
      AND vitals.charttime <= anchors.anchor_time
),
aggregated AS (
    SELECT
        stay_id,
        ARRAY_AGG(heart_rate IGNORE NULLS ORDER BY charttime ASC LIMIT 1)[SAFE_OFFSET(0)] AS heart_rate_first_6h,
        ARRAY_AGG(heart_rate IGNORE NULLS ORDER BY charttime DESC LIMIT 1)[SAFE_OFFSET(0)] AS heart_rate_last_6h,
        MIN(heart_rate) AS heart_rate_min_6h,
        MAX(heart_rate) AS heart_rate_max_6h,
        AVG(heart_rate) AS heart_rate_mean_6h,
        COUNTIF(heart_rate IS NOT NULL) AS heart_rate_count_6h,
        ARRAY_AGG(sbp IGNORE NULLS ORDER BY charttime ASC LIMIT 1)[SAFE_OFFSET(0)] AS sbp_first_6h,
        ARRAY_AGG(sbp IGNORE NULLS ORDER BY charttime DESC LIMIT 1)[SAFE_OFFSET(0)] AS sbp_last_6h,
        MIN(sbp) AS sbp_min_6h,
        MAX(sbp) AS sbp_max_6h,
        AVG(sbp) AS sbp_mean_6h,
        COUNTIF(sbp IS NOT NULL) AS sbp_count_6h,
        ARRAY_AGG(dbp IGNORE NULLS ORDER BY charttime ASC LIMIT 1)[SAFE_OFFSET(0)] AS dbp_first_6h,
        ARRAY_AGG(dbp IGNORE NULLS ORDER BY charttime DESC LIMIT 1)[SAFE_OFFSET(0)] AS dbp_last_6h,
        MIN(dbp) AS dbp_min_6h,
        MAX(dbp) AS dbp_max_6h,
        AVG(dbp) AS dbp_mean_6h,
        COUNTIF(dbp IS NOT NULL) AS dbp_count_6h,
        ARRAY_AGG(mbp IGNORE NULLS ORDER BY charttime ASC LIMIT 1)[SAFE_OFFSET(0)] AS mbp_first_6h,
        ARRAY_AGG(mbp IGNORE NULLS ORDER BY charttime DESC LIMIT 1)[SAFE_OFFSET(0)] AS mbp_last_6h,
        MIN(mbp) AS mbp_min_6h,
        MAX(mbp) AS mbp_max_6h,
        AVG(mbp) AS mbp_mean_6h,
        COUNTIF(mbp IS NOT NULL) AS mbp_count_6h,
        ARRAY_AGG(resp_rate IGNORE NULLS ORDER BY charttime ASC LIMIT 1)[SAFE_OFFSET(0)] AS resp_rate_first_6h,
        ARRAY_AGG(resp_rate IGNORE NULLS ORDER BY charttime DESC LIMIT 1)[SAFE_OFFSET(0)] AS resp_rate_last_6h,
        MIN(resp_rate) AS resp_rate_min_6h,
        MAX(resp_rate) AS resp_rate_max_6h,
        AVG(resp_rate) AS resp_rate_mean_6h,
        COUNTIF(resp_rate IS NOT NULL) AS resp_rate_count_6h,
        ARRAY_AGG(temperature IGNORE NULLS ORDER BY charttime ASC LIMIT 1)[SAFE_OFFSET(0)] AS temperature_first_6h,
        ARRAY_AGG(temperature IGNORE NULLS ORDER BY charttime DESC LIMIT 1)[SAFE_OFFSET(0)] AS temperature_last_6h,
        MIN(temperature) AS temperature_min_6h,
        MAX(temperature) AS temperature_max_6h,
        AVG(temperature) AS temperature_mean_6h,
        COUNTIF(temperature IS NOT NULL) AS temperature_count_6h,
        ARRAY_AGG(spo2 IGNORE NULLS ORDER BY charttime ASC LIMIT 1)[SAFE_OFFSET(0)] AS spo2_first_6h,
        ARRAY_AGG(spo2 IGNORE NULLS ORDER BY charttime DESC LIMIT 1)[SAFE_OFFSET(0)] AS spo2_last_6h,
        MIN(spo2) AS spo2_min_6h,
        MAX(spo2) AS spo2_max_6h,
        AVG(spo2) AS spo2_mean_6h,
        COUNTIF(spo2 IS NOT NULL) AS spo2_count_6h
    FROM filtered_vitals
    GROUP BY stay_id
)
SELECT
    anchors.stay_id,
    aggregated.heart_rate_first_6h,
    aggregated.heart_rate_last_6h,
    aggregated.heart_rate_min_6h,
    aggregated.heart_rate_max_6h,
    aggregated.heart_rate_mean_6h,
    aggregated.heart_rate_count_6h,
    aggregated.sbp_first_6h,
    aggregated.sbp_last_6h,
    aggregated.sbp_min_6h,
    aggregated.sbp_max_6h,
    aggregated.sbp_mean_6h,
    aggregated.sbp_count_6h,
    aggregated.dbp_first_6h,
    aggregated.dbp_last_6h,
    aggregated.dbp_min_6h,
    aggregated.dbp_max_6h,
    aggregated.dbp_mean_6h,
    aggregated.dbp_count_6h,
    aggregated.mbp_first_6h,
    aggregated.mbp_last_6h,
    aggregated.mbp_min_6h,
    aggregated.mbp_max_6h,
    aggregated.mbp_mean_6h,
    aggregated.mbp_count_6h,
    aggregated.resp_rate_first_6h,
    aggregated.resp_rate_last_6h,
    aggregated.resp_rate_min_6h,
    aggregated.resp_rate_max_6h,
    aggregated.resp_rate_mean_6h,
    aggregated.resp_rate_count_6h,
    aggregated.temperature_first_6h,
    aggregated.temperature_last_6h,
    aggregated.temperature_min_6h,
    aggregated.temperature_max_6h,
    aggregated.temperature_mean_6h,
    aggregated.temperature_count_6h,
    aggregated.spo2_first_6h,
    aggregated.spo2_last_6h,
    aggregated.spo2_min_6h,
    aggregated.spo2_max_6h,
    aggregated.spo2_mean_6h,
    aggregated.spo2_count_6h
FROM eligible_anchors AS anchors
LEFT JOIN aggregated
    ON anchors.stay_id = aggregated.stay_id;
