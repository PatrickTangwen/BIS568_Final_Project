# AKI Early-Prediction Pipeline Plan

## Target task
- Build an AKI early-prediction dataset from MIMIC-IV for adult ICU patients.
- Keep the first ICU stay per patient for the MVP version.
- Produce one modeling row per `stay_id` with the binary target `future_aki_24h`.

## Core time design
- Observation window: the first 6 hours before the prediction anchor.
- Prediction horizon: AKI onset within the next 24 hours after the anchor.
- Leakage boundary: only features observed on or before the anchor can be used.

## Expected file flow
1. `sql/01_base_cohort.sql` defines the ICU cohort backbone.
2. `sql/02_kdigo_labels.sql` derives KDIGO evidence signals.
3. `sql/03_aki_onset.sql` converts evidence into first-onset timing.
4. `sql/04_prediction_anchors.sql` creates one leakage-safe anchor per stay.
5. `sql/05_static_features.sql` through `sql/09_comorbidities.sql` build feature blocks.
6. `sql/10_final_aki_dataset.sql` joins features into the final modeling table.
7. `sql/99_sanity_checks.sql` validates row counts, timing rules, and target shape.
8. `data_fetch_aki.py` runs the stages in order from Google Colab.

## When to switch to Colab
- After the scaffold SQL files exist and the first SQL stages are implemented enough for a smoke test.
- Again after KDIGO label and AKI onset logic is implemented.
- Again after the full feature stack is implemented and ready for export.
- Later for notebook-based cleaning and modeling work.

