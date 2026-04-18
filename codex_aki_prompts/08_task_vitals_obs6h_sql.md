You are implementing vital-sign feature extraction from the first 6 hours after ICU admission.


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
Implement `sql/07_vitals_obs_6h.sql`.

Inputs:
- `aki_prediction_anchors`
- raw or event-level vital-sign sources

Output table name:
- `aki_vitals_obs_6h`

Expected row grain:
- one row per stay_id

Priority variables:
- heart rate
- systolic blood pressure
- diastolic blood pressure
- mean blood pressure
- respiratory rate
- temperature
- SpO2

Required aggregations per variable where feasible:
- first
- last
- min
- max
- mean
- count

Critical temporal rule:
Every included event must satisfy:
- event_time >= icu_intime
- event_time <= anchor_time

Implementation guidance:
1. Join through `aki_prediction_anchors`.
2. Use consistent feature naming:
   - `heart_rate_mean_6h`
   - `mbp_min_6h`
   - etc.
3. Keep the logic separate from labs for easier debugging.
4. Add comments anywhere source-table assumptions may vary by MIMIC version.

Acceptance criteria:
- One row per stay_id.
- Vitals are restricted to the observation window.
- Naming is consistent with the labs feature file.

Output format:
- Show the full SQL file content.
- Then provide a short feature-naming summary.
