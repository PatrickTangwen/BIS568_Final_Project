You are creating the cleaning notebook for the AKI early-prediction pipeline.


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
Create `notebook/aki_data_cleaning.ipynb`.

This notebook is intended to be run by the user in Google Colab after `mimic_aki_cohort_raw.csv` has been exported.

Notebook responsibilities:
1. Load the raw CSV.
2. Display shape and column summary.
3. Inspect missingness.
4. Separate identifiers, timing columns, target, and candidate features.
5. Remove obviously unusable columns.
6. Preserve identifiers needed for subject-level splitting later.
7. Save a cleaned dataset, e.g.:
   - `outputs/mimic_aki_cohort_cleaned.csv`

Strong requirements:
- Do not create leakage by using post-anchor information.
- Do not redefine the target.
- Do not accidentally drop subject_id.
- Add markdown cells that explain the purpose of each stage.

Suggested notebook sections:
- Setup and imports
- Load raw dataset
- Basic inspection
- Missingness review
- Column grouping
- Leakage-sensitive columns review
- Cleaning decisions
- Export cleaned dataset

Helpful extras:
- a simple table of percent missing by column
- a brief data dictionary export if easy
- explicit note that final model split must be by subject_id

Acceptance criteria:
- The notebook is readable in Colab.
- It produces a cleaned CSV.
- It documents cleaning decisions with markdown, not just code.

Output format:
- Provide the notebook content in a practical form for the repo.
- If you choose to provide it as JSON notebook structure, keep it valid.
- If you choose a script-style notebook template, make it easy to convert to `.ipynb`.
