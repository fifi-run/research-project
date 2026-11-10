# Wine Quality Prediction: LASSO and Random Forest

## Overview

This project uses physicochemical measurements from the UCI Red Wine Quality dataset to predict wine quality scores. The submitted analysis combines a regularised linear regression approach (LASSO) with Random Forest modelling and explores numeric prediction and categorical quality classification.

**Dataset:** 1,599 red-wine observations, 11 physicochemical predictors and a quality score. The source CSV is semicolon-delimited.

## Methods in the supplied analysis

- Exploratory data analysis, summary statistics and correlation visualisation.
- Outlier review using IQR counts followed by domain-informed value filters.
- LASSO regression using glmnet and 10-fold cross-validation to select the penalty parameter.
- Random Forest classification using randomForest, including tuning and feature-importance analysis.
- Classification evaluation using a confusion matrix, accuracy, Kappa and class-level metrics.
- Regression-style evaluation using MSE, RMSE, MAE and R-squared.

## Results reported in the submitted report

| Model / task | Reported result |
|---|---:|
| LASSO regression | RMSE 0.675; MAE 0.537; R-squared 0.370 |
| Random Forest classification | Accuracy 0.942; Kappa 0.910 |
| Random Forest numeric-score comparison (as reported) | RMSE 0.261; MAE 0.0614; R-squared 0.896 |

The report identifies alcohol as the strongest Random Forest feature, followed by sulphates and total sulfur dioxide. It also notes that common quality classes (especially scores 5–7) are predicted more reliably than rare edge classes.

## Important interpretation caveats

- LASSO is fitted as a regression model, while the principal Random Forest result is a classification model. Converting class predictions to numeric scores and comparing RMSE/R-squared with LASSO regression is not a clean like-for-like comparison. Classification metrics and regression metrics should be reported separately.
- The report's table gives an adjusted R-squared value of 8.92777 for LASSO, which is outside the valid range for the usual adjusted R-squared statistic. It is not reproduced as a valid performance measure here.
- The headline classification accuracy should be read alongside per-class recall and the confusion matrix, especially because the report notes weak recognition of rare quality classes.
- The original analysis applies domain-based filters after exploratory IQR analysis; the filters and their impact on the data distribution should be justified.
- A fixed random seed is added in the curated script for repeatability, so exact numerical results may differ from the original coursework run.
- The separate LOSSO.R file is exploratory: it assumes an in-memory object and predicts on the same observations used to fit the model. Its errors are in-sample and must not be described as test performance.

## Code and data

- R/wine_quality_analysis.R: curated project-relative workflow based on the supplied primary R script.
- R/lasso_exploratory_in_sample.R: original exploratory LASSO variant, retained with an explicit in-sample warning.
- data/DATASET_ATTRIBUTION.md: official source and licence details.

The raw red-wine CSV is not committed in this repository update. Obtain it from the UCI record linked below and place it at data/winequality-red.csv.

## Run

Install the imported packages (caret, glmnet, randomForest, ggplot2, dplyr, corrplot, GGally, reshape2) and then run source("R/wine_quality_analysis.R").

## Dataset citation and licence

Cortez, P., Cerdeira, A., Almeida, F., Matos, T., & Reis, J. (2009). *Wine Quality* [Dataset]. UCI Machine Learning Repository. https://doi.org/10.24432/C56S3T

The UCI record identifies the dataset licence as **CC BY 4.0**. Retain attribution when reusing or adapting the data: https://archive.ics.uci.edu/dataset/186/wine+quality.

## Future improvements

Use a stratified, fixed train/validation/test split; compare ordinal classification, regression and ranking objectives separately; avoid domain filters unless justified; tune hyperparameters only inside training folds; report balanced accuracy and per-class precision/recall/F1; and compare LASSO with Random Forest on the same regression target if regression is the research question.
