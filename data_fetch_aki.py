"""Google Colab entrypoint for the AKI early-prediction BigQuery extraction flow.

Usage in Colab:
1. Upload or clone this repo into the notebook runtime.
2. Edit `PROJECT_ID` and `DATASET_ID` below.
3. Optionally set `RUN_ONLY` to rerun a subset of stages.
4. Run this file to materialize the AKI tables and export the final CSV.
"""

from __future__ import annotations

from pathlib import Path
from typing import Iterable

import pandas as pd
from google.cloud import bigquery
from google.colab import auth
from google.api_core.exceptions import NotFound


# Config block: edit these names in Colab before running.
PROJECT_ID = "your-gcp-project"
DATASET_ID = "your_bigquery_dataset"
SQL_DIR = Path("sql")
OUTPUT_DIR = Path("outputs")
FINAL_EXPORT_CSV = OUTPUT_DIR / "mimic_aki_cohort_raw.csv"
PREVIEW_ROWS = 5

# Leave as None to run the full pipeline.
# Example: RUN_ONLY = ["01_base_cohort.sql", "02_kdigo_labels.sql"]
RUN_ONLY: list[str] | None = None

# Optional debug behavior.
RUN_SANITY_CHECKS_AFTER_MAIN = True
PREVIEW_FINAL_TABLE = True

OUTPUT_DATASET_TABLES = {
    "base_cohort_table": "aki_base_cohort",
    "kdigo_stages_table": "kdigo_stages_aki",
    "aki_onset_table": "aki_onset",
    "prediction_anchors_table": "aki_prediction_anchors",
    "static_features_table": "aki_static_features",
    "labs_features_table": "aki_labs_obs_6h",
    "vitals_features_table": "aki_vitals_obs_6h",
    "urine_features_table": "aki_urine_obs_6h",
    "comorbidities_table": "aki_comorbidities",
    "final_dataset_table": "mimic_aki_cohort_raw",
}

MAIN_SQL_STAGES = [
    "01_base_cohort.sql",
    "02_kdigo_labels.sql",
    "03_aki_onset.sql",
    "04_prediction_anchors.sql",
    "05_static_features.sql",
    "06_labs_obs_6h.sql",
    "07_vitals_obs_6h.sql",
    "08_urine_obs_6h.sql",
    "09_comorbidities.sql",
    "10_final_aki_dataset.sql",
]
SANITY_CHECKS_SQL = "99_sanity_checks.sql"
STAGE_TO_TABLE_KEY = {
    "01_base_cohort.sql": "base_cohort_table",
    "02_kdigo_labels.sql": "kdigo_stages_table",
    "03_aki_onset.sql": "aki_onset_table",
    "04_prediction_anchors.sql": "prediction_anchors_table",
    "05_static_features.sql": "static_features_table",
    "06_labs_obs_6h.sql": "labs_features_table",
    "07_vitals_obs_6h.sql": "vitals_features_table",
    "08_urine_obs_6h.sql": "urine_features_table",
    "09_comorbidities.sql": "comorbidities_table",
    "10_final_aki_dataset.sql": "final_dataset_table",
}


def read_sql_file(sql_dir: Path, file_name: str) -> str:
    """Load a SQL file from disk."""
    sql_path = sql_dir / file_name
    return sql_path.read_text(encoding="utf-8")


def render_stage_sql(raw_sql: str, replacements: dict[str, str]) -> str:
    """Fill SQL placeholders such as project, dataset, and output table names."""
    return raw_sql.format(**replacements)


def iter_stage_sql(stage_names: list[str]) -> Iterable[tuple[str, str]]:
    """Yield `(file_name, rendered_sql)` in stage order."""
    replacements = {
        "project_id": PROJECT_ID,
        "dataset_id": DATASET_ID,
        **OUTPUT_DATASET_TABLES,
    }
    for file_name in stage_names:
        raw_sql = read_sql_file(SQL_DIR, file_name)
        yield file_name, render_stage_sql(raw_sql, replacements)


def stage_selected(file_name: str) -> bool:
    """Return True when a stage should run under the current filter."""
    if not RUN_ONLY:
        return True
    return file_name in RUN_ONLY or file_name.replace(".sql", "") in RUN_ONLY


def run_query(client: bigquery.Client, sql_query: str) -> bigquery.table.RowIterator:
    """Execute SQL and wait for completion."""
    query_job = client.query(sql_query)
    result = query_job.result()
    return result


def fetch_row_count(client: bigquery.Client, table_key: str) -> int:
    """Return the row count for a materialized output table."""
    table_name = OUTPUT_DATASET_TABLES[table_key]
    count_sql = f"""
    SELECT COUNT(*) AS row_count
    FROM `{PROJECT_ID}.{DATASET_ID}.{table_name}`
    """
    row = next(run_query(client, count_sql))
    return int(row["row_count"])


def table_exists(client: bigquery.Client, table_key: str) -> bool:
    """Return True when the configured table is available in BigQuery."""
    table_name = OUTPUT_DATASET_TABLES[table_key]
    try:
        client.get_table(f"{PROJECT_ID}.{DATASET_ID}.{table_name}")
        return True
    except NotFound:
        return False


def log_stage_row_count(client: bigquery.Client, file_name: str) -> None:
    """Print a simple row-count audit after a materialization stage finishes."""
    table_key = STAGE_TO_TABLE_KEY.get(file_name)
    if table_key is None:
        return
    row_count = fetch_row_count(client, table_key)
    table_name = OUTPUT_DATASET_TABLES[table_key]
    print(f"[done] {file_name} -> {table_name} ({row_count:,} rows)")


def split_sql_blocks(sql_text: str) -> list[str]:
    """Split a multi-query SQL file into standalone blocks."""
    blocks = []
    for block in sql_text.split(";"):
        cleaned = block.strip()
        if cleaned:
            blocks.append(cleaned)
    return blocks


def run_sanity_checks(client: bigquery.Client) -> None:
    """Run sanity-check query blocks and print small previews."""
    raw_sql = read_sql_file(SQL_DIR, SANITY_CHECKS_SQL)
    rendered_sql = render_stage_sql(
        raw_sql,
        {"project_id": PROJECT_ID, "dataset_id": DATASET_ID, **OUTPUT_DATASET_TABLES},
    )
    for idx, block in enumerate(split_sql_blocks(rendered_sql), start=1):
        print(f"[sanity] Running block {idx}")
        preview_df = client.query(block).to_dataframe()
        print(preview_df.head(PREVIEW_ROWS))


def export_final_table(client: bigquery.Client) -> pd.DataFrame:
    """Download the final modeled table and save it as CSV inside the Colab runtime."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    final_table_name = OUTPUT_DATASET_TABLES["final_dataset_table"]
    export_sql = f"""
    SELECT *
    FROM `{PROJECT_ID}.{DATASET_ID}.{final_table_name}`
    ORDER BY stay_id
    """
    final_df = client.query(export_sql).to_dataframe()
    final_df.to_csv(FINAL_EXPORT_CSV, index=False)
    print(f"[export] Wrote {FINAL_EXPORT_CSV} with {len(final_df):,} rows")
    return final_df


def main() -> None:
    """Run the AKI extraction stages in order."""
    auth.authenticate_user()
    client = bigquery.Client(project=PROJECT_ID)
    selected_stages = [stage for stage in MAIN_SQL_STAGES if stage_selected(stage)]

    if not selected_stages:
        raise ValueError("RUN_ONLY did not match any main SQL stage.")

    print(f"[config] project_id={PROJECT_ID}")
    print(f"[config] dataset_id={DATASET_ID}")
    print(f"[config] sql_dir={SQL_DIR}")
    print(f"[config] output_dir={OUTPUT_DIR}")
    print(f"[config] selected_stages={selected_stages}")

    for file_name, sql_query in iter_stage_sql(selected_stages):
        print(f"[start] {file_name}")
        run_query(client, sql_query)
        log_stage_row_count(client, file_name)

    if RUN_SANITY_CHECKS_AFTER_MAIN:
        run_sanity_checks(client)

    if "10_final_aki_dataset.sql" in selected_stages or table_exists(client, "final_dataset_table"):
        final_df = export_final_table(client)
        if PREVIEW_FINAL_TABLE:
            print("[preview] Final dataset sample")
            print(final_df.head(PREVIEW_ROWS))
    else:
        print("[skip] Final dataset export skipped because the final table was not built in this run.")


if __name__ == "__main__":
    main()
