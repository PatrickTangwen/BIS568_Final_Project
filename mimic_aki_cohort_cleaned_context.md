# Context for `mimic_aki_cohort_cleaned.csv`

This markdown is a quick context file for model development

## Dataset summary

- File: `mimic_aki_cohort_cleaned.csv`
- Shape: `29,274 rows x 156 columns`
- Unit of analysis: `one row per ICU stay`
- In the current cleaned file, `unique_subjects = 29,274` and `unique_stays = 29,274`
- This is effectively `one row per patient` in the current MVP because the cohort keeps the first ICU stay per patient

## Prediction task

- Target column: `future_aki_24h`
- Label meaning:
  - `0` = no AKI onset in the prediction window
  - `1` = AKI onset occurs in the prediction window
- Time design:
  - observation window: first `6 hours` after ICU admission
  - prediction window: next `24 hours` after the anchor
  - anchor time is `icu_intime + 6 hours`

## Target distribution

- `future_aki_24h = 0`: `12,156`
- `future_aki_24h = 1`: `17,118`
- Positive rate is relatively high, so report both `AUROC` and `PR-AUC`

## High-level column groups

### 1. Identifiers

- `subject_id`
- `hadm_id`
- `stay_id`

These should **not** be used as model features.

### 2. Timing / window metadata

- `icu_intime`
- `anchor_time`
- `obs_window_start`
- `obs_window_end`
- `pred_window_start`
- `pred_window_end`

These are useful for auditability, but should usually be excluded from the feature matrix for standard prediction modeling.

### 3. Target

- `future_aki_24h`

### 4. Demographics / baseline administrative features

- `admission_age`
- `gender`
- `race`
- `admission_type`
- `admission_location`
- `insurance`
- `language`
- `marital_status`

### 5. Comorbidity flags

- `ckd_flag`
- `diabetes_flag`
- `hypertension_flag`
- `chf_flag`
- `liver_disease_flag`
- `sepsis_infection_flag`
- `chronic_pulmonary_flag`

These are already encoded as binary baseline indicators.

### 6. Lab features from the first 6 hours

Feature families include:

- creatinine
- BUN
- bicarbonate
- potassium
- sodium
- chloride
- calcium
- glucose
- lactate
- hemoglobin
- hematocrit
- platelets

Typical naming pattern:

- `<lab>_first_6h`
- `<lab>_last_6h`
- `<lab>_min_6h`
- `<lab>_max_6h`
- `<lab>_mean_6h`
- `<lab>_count_6h`
- `<lab>_delta_6h`

### 7. Vital-sign features from the first 6 hours

Feature families include:

- `heart_rate_*`
- `sbp_*`
- `dbp_*`
- `mbp_*`
- `resp_rate_*`
- `temperature_*`
- `spo2_*`

Typical naming pattern:

- `<vital>_first_6h`
- `<vital>_last_6h`
- `<vital>_min_6h`
- `<vital>_max_6h`
- `<vital>_mean_6h`
- `<vital>_count_6h`

### 8. Urine-output features

- `urine_total_6h`
- `urine_count_6h`
- `weight_used_for_uo_norm`
- `urine_rate_6h`
- `oliguria_like_6h`

These are predictive features, but note that urine output is also part of the AKI definition, so this project should be explicit about leakage boundaries.

## What was already removed before this cleaned file

This cleaned file is intended for model development, not raw extraction.

Columns that were removed earlier include explicit leakage-style columns such as:

- `icu_outtime`
- `dischtime`
- `los_icu`
- `los_hospital`
- `hospital_expire_flag`
- `aki_onset_time`
- `aki_onset_stage`
- `aki_stage_max`
- `has_aki_anytime`
- `eligible_for_prediction`

Do **not assume** those columns still exist in the cleaned CSV.

## Missingness snapshot

Top missing columns in the current cleaned file:

1. `lactate_first_6h` — `51.68%`
2. `lactate_delta_6h` — `51.68%`
3. `lactate_count_6h` — `51.68%`
4. `lactate_mean_6h` — `51.68%`
5. `lactate_max_6h` — `51.68%`
6. `lactate_min_6h` — `51.68%`
7. `lactate_last_6h` — `51.68%`
8. `calcium_delta_6h` — `43.02%`
9. `calcium_first_6h` — `43.02%`
10. `calcium_last_6h` — `43.02%`

Additional calcium summaries and some sodium summaries also have substantial missingness.

## Modeling guidance

1. Use `future_aki_24h` as the target.
2. Do **not** use `subject_id`, `hadm_id`, or `stay_id` as predictors.
3. Do **not** use timing columns such as `icu_intime` or `anchor_time` as standard features unless there is a specific modeling reason.
4. Split at the `subject_id` level, not by row.
5. Handle missingness explicitly.
6. Report at least:
   - `AUROC`
   - `PR-AUC`
   - calibration curve
7. Prefer simple, explainable baselines first:
   - logistic regression
   - random forest

## Recommended simple feature engineering

Reasonable derived features for model development include:

- `bun_creatinine_ratio_last_6h`
- `pulse_pressure_last_6h`
- `shock_index_last_6h`
- `urine_ml_per_kg_6h`
- `creatinine_change_6h`

These should be created in a separate preprocessing step, not hardcoded into the target definition.

## Suggested report framing

If the goal is a BIS568-style model development section, the writeup can be organized as:

1. EDA:
   - demographics summary table
   - target distribution figure
   - simple age-by-target or sex/race-by-target summary
2. Preprocessing:
   - top missingness review
   - removal of identifiers and leakage columns
   - imputation strategy
   - any feature engineering
3. Data splitting:
   - subject-level train / validation / test split
4. Model development:
   - at least two models on the same cleaned dataset
5. Evaluation:
   - ROC
   - PR curve
   - calibration curve
   - short comparison between models and splits

## Important caution

This project is an **AKI early prediction** task, not a general outcome prediction task.
Please do not redefine the target and should not bring back post-anchor or full-stay leakage features.
