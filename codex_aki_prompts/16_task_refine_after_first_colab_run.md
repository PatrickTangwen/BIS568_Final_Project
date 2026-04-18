You are refining the AKI early-prediction pipeline after the first real Google Colab execution.


General requirements for this task:
- Keep the repo style close to the current project.
- Write clear, maintainable code and comments.
- Avoid data leakage across the prediction anchor.
- Make project_id, dataset_id, and output table names configurable.
- Do not hardcode secrets or user-specific paths.
- If a task creates a file that will be run in Colab, add a short usage comment near the top.
- Prefer explicit names and step-by-step logic over clever compact code.
- Unless the task explicitly asks for execution, only generate or edit files; do not claim the code was run.


Context:
The user has already generated the AKI SQL files, `data_fetch_aki.py`, and the initial notebooks, and has now run the extraction pipeline in Colab at least once.

Objective:
Review the current implementation and make pragmatic improvements based on likely first-run issues.

Your task:
1. Inspect the generated SQL files and Python script.
2. Tighten comments, logging, and config usability.
3. Reduce any obvious friction in rerunning subsets of stages.
4. Improve error messages and row-count prints.
5. Add or refine sanity checks if they are too weak.
6. Clean up naming inconsistencies across:
   - SQL output table names
   - CSV output names
   - feature column conventions
7. If you find likely leakage risk, add comments and safe guards.
8. If you find likely duplicate-risk joins, make the protection more explicit.
9. Do not radically redesign the entire pipeline unless absolutely necessary.

Specific deliverables:
- improved `data_fetch_aki.py`
- any refined SQL files that clearly need follow-up
- minor notebook fixes if they remove obvious friction
- a concise change summary

Acceptance criteria:
- The pipeline is easier to rerun in Colab.
- Debugging output is clearer.
- Naming and stage ordering are more consistent.
- No unnecessary over-engineering is introduced.

Output format:
- First summarize the likely first-run pain points you addressed.
- Then show the changed file contents or patches.
- End with a short rerun checklist for the user.
