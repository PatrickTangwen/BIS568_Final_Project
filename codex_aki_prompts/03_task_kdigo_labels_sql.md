You are implementing the AKI stage timeline SQL for an AKI early-prediction pipeline.


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
Implement `sql/02_kdigo_labels.sql`.

Goal:
Create a time-resolved AKI stage table that can later be collapsed into onset time.

Use this output table name:
- `kdigo_stages_aki`

Expected columns:
- stay_id
- charttime
- aki_stage
- aki_stage_smoothed
- aki_stage_creat
- aki_stage_uo
- aki_stage_crrt

Important design constraint:
Do not invent a casual AKI definition. Base the implementation structure on the standard MIMIC KDIGO-style logic:
- creatinine-based staging
- urine-output-based staging
- CRRT / RRT-based stage 3 logic if available
- smoothed stage field preserved if feasible

Implementation guidance:
1. Preserve time resolution.
2. Do not collapse to one row per stay here.
3. Keep the SQL modular and well-commented.
4. If the full official logic is too large, it is acceptable to:
   - keep the structure close to official concept SQL
   - add clear TODO markers for exact path adjustments
   - still make the file runnable as a first draft if possible
5. Add comments wherever temporal alignment matters.

Deliverable preference:
- A version that is as close to runnable as possible.
- If source table names may vary by MIMIC version, isolate those assumptions in comments.

Acceptance criteria:
- The output is a time-series AKI stage table keyed by stay_id and charttime.
- The file explicitly separates creatinine, urine-output, and CRRT components.
- The file is suitable input for the onset-collapsing step.

Output format:
- Show the full SQL file content.
- Then provide a short list of assumptions or known follow-up checks.
