You are implementing the final dataset assembly SQL for the AKI early-prediction pipeline.


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
Implement `sql/10_final_aki_dataset.sql`.

Inputs:
- `aki_base_cohort`
- `aki_prediction_anchors`
- `aki_static_features`
- `aki_labs_obs_6h`
- `aki_vitals_obs_6h`
- `aki_urine_obs_6h`
- `aki_comorbidities`
- optionally `aki_onset` if useful for debug-only columns

Output table name:
- `mimic_aki_cohort_raw`

Expected row grain:
- exactly one row per stay_id

Required columns:
- identifiers: subject_id, hadm_id, stay_id
- timing metadata: icu_intime, anchor_time
- target: future_aki_24h
- baseline / observation-window features only

Requirements:
1. Join all feature tables carefully and preserve one row per stay_id.
2. Add explicit comments around any debug-only columns.
3. Do not include post-anchor leakage features.
4. Keep the final file easy to inspect because it will be exported to CSV.
5. If helpful, include a final QUALIFY or duplicate check pattern to guard one-row-per-stay.

Acceptance criteria:
- Exactly one row per stay_id.
- Target column exists.
- Output is ready for CSV export.
- No obvious post-anchor fields are included as model features.

Output format:
- Show the full SQL file content.
- Then describe the join order and duplicate-protection logic.
