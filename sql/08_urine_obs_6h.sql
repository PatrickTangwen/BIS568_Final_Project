-- AKI Pipeline Stage 08: Aggregate urine output features from the observation window.
-- Intended output table: `{project_id}.{dataset_id}.{urine_features_table}`
-- Intended inputs:
--   - `{project_id}.{dataset_id}.{prediction_anchors_table}`
--   - `physionet-data.mimiciv_2_2_icu.outputevents`
--   - `physionet-data.mimiciv_2_2_icu.chartevents` for weight normalization
--
-- Leakage warning:
-- urine output is both a predictive feature and part of the AKI definition.
-- This feature table only uses urine events from `icu_intime` through
-- `anchor_time`. Label construction happens separately in the KDIGO stage SQL.

CREATE OR REPLACE TABLE `{project_id}.{dataset_id}.{urine_features_table}` AS
WITH eligible_anchors AS (
    SELECT
        stay_id,
        icu_intime,
        anchor_time
    FROM `{project_id}.{dataset_id}.{prediction_anchors_table}`
    WHERE eligible_for_prediction = 1
),
urine_events AS (
    SELECT
        anchors.stay_id,
        oe.charttime,
        CASE
            WHEN oe.itemid = 227488 AND CAST(oe.value AS FLOAT64) > 0
            THEN -1 * CAST(oe.value AS FLOAT64)
            ELSE CAST(oe.value AS FLOAT64)
        END AS urine_output_ml
    FROM eligible_anchors AS anchors
    INNER JOIN `physionet-data.mimiciv_2_2_icu.outputevents` AS oe
        ON anchors.stay_id = oe.stay_id
    WHERE oe.itemid IN (
        226559, 226560, 226561, 226584, 226563,
        226564, 226565, 226567, 226557, 226558,
        227488, 227489
    )
      AND oe.value IS NOT NULL
      AND oe.charttime >= anchors.icu_intime
      AND oe.charttime <= anchors.anchor_time
),
urine_summary AS (
    SELECT
        stay_id,
        SUM(urine_output_ml) AS urine_total_6h,
        COUNT(*) AS urine_count_6h
    FROM urine_events
    GROUP BY stay_id
),
weight_candidates AS (
    SELECT
        anchors.stay_id,
        ce.charttime,
        CAST(ce.valuenum AS FLOAT64) AS weight_kg,
        ce.itemid
    FROM eligible_anchors AS anchors
    INNER JOIN `physionet-data.mimiciv_2_2_icu.chartevents` AS ce
        ON anchors.stay_id = ce.stay_id
    WHERE ce.itemid IN (226512, 224639)
      AND ce.valuenum IS NOT NULL
      AND ce.valuenum > 0
      AND ce.charttime >= DATETIME_SUB(anchors.icu_intime, INTERVAL 2 HOUR)
      AND ce.charttime <= anchors.anchor_time
),
weight_summary AS (
    SELECT
        stay_id,
        ARRAY_AGG(
            STRUCT(weight_kg, charttime)
            ORDER BY
                CASE WHEN itemid = 226512 THEN 0 ELSE 1 END,
                charttime
            LIMIT 1
        )[SAFE_OFFSET(0)] AS selected_weight
    FROM weight_candidates
    GROUP BY stay_id
)
SELECT
    anchors.stay_id,
    urine.urine_total_6h,
    urine.urine_count_6h,
    weight.selected_weight.weight_kg AS weight_used_for_uo_norm,
    CASE
        WHEN weight.selected_weight.weight_kg IS NOT NULL
         AND weight.selected_weight.weight_kg > 0
        THEN urine.urine_total_6h / weight.selected_weight.weight_kg / 6.0
        ELSE NULL
    END AS urine_rate_6h,
    CASE
        WHEN weight.selected_weight.weight_kg IS NOT NULL
         AND weight.selected_weight.weight_kg > 0
         AND urine.urine_total_6h / weight.selected_weight.weight_kg / 6.0 < 0.5
        THEN 1
        WHEN weight.selected_weight.weight_kg IS NOT NULL
         AND weight.selected_weight.weight_kg > 0
        THEN 0
        ELSE NULL
    END AS oliguria_like_6h
FROM eligible_anchors AS anchors
LEFT JOIN urine_summary AS urine
    ON anchors.stay_id = urine.stay_id
LEFT JOIN weight_summary AS weight
    ON anchors.stay_id = weight.stay_id;
