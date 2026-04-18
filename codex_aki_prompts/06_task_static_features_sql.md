You are implementing the baseline/static feature SQL for the AKI pipeline.


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
Implement `sql/05_static_features.sql`.

Inputs:
- `aki_base_cohort`
- admissions / patients style context if needed

Output table name:
- `aki_static_features`

Expected row grain:
- one row per stay_id

Candidate features:
- subject_id
- hadm_id
- stay_id
- admission_age
- gender
- race
- admission_type
- admission_location
- insurance
- language
- marital_status
- first_icu_stay
- first_hosp_stay

Requirements:
1. Keep this table strictly one row per stay_id.
2. Use only baseline or slowly varying administrative/demographic information.
3. Add comments to distinguish safe baseline context from future information.
4. Preserve identifiers needed for downstream joins.

Do not:
- include post-anchor summaries
- include AKI label fields
- include full-stay leakage summaries as modeling features

Acceptance criteria:
- Table is one row per stay_id.
- Columns are baseline-safe.
- The SQL is clear and easy to maintain.

Output format:
- Show the full SQL file content.
- Then give a short bullet list of included feature groups.
