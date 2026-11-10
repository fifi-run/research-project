# Cancer Risk Assessment: A Multi-Model Group Project

> **Group coursework — Group 28**

## Overview

This collaborative Introduction to Mathematics project explored a tabular lung-cancer risk-level dataset using modelling families described in the group report: multiclass logistic regression, Bayesian models and Random Forest. The project considered lifestyle, environmental, occupational, genetic and symptom-related variables and examined their associations with a three-level outcome (Low, Medium, High).

The report is a **Group 28** submission. The supplied files do not document individual task allocation, so this portfolio presents the work as a group project and does not imply sole authorship.

## Methods described in the group report

- **Multiclass logistic regression:** reported test accuracy of 83%.
- **Bayesian models:** the report compares Gaussian and multinomial variants, reporting approximately 92% accuracy for the Gaussian model and 58% for the multinomial model.
- **Random Forest:** the report describes feature-importance analysis and reports an F1 score of 1.0.

The report identifies occupational hazards, alcohol use, dust allergy, genetic risk and symptoms as relevant variables, and discusses interactions among environmental/lifestyle variables and symptoms.

## Code supplied with the project

The supplied Jupyter notebook implements exploratory visualisation of the target-class distribution and a correlation matrix; a Random Forest classifier with an 80/20 train-test split and weighted F1 evaluation; feature-importance ranking; and a pruned Decision Tree using cost-complexity pruning and randomized hyperparameter search with 10-fold cross-validation.

The notebook does **not** implement the logistic-regression or Bayesian models described in the report. Those models appear in the group report, but separate executable source files were not present in the supplied project folder.

## Results from the supplied notebook

- Random Forest weighted F1 on the notebook's holdout split: **1.00**.
- Top feature importances in the saved notebook output: Coughing of Blood (0.113), Passive Smoker (0.100), Obesity (0.086), Wheezing (0.075) and Fatigue (0.066).
- The Decision Tree hyperparameter search reports a best cross-validation accuracy of approximately **0.99**. The supplied notebook does not calculate a separate final holdout metric for the selected Decision Tree.

## Interpretation and limitations

These numbers should not be interpreted as evidence of clinically reliable lung-cancer prediction. A perfect holdout F1 on a 1,000-row educational dataset is a reason for further audit, not a reason to claim a deployable model.

- The report describes the dataset as Kaggle-sourced, but the exact dataset URL, version and licence are not recorded in the supplied files. The raw dataset is therefore not redistributed in this repository.
- The data include symptom variables such as coughing of blood, fatigue and shortness of breath. If the target Level was constructed partly from the same or related variables, predictive performance may reflect label construction or target leakage.
- A random train/test split does not establish external validity, population representativeness or calibration.
- Feature importance indicates predictive association within this dataset; it does not establish causal risk factors.
- The group report and supplied notebook are not identical artefacts: the notebook contains Random Forest and Decision Tree code, while the report also describes logistic and Bayesian models.

## Data access

The raw file was named cancer patient data sets.csv in the supplied archive and contains a Patient Id field alongside health-related variables. It is not included here. Before redistribution, confirm the dataset source, licence, de-identification and terms of use. Store any authorised copy at data/cancer_risk_dataset.csv to run the notebook.

## Running the notebook

Install Python packages: numpy, pandas, matplotlib, seaborn, scikit-learn and jupyter. Then open notebooks/cancer_risk_models.ipynb. The notebook expects an authorised copy of the dataset at data/cancer_risk_dataset.csv relative to the project root.

## Citation

Wang, Z. et al. / Group 28 (2024/25). *Integrative Mathematical Modeling for Cancer Risk Assessment*. Introduction to Mathematics group project, Durham University coursework.

The exact list of group-member names and individual contributions was not available in the materials used to prepare this portfolio.
