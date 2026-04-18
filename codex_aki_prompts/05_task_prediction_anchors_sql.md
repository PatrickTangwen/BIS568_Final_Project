You are implementing the prediction-anchor SQL for AKI early prediction.


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
Implement `sql/04_prediction_anchors.sql`.

Inputs:
- `aki_base_cohort`
- `aki_onset`

Output table name:
- `aki_prediction_anchors`

MVP task definition:
- observation window: first 6 hours after ICU admission
- prediction horizon: next 24 hours
- target: `future_aki_24h`

Expected columns:
- stay_id
- subject_id
- hadm_id
- icu_intime
- anchor_time
- obs_window_start
- obs_window_end
- pred_window_start
- pred_window_end
- eligible_for_prediction
- future_aki_24h

Required logic:
1. `obs_window_start = icu_intime`
2. `obs_window_end = icu_intime + 6 hours`
3. `anchor_time = obs_window_end`
4. `pred_window_start = anchor_time`
5. `pred_window_end = anchor_time + 24 hours`
6. Exclude or mark ineligible stays where AKI onset is on or before anchor_time.
7. Positive label if AKI onset occurs in `(pred_window_start, pred_window_end]`.

Implementation guidance:
- Make time arithmetic explicit.
- Include a clear column for eligibility.
- Add comments that all later feature queries must respect `event_time <= anchor_time`.
- Keep this file clean because it becomes the temporal contract for downstream feature extraction.

Acceptance criteria:
- The SQL makes the label boundary unambiguous.
- The exclusion / eligibility logic is explicit.
- The resulting table can be joined by stay_id in all later steps.

Output format:
- Show the full SQL file content.
- Then explain the label window in plain language.
