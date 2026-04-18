You are implementing urine-output feature extraction for the AKI early-prediction pipeline.


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
Implement `sql/08_urine_obs_6h.sql`.

Inputs:
- `aki_prediction_anchors`
- urine-output event sources
- weight source if needed for rate normalization

Output table name:
- `aki_urine_obs_6h`

Expected row grain:
- one row per stay_id

Candidate features:
- urine_total_6h
- urine_count_6h
- urine_rate_6h if weight is available
- oliguria-like indicator during the observation window
- weight_used_for_uo_norm if you choose to expose it

Critical warning:
Urine output is both:
- a predictive feature
- part of the AKI definition

So this SQL must be especially explicit about leakage control.

Required temporal rule:
Every urine event used for feature construction must satisfy:
- event_time >= icu_intime
- event_time <= anchor_time

Implementation guidance:
1. Add a prominent comment block explaining the leakage boundary.
2. Keep label construction and feature construction logically separate even if they touch similar raw data.
3. If weight normalization is included, clearly state the source and any assumptions.
4. Prefer a simple, auditable first version over over-engineered logic.

Acceptance criteria:
- One row per stay_id.
- Observation-window boundary is explicit.
- The file clearly documents the feature-vs-label separation.

Output format:
- Show the full SQL file content.
- Then explain the leakage precautions in plain language.
