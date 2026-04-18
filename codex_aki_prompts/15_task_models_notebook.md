You are creating the baseline modeling notebook for the AKI early-prediction pipeline.


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
Create `notebook/aki_models.ipynb`.

This notebook is intended to be run by the user in Google Colab after the cleaned dataset is ready.

Target:
- `future_aki_24h`

Required modeling rule:
- split by `subject_id`, not by row

Notebook responsibilities:
1. Load cleaned dataset.
2. Define target, identifier columns, time columns, and leakage-sensitive columns.
3. Build a subject-level split.
4. Train simple baseline models, at minimum:
   - logistic regression
   - random forest
5. If feasible, optionally add XGBoost or LightGBM behind a safe import block.
6. Report:
   - AUROC
   - AUPRC
   - classification report or threshold-based metrics
7. Print dataset shape, class balance, and split sizes.

Strong requirements:
- Do not use identifiers as features.
- Do not use row-level random split.
- Do not include full-stay leakage columns such as LOS summaries if they imply future information.
- Add markdown cells explaining the split and leakage logic.

Suggested notebook sections:
- Setup and imports
- Load cleaned dataset
- Target and feature column review
- Subject-level train/test split
- Preprocessing pipeline
- Logistic regression baseline
- Random forest baseline
- Metrics summary

Acceptance criteria:
- The notebook is Colab-friendly.
- It clearly preserves subject-level independence.
- It runs at least one end-to-end baseline without fragile hidden assumptions.

Output format:
- Provide the notebook content in a practical repo-ready form.
- Keep it readable and easy for the user to modify later.
