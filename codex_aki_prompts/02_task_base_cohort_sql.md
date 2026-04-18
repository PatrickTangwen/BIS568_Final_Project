You are implementing the first real SQL file for an AKI early-prediction pipeline.


General requirements for this task:
- Keep the repo style close to the current project.
- Write clear, maintainable code and comments.
- Avoid data leakage across the prediction anchor.
- Make project_id, dataset_id, and output table names configurable.
- Do not hardcode secrets or user-specific paths.
- If a task creates a file that will be run in Colab, add a short usage comment near the top.
- Prefer explicit names and step-by-step logic over clever compact code.
- Unless the task explicitly asks for execution, only generate or edit files; do not claim the code was run.


Objective:
Implement `sql/01_base_cohort.sql`.

Target task design:
- one row per ICU stay
- adult patients only
- first ICU stay per patient for MVP
- enough ICU length to support a 6h observation window and a 24h prediction horizon

Use this output table name:
- `aki_base_cohort`

Expected columns:
- subject_id
- hadm_id
- stay_id
- icu_intime
- icu_outtime
- admittime
- dischtime
- admission_age
- gender
- race
- admission_type
- admission_location
- insurance
- language
- marital_status
- hospital_expire_flag
- los_icu
- los_hospital
- first_icu_stay
- first_hosp_stay

Implementation guidance:
1. Prefer using MIMIC-IV ICU backbone plus hospital admissions/patients.
2. If an `icustay_detail`-style derived table is available and simplifies age / first-stay flags, it is fine to use it.
3. Filter to adults only.
4. Restrict to the first ICU stay per patient in version 1.
5. Filter out ICU stays too short for:
   - observation window = 6 hours
   - prediction horizon = 24 hours
6. Keep identifiers and timestamps explicit.
7. Add comments explaining each filter.

Also:
- Add a comment block at the top listing likely source tables.
- Keep project / dataset references easy to edit later.
- Favor clarity over compactness.

Acceptance criteria:
- The SQL clearly produces one row per eligible stay_id.
- The stay-duration filter is explicit.
- The first-ICU-stay logic is explicit.
- The file is ready to be called by `data_fetch_aki.py`.

Output format:
- First show the full SQL file content.
- Then briefly explain the key design choices.
