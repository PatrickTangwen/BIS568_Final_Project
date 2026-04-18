下面这版可以直接保存成 `AKI_pipeline_plan.md`。它是按你当前 repo 的风格写的：保留 `data_fetch.py -> notebook/清洗 -> notebook/建模` 这条主线，但把任务从"pneumonia cohort + first_day 静态表 + mortality"切到"通用 ICU cohort + AKI 标签 + 早期预测"。你当前仓库的 `data_fetch.py` 现在是从 pneumonia ICD 映射表出发，连 `icustay_detail / admissions / patients`，再拼 `first_day_lab / first_day_vitalsign / first_day_bg / inflammation / first_day_urine_output / first_day_height / first_day_weight` 导出 `mimic_pneumonia_cohort_full.csv`；`ML_models.ipynb` 则以 `hospital_expire_flag` 为目标，并已做 `subject_id` 级切分、显式去掉 `los_hospital / los_icu` 这类泄漏变量。MIMIC-IV 官方当前可在 BigQuery 使用，且官方 `kdigo_stages.sql` 已给出 AKI 的标准派生逻辑。([GitHub][1])


# AKI Early Prediction Pipeline Plan

## 1. Goal

Build an AKI early prediction data pipeline in the style of the current repo.

Current repo style:
- one main extraction script from BigQuery
- one cleaning notebook
- one modeling notebook
- exported CSV / cleaned table for downstream use

Target task:
- predict **future AKI onset** in ICU patients
- avoid label leakage
- keep the pipeline simple enough for iterative development in Colab + BigQuery

This plan is for **data extraction and dataset construction**, not for final model optimization.

---

## 2. Key design shift from the current repo

### Current repo
The current pipeline is:
1. start from a disease-specific cohort (pneumonia ICD mapping)
2. join ICU stay backbone
3. attach `first_day_*` derived features
4. export one static row per stay
5. model `hospital_expire_flag`

### AKI pipeline
The AKI pipeline must instead be:
1. start from a **general ICU cohort**
2. derive **time-aware AKI labels**
3. define a **prediction anchor time**
4. use only features available **before anchor time**
5. predict whether AKI will happen **after anchor time**

### Why this shift is necessary
AKI is not just a diagnosis-code cohort task. In MIMIC, the official AKI concept is computed over time using serum creatinine and urine output, with stage logic derived from KDIGO. Therefore, we should not define the cohort via pneumonia-style ICD filtering, and we should not directly use first-day summary tables as the main feature source for early prediction. Those tables are useful as references, but they can cross the prediction boundary and create leakage.

---

## 3. Proposed task definition (MVP)

### Prediction unit
- one row per `stay_id`

### Cohort
- adult ICU stays only
- use first ICU stay per patient in the first version
- require enough stay duration to support observation + prediction window

### Observation window
- first **6 hours** after ICU admission

### Prediction horizon
- predict whether AKI occurs in the **next 24 hours**
- equivalent label: AKI onset in `(icu_intime + 6h, icu_intime + 30h]`

### Label
- binary label: `future_aki_24h`
- `1` if first AKI onset occurs after the observation window and within the horizon
- `0` otherwise

### Exclusions
- AKI already present before or at anchor time
- ICU stay too short to evaluate horizon
- clearly insufficient renal monitoring data for reliable labeling

### Why this MVP
This is the simplest clean early-prediction setup:
- easy to explain
- easy to implement
- avoids most leakage
- close to the current repo style of one-row-per-stay modeling

---

## 4. Directory / file plan

Keep the repo style similar to the current project.

```text
.
├── sql/
│   ├── 01_base_cohort.sql
│   ├── 02_kdigo_labels.sql
│   ├── 03_aki_onset.sql
│   ├── 04_prediction_anchors.sql
│   ├── 05_static_features.sql
│   ├── 06_labs_obs_6h.sql
│   ├── 07_vitals_obs_6h.sql
│   ├── 08_urine_obs_6h.sql
│   ├── 09_comorbidities.sql
│   ├── 10_final_aki_dataset.sql
│   └── 99_sanity_checks.sql
├── data_fetch_aki.py
├── notebook/
│   ├── aki_data_cleaning.ipynb
│   ├── aki_eda.ipynb
│   └── aki_models.ipynb
├── docs/
│   └── AKI_pipeline_plan.md
└── outputs/
    ├── mimic_aki_cohort_raw.csv
    ├── mimic_aki_cohort_cleaned.csv
    └── data_dictionary_aki.csv
````

---

## 5. File-by-file responsibilities

## 5.1 `sql/01_base_cohort.sql`

### Purpose

Create the ICU backbone cohort.

### Input tables

* `physionet-data.mimiciv_icu.icustays`
* `physionet-data.mimiciv_derived.icustay_detail` if convenient
* `physionet-data.mimiciv_hosp.admissions`
* `physionet-data.mimiciv_hosp.patients`

### Output

A table like:

* `project.dataset.aki_base_cohort`

### Required columns

* `subject_id`
* `hadm_id`
* `stay_id`
* `icu_intime`
* `icu_outtime`
* `admittime`
* `dischtime`
* `admission_age`
* `gender`
* `race`
* `admission_type`
* `admission_location`
* `insurance`
* `hospital_expire_flag`
* `los_icu`
* `los_hospital`
* `first_icu_stay`
* `first_hosp_stay`

### Inclusion logic

* age >= 18
* ICU stays only
* first ICU stay per patient for MVP
* ICU LOS long enough for 6h observation + 24h prediction horizon

### Notes for Codex

* prefer `icustay_detail` if it already contains derived age and first-stay flags
* keep this table compact and reusable
* do not include disease-specific ICD filtering here

---

## 5.2 `sql/02_kdigo_labels.sql`

### Purpose

Build AKI stage timeline using official MIMIC logic.

### Preferred strategy

Reuse or adapt the official MIMIC concept:

* `kdigo_creatinine`
* `kdigo_uo`
* `kdigo_stages`

### Output

A table like:

* `project.dataset.kdigo_stages_aki`

### Required columns

* `stay_id`
* `charttime`
* `aki_stage`
* `aki_stage_smoothed`
* `aki_stage_creat`
* `aki_stage_uo`
* `aki_stage_crrt`

### Notes for Codex

* do **not** invent a custom AKI definition first
* start from the official logic and only adapt table paths if needed
* preserve the time axis because downstream onset extraction depends on it

---

## 5.3 `sql/03_aki_onset.sql`

### Purpose

Convert the stage timeline into one onset record per ICU stay.

### Output

A table like:

* `project.dataset.aki_onset`

### Required columns

* `stay_id`
* `aki_onset_time`
* `aki_onset_stage`
* `aki_stage_max`
* `has_aki_anytime`

### Core logic

* first time where `aki_stage_smoothed >= 1` is the AKI onset
* maximum stage during ICU stay can be retained for future analyses

### Notes for Codex

* use `MIN(charttime)` over stage-positive rows
* preserve stays with no AKI by returning `NULL aki_onset_time`

---

## 5.4 `sql/04_prediction_anchors.sql`

### Purpose

Define the prediction anchor and eligibility for modeling.

### Output

A table like:

* `project.dataset.aki_prediction_anchors`

### Required columns

* `stay_id`
* `anchor_time`
* `obs_window_start`
* `obs_window_end`
* `pred_window_start`
* `pred_window_end`
* `eligible_for_prediction`
* `future_aki_24h`

### Core logic

* `obs_window_start = icu_intime`
* `obs_window_end = icu_intime + 6 hours`
* `pred_window_start = obs_window_end`
* `pred_window_end = obs_window_end + 24 hours`
* exclude stays where AKI onset is `<= obs_window_end`
* positive label if `aki_onset_time` is in `(pred_window_start, pred_window_end]`

### Notes for Codex

* this table is the formal boundary between label construction and feature extraction
* all feature queries must join to this table and enforce `event_time <= anchor_time`

---

## 5.5 `sql/05_static_features.sql`

### Purpose

Extract non-time-varying or slowly varying baseline features.

### Output

A table like:

* `project.dataset.aki_static_features`

### Feature groups

* demographics
* admission metadata
* first ICU stay / first hospital stay flags
* coarse admission context

### Candidate columns

* `subject_id`, `hadm_id`, `stay_id`
* `admission_age`
* `gender`
* `race`
* `admission_type`
* `admission_location`
* `insurance`
* `marital_status`
* `language`
* `hospital_expire_flag` only for reference, not modeling target here

### Notes for Codex

* keep identifiers for joining
* do not yet drop columns just because they may be excluded later in modeling

---

## 5.6 `sql/06_labs_obs_6h.sql`

### Purpose

Build lab features from the observation window only.

### Main idea

Use raw or semi-raw lab events constrained to:

* `charttime >= icu_intime`
* `charttime <= anchor_time`

### Priority renal / metabolic labs

* creatinine
* BUN
* bicarbonate
* potassium
* sodium
* chloride
* calcium
* glucose
* lactate
* hemoglobin
* hematocrit
* platelets
* WBC

### Aggregations per variable

* `first`
* `last`
* `min`
* `max`
* `mean`
* `count`
* optionally `delta = last - first`

### Output

A wide table like:

* `stay_id`
* `creatinine_first_6h`
* `creatinine_last_6h`
* `creatinine_min_6h`
* `creatinine_max_6h`
* `creatinine_mean_6h`
* `creatinine_count_6h`
* etc.

### Notes for Codex

* feature names must encode variable + aggregation + window
* do not use first-day derived tables as the final source for this task unless the time boundary is guaranteed safe
* prefer raw event tables or event-level derived concepts where time filtering is explicit

---

## 5.7 `sql/07_vitals_obs_6h.sql`

### Purpose

Build vital sign features from the same observation window.

### Priority variables

* heart rate
* systolic BP
* diastolic BP
* mean BP
* respiratory rate
* temperature
* SpO2

### Aggregations

* `first`
* `last`
* `min`
* `max`
* `mean`
* `count`

### Output

A wide table keyed by `stay_id`

### Notes for Codex

* follow the same naming convention as labs
* keep this query separate from labs for simpler debugging

---

## 5.8 `sql/08_urine_obs_6h.sql`

### Purpose

Build urine-related features from the observation window.

### Why separate file

Urine output is both:

* a feature for prediction
* a component of the AKI definition

So this file needs extra leakage care.

### Candidate features

* total urine output in first 6h
* urine output rate normalized by weight if feasible
* urine measurement count
* oliguria indicator in observation window
* weight used for normalization

### Output

A table keyed by `stay_id`

### Notes for Codex

* use only urine data up to `anchor_time`
* keep label generation and feature generation logically separate even if both depend on urine output
* include clear comments about leakage boundaries

---

## 5.9 `sql/09_comorbidities.sql`

### Purpose

Build diagnosis-history style features.

### Candidate comorbidities

* CKD
* diabetes
* hypertension
* CHF
* liver disease
* sepsis / infection-related flags
* chronic pulmonary disease if desired

### Input tables

* `diagnoses_icd`
* optional curated ICD mappings

### Output

A table like:

* one row per `stay_id`
* one binary flag per comorbidity

### Notes for Codex

* do not use future diagnosis information that would only be known after the prediction window in a real deployment setting if that concern matters
* acceptable MVP choice: use diagnosis codes attached to the hospitalization as coarse baseline context
* keep mapping logic transparent and editable

---

## 5.10 `sql/10_final_aki_dataset.sql`

### Purpose

Assemble the final one-row-per-stay modeling dataset.

### Join order

* anchors
* base cohort
* static features
* labs
* vitals
* urine
* comorbidities
* onset summary if needed

### Output

A final table like:

* `project.dataset.mimic_aki_cohort_raw`

### Required columns

* IDs: `subject_id`, `hadm_id`, `stay_id`
* time references: `icu_intime`, `anchor_time`
* target: `future_aki_24h`
* feature columns only from observation window or baseline context

### Hard exclusions

* any feature using information after `anchor_time`
* any label information accidentally included as feature columns
* leakage columns like full LOS if they imply future information

---

## 5.11 `sql/99_sanity_checks.sql`

### Purpose

Run validation checks before export.

### Checks

* cohort row count
* positive label prevalence
* number excluded due to early AKI
* number excluded due to short ICU stay
* fraction missing by major feature family
* verify no feature event timestamp exceeds anchor time
* verify one row per `stay_id`

### Recommended outputs

* summary tables
* a small random sample for manual inspection

---

## 6. Python script plan

## 6.1 `data_fetch_aki.py`

### Purpose

Equivalent to current `data_fetch.py`, but for AKI.

### Responsibilities

1. authenticate in Colab
2. define `project_id` and `dataset_id`
3. run SQL files in order
4. materialize intermediate tables in BigQuery
5. export final dataset to CSV
6. optionally export a data dictionary

### Style constraints

* keep similar coding style to current repo
* simple top-level script is acceptable
* use helper function `query_bigquery(sql_query: str) -> pd.DataFrame`
* use one config block near the top

### Suggested config block

* `project_id`
* `dataset_id`
* `output_table_prefix`
* `use_demo`
* `export_csv`
* `csv_filename = 'mimic_aki_cohort_raw.csv'`

### Recommended behavior

* SQL files can be read from `sql/`
* either:

  * execute table-creation SQL one by one, or
  * store each query as a Python multiline string for MVP
* print row counts after each major step

---

## 7. Notebook plan

## 7.1 `notebook/aki_data_cleaning.ipynb`

### Purpose

Equivalent to current `data_cleaning.ipynb`

### Responsibilities

* load `mimic_aki_cohort_raw`
* inspect missingness
* drop obviously unusable columns
* encode / standardize naming if necessary
* create `mimic_aki_cohort_cleaned`
* export cleaned CSV / BigQuery table

### Important rules

* do not create features here using future information
* do not rebalance labels here in a way that changes the source dataset
* preserve identifiers for subject-level splitting

---

## 7.2 `notebook/aki_eda.ipynb`

### Purpose

Quick clinical and data sanity analysis

### Suggested contents

* cohort flow summary
* AKI prevalence
* time to AKI onset distribution
* missingness heatmap
* feature distribution for positive vs negative class
* creatinine / urine summary diagnostics

---

## 7.3 `notebook/aki_models.ipynb`

### Purpose

Baseline modeling notebook in the style of current `ML_models.ipynb`

### Initial target

* `future_aki_24h`

### Required split rule

* split by `subject_id`, not by random row

### Initial models

* logistic regression
* random forest
* XGBoost or LightGBM if available

### Metrics

* AUROC
* AUPRC
* sensitivity / specificity at a chosen threshold
* calibration if possible

### Leakage control

Drop at least:

* direct identifiers
* timestamp columns
* future LOS-like columns
* any column derived from post-anchor data

---

## 8. Data contract for final modeling table

The final modeling table must satisfy:

### Unit

* exactly one row per `stay_id`

### Columns

* identifiers
* anchor metadata
* binary target
* baseline features
* observation-window features only

### Forbidden columns

* any event after anchor time
* full-stay summaries
* post-outcome summary statistics
* explicit AKI stage columns used to define the future label

### Split rule

* all stays from the same `subject_id` must remain in the same split

---

## 9. Naming conventions

Use explicit names.

### Tables

* `aki_base_cohort`
* `kdigo_stages_aki`
* `aki_onset`
* `aki_prediction_anchors`
* `aki_static_features`
* `aki_labs_obs_6h`
* `aki_vitals_obs_6h`
* `aki_urine_obs_6h`
* `aki_comorbidities`
* `mimic_aki_cohort_raw`

### Columns

Prefer:

* `<feature>_<agg>_<window>`
  Examples:
* `creatinine_last_6h`
* `bun_max_6h`
* `heart_rate_mean_6h`
* `urine_total_6h`

---

## 10. What to reuse from the current repo

### Reuse directly

* Colab + BigQuery authentication pattern
* top-level extraction script style
* raw -> cleaned -> model notebook flow
* `subject_id` level split logic in modeling
* explicit drop of obvious leakage columns

### Replace

* disease ontology ICD filtering
* pneumonia-specific metadata columns
* mortality target
* blind use of `first_day_*` as final modeling features

---

## 11. MVP acceptance criteria

The first version is acceptable if:

1. `data_fetch_aki.py` runs end-to-end
2. `mimic_aki_cohort_raw` is produced with one row per `stay_id`
3. `future_aki_24h` is populated
4. no feature uses information after anchor time
5. baseline notebook can train at least one model without crashing
6. train/test split is by `subject_id`
7. sanity checks are saved and readable

---

## 12. Suggested Codex task breakdown

### Task 1

Create `sql/01_base_cohort.sql`

### Task 2

Create `sql/02_kdigo_labels.sql` by adapting official MIMIC AKI concept to project dataset paths

### Task 3

Create `sql/03_aki_onset.sql`

### Task 4

Create `sql/04_prediction_anchors.sql`

### Task 5

Create observation-window feature SQL files:

* labs
* vitals
* urine

### Task 6

Create comorbidity flag SQL

### Task 7

Create `sql/10_final_aki_dataset.sql`

### Task 8

Create `sql/99_sanity_checks.sql`

### Task 9

Implement `data_fetch_aki.py`

### Task 10

Create starter notebooks:

* `aki_data_cleaning.ipynb`
* `aki_models.ipynb`

---

## 13. Explicit non-goals for version 1

Do not do these in the first pass:

* rolling multi-anchor prediction
* sequence models
* time-to-event survival modeling
* stage-specific multiclass AKI prediction
* extensive ICD phenotyping system
* complicated imputation research
* external validation

These can be added later after the MVP works.

---

## 14. Practical warnings

1. AKI label construction and urine-output feature construction touch similar raw data; keep them in separate logical stages to avoid confusion.
2. If using demo data, the pipeline is for debugging and development, not for serious model performance claims.
3. If raw event queries are too expensive or complicated, use intermediate BigQuery tables rather than one giant SQL.
4. Always keep a small manual inspection sample for positive and negative cases.

---

## 15. Final implementation principle

The pipeline should be:

* simple
* leakage-aware
* easy to debug
* easy to extend

The first success criterion is **correct temporal dataset construction**, not fancy modeling.


