You are implementing the SQL that collapses AKI stage timeline into one onset record per ICU stay.


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
Implement `sql/03_aki_onset.sql`.

Input:
- `kdigo_stages_aki`

Output table name:
- `aki_onset`

Expected columns:
- stay_id
- aki_onset_time
- aki_onset_stage
- aki_stage_max
- has_aki_anytime

Logic requirements:
1. AKI onset is the earliest charttime where `aki_stage_smoothed >= 1`.
2. `aki_stage_max` is the maximum AKI stage observed during the stay.
3. Stays with no AKI should still appear if practical, with:
   - NULL onset time
   - `has_aki_anytime = 0`
4. Add comments explaining how null/no-event stays are handled.

Implementation guidance:
- Keep this file simple and easy to audit.
- Prefer CTEs over nested unreadable subqueries.
- If you use a left join back to the base cohort so non-AKI stays are preserved, comment why.

Acceptance criteria:
- Exactly one row per stay_id.
- Onset and max-stage logic are explicit.
- The output is ready for the prediction-anchor stage.

Output format:
- Show the full SQL file content.
- Then briefly explain the null-handling and one-row-per-stay logic.
