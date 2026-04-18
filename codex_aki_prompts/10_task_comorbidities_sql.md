You are implementing comorbidity-flag extraction for the AKI early-prediction pipeline.


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
Implement `sql/09_comorbidities.sql`.

Inputs:
- `aki_base_cohort`
- diagnoses_icd style sources
- optional curated ICD mapping logic

Output table name:
- `aki_comorbidities`

Expected row grain:
- one row per stay_id

Priority flags:
- CKD
- diabetes
- hypertension
- CHF
- liver disease
- sepsis or infection-related context if feasible
- chronic pulmonary disease if you think it adds reasonable baseline context

Requirements:
1. Make the ICD mapping logic transparent and editable.
2. Keep the first version simple and auditable.
3. Preserve stay_id as the join key.
4. Add comments about any assumptions:
   - ICD version handling
   - diagnosis source timing
   - whether hospital-level diagnoses are treated as baseline context

Do not:
- bury complex mapping logic without comments
- include post-anchor event summaries that are not appropriate for baseline context

Acceptance criteria:
- One row per stay_id.
- Comorbidity flags are clearly defined.
- The SQL is easy to revise later.

Output format:
- Show the full SQL file content.
- Then list the implemented flags and note any placeholders.
