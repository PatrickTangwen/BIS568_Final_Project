# BIS638 Database Group -  Pneumonia Cohort Pipeline

## Overview
This repository contains the complete pipeline for building, cleaning, analyzing, and visualizing a pneumonia-specific patient cohort from the MIMIC-IV database. The project integrates data extraction, preprocessing, statistical modeling, machine learning, and an interactive dashboard for exploratory analysis.

You may access the dashboard at the following link: https://patricktangwen.github.io/BIS638_Database_Group/

## Repository Structure

### Data Extraction & Processing
- **`data_fetch.py`**: A Python script designed for Google Colab to query MIMIC-IV via BigQuery. It extracts patient demographics, ICU stays, lab values, and vital signs, exporting the raw dataset as `mimic_pneumonia_cohort_full.csv`.
- **`pneumonia_doid_icd2.csv`**: A mapping file linking Disease Ontology (DOID) terms to ICD-10-CM codes, used to identify pneumonia cases in the database.
- **`mimic_pneumonia_cohort_full.csv`**: The raw dataset extracted from MIMIC-IV containing the initial cohort (re-generate this to keep data current).
- **`all_columns.txt`**: A reference list of all column names in the extracted dataset.

### Notebooks (Analysis & Modeling)
Located in the `notebook/` directory:
- **`Doid_Data_Fetch.ipynb`**: Handles disease ontology mapping and initial data querying logic from BigQuery.
- **`data_cleaning.ipynb`**: Performs extensive data cleaning, including handling missing values, outlier detection/winsorization, and log-transformation of skewed features. Outputs `cleaned_data.csv`.
- **`cleaned_data.csv`**: The processed, cleaned dataset ready for analysis and modeling.
- **`Bayesian_selection.ipynb`**: Implements a Bayesian hierarchical logistic regression model for probabilistic feature selection. Outputs `pip_table.csv` as feature selection result by posterior inclusion probability.
- **`ML_models.ipynb`**: Trains and evaluates machine learning models (Logistic Regression, Random Forest, XGBoost) to predict hospital mortality.
- **`visualization.ipynb`**: Generates static visualizations (distributions, correlations) for the final report.

### Interactive Dashboard
Located in the `dashboard/` directory. A React-based web application for interactive exploration of the cohort.
- **`src/`**: Source code for the dashboard application (React components, pages, logic).
- **`public/`**: Static assets including the dataset used by the dashboard.
- **`README.md`**: Specific instructions for running and deploying the dashboard.


## Usage Guide
1. **Data Extraction**: Run `data_fetch.py` in Google Colab to generate the raw cohort CSV.
2. **Data Cleaning**: Execute `notebook/data_cleaning.ipynb` to process the raw CSV into `cleaned_data.csv`.
3. **Analysis**: Run `notebook/ML_models.ipynb` and `notebook/Bayesian_selection.ipynb` for predictive modeling.
4. **Dashboard**: Navigate to `dashboard/` and follow its README to launch the interactive visualization tool locally.
