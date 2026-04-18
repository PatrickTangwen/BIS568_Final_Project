# Codex Prompt Pack for AKI Early Prediction Pipeline

This file contains task-specific prompts you can paste into Codex one by one.

## Recommended order
1. 01_task_scaffold.md
2. 02_task_base_cohort_sql.md
3. 03_task_kdigo_labels_sql.md
4. 04_task_aki_onset_sql.md
5. 05_task_prediction_anchors_sql.md
6. 06_task_static_features_sql.md
7. 07_task_labs_obs6h_sql.md
8. 08_task_vitals_obs6h_sql.md
9. 09_task_urine_obs6h_sql.md
10. 10_task_comorbidities_sql.md
11. 11_task_final_dataset_sql.md
12. 12_task_sanity_checks_sql.md
13. 13_task_data_fetch_aki_py.md
14. User switches to Google Colab and runs the extraction script for the first real test
15. 14_task_cleaning_notebook.md
16. 15_task_models_notebook.md
17. 16_task_refine_after_first_colab_run.md

## What these prompts assume
- You are adapting an existing repo that currently follows this pattern:
  - one extraction script
  - notebook/data_cleaning.ipynb
  - notebook/ML_models.ipynb
- The AKI version should keep the same overall style.
- Data extraction is run in Google Colab through BigQuery.
- SQL files should be modular and saved under `sql/`.
- The first task version is an MVP:
  - adult ICU patients
  - first ICU stay per patient
  - 6h observation window
  - 24h prediction horizon
  - one row per `stay_id`
  - target = `future_aki_24h`

## Important operational boundary
Codex should generate and edit files.
The user should run files in Google Colab whenever BigQuery access, authentication, or CSV export is required.

## Expected file set
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
- notebook/aki_data_cleaning.ipynb
- notebook/aki_models.ipynb

## When the user should switch to Colab
- After `data_fetch_aki.py` exists and at least the first SQL stages are implemented.
- Again after AKI label SQL is implemented.
- Again after the full feature SQL stack is implemented.
- For the cleaning and modeling notebooks.

## Notes
- Keep project IDs, dataset IDs, and output table names configurable.
- Do not hardcode secrets.
- Add comments anywhere time-boundary leakage is a risk.
- Prefer simple, debuggable SQL over one giant monolithic query.
