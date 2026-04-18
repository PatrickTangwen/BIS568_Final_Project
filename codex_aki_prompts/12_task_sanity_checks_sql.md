You are implementing a sanity-check SQL file for the AKI early-prediction pipeline.


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
Implement `sql/99_sanity_checks.sql`.

Purpose:
This file should contain debug queries that are easy for the user to run in Google Colab or BigQuery after each major stage.

Include checks for:
1. base cohort row count
2. number of unique subject_id / hadm_id / stay_id
3. first-ICU-stay restriction effect
4. AKI onset prevalence
5. positive-label prevalence in `future_aki_24h`
6. number of excluded or ineligible stays if that metadata is available
7. duplicate stay_id checks in final tables
8. simple missingness / non-null counts for major feature groups
9. optional sample queries for a few positive and negative rows

Requirements:
- Organize the file into clearly labeled sections.
- Each section should be runnable as a standalone query block if copied out.
- Add short comments saying what each check is trying to catch.

Acceptance criteria:
- The file is genuinely useful for debugging.
- Queries are readable and logically grouped.
- It supports manual inspection after Colab runs.

Output format:
- Show the full SQL file content.
- Then explain when the user should run this file during the workflow.
