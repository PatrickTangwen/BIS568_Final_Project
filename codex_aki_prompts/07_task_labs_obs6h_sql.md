You are implementing lab feature extraction from the first 6 hours after ICU admission.


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
Implement `sql/06_labs_obs_6h.sql`.

Inputs:
- `aki_prediction_anchors`
- raw or event-level lab sources

Output table name:
- `aki_labs_obs_6h`

Expected row grain:
- one row per stay_id

Priority lab variables:
- creatinine
- BUN
- bicarbonate
- potassium
- sodium
- chloride
- calcium
- glucose
- lactate
- hemoglobin
- hematocrit
- platelets
- WBC

Required aggregations per variable where feasible:
- first
- last
- min
- max
- mean
- count
- optional delta = last - first

Critical temporal rule:
Every included lab event must satisfy:
- event_time >= icu_intime
- event_time <= anchor_time

Implementation guidance:
1. Join through `aki_prediction_anchors` so the time boundary is explicit.
2. Use clear feature names like:
   - `creatinine_last_6h`
   - `bun_max_6h`
3. Prefer CTEs and explicit item/label mappings if needed.
4. Add comments explaining why first-day summary tables are not the main source here unless their timing is guaranteed safe.
5. Keep identifiers needed for joining.

Acceptance criteria:
- One row per stay_id.
- Only observation-window lab events are used.
- Feature names encode variable + aggregation + window.

Output format:
- Show the full SQL file content.
- Then explain the temporal leakage protection in 3-6 sentences.
