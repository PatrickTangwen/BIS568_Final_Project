You are implementing the main Google Colab extraction script for the AKI early-prediction pipeline.


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
Implement `data_fetch_aki.py`.

This file will be the main entry point that the user runs in Google Colab.

Required behavior:
1. Authenticate in Colab using `google.colab.auth`.
2. Configure:
   - project_id
   - dataset_id
   - sql directory
   - output directory
   - final table name
   - optional stage filter / RUN_ONLY list
3. Load SQL files from `sql/`.
4. Execute SQL stages in order.
5. Print simple progress logs and row counts after major stages.
6. Export the final table to CSV.
7. Optionally preview a few rows of the final dataset.

SQL execution order:
- 01_base_cohort.sql
- 02_kdigo_labels.sql
- 03_aki_onset.sql
- 04_prediction_anchors.sql
- 05_static_features.sql
- 06_labs_obs_6h.sql
- 07_vitals_obs_6h.sql
- 08_urine_obs_6h.sql
- 09_comorbidities.sql
- 10_final_aki_dataset.sql

Optional:
- allow running `99_sanity_checks.sql` separately or after the main stages

Implementation guidance:
1. Put the Colab auth block near the top.
2. Use a helper to read SQL files.
3. Use a helper to run SQL and wait for completion.
4. Use a helper to fetch a small dataframe preview and/or final CSV export.
5. Make the file robust to reruns.
6. Add comments explaining where the user should edit project / dataset names.
7. Do not assume local secrets beyond normal Colab auth.

Acceptance criteria:
- The file is clearly designed for Colab.
- Stage order is explicit.
- The user can rerun only selected stages if needed.
- Final CSV export path is easy to edit.

Output format:
- Show the full Python file content.
- Then provide a brief usage note for the user running it in Colab.
