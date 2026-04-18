You are modifying an existing MIMIC-IV cohort repo and need to scaffold an AKI early-prediction pipeline.


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
Create the AKI pipeline file structure and minimal placeholders, without trying to fully implement all logic yet.

Create or update these paths:
- sql/01_base_cohort.sql
- sql/02_kdigo_labels.sql
- sql/03_aki_onset.sql
- sql/04_prediction_anchors.sql
- sql/05_static_features.sql
- sql/06_labs_obs_6h.sql
- sql/07_vitals_obs_6h.sql
- sql/08_urine_obs_6h.sql
- sql/09_comorbidities.sql
- sql/10_final_aki_dataset.sql
- sql/99_sanity_checks.sql
- data_fetch_aki.py
- docs/AKI_pipeline_plan.md

Requirements:
1. Create the files if they do not exist.
2. Each SQL file should contain:
   - a short header comment
   - the intended output table name
   - the intended inputs
   - a TODO block describing implementation scope
3. `data_fetch_aki.py` should be a scaffold only:
   - config block
   - placeholder function to read SQL files
   - placeholder function to run a query
   - ordered list of SQL stages
   - a clear comment that this file is intended to be run in Google Colab
4. `docs/AKI_pipeline_plan.md` should briefly summarize:
   - the target task
   - the observation window
   - the prediction horizon
   - the expected file flow
   - when the user should switch to Colab

Do not:
- write full AKI SQL yet
- write notebooks yet
- delete any existing repo files unless they are clearly obsolete placeholders you created in this task

Output format:
- Provide a concise summary of created files
- Mention any assumptions you made
