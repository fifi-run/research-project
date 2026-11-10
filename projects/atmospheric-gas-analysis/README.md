# Atmospheric Gas Data Analysis: Missing Data, PCA and Clustering

## Overview

This project analyses a monthly atmospheric-gas dataset containing carbon monoxide (CO), carbon dioxide (CO2), methane, nitrous oxide and CFC-11 measurements. The submitted report describes observations spanning 2000–2019 and focuses on data quality, missing-value handling, dimensionality reduction and unsupervised clustering.

Although the observations are dated, the supplied analysis does **not** implement a time-series forecasting model or explicitly model temporal autocorrelation. It is best described as exploratory multivariate statistical analysis.

## Research workflow

1. **Exploratory analysis:** inspect types, distributions, pairwise correlations and outliers.
2. **Outlier review:** apply Tukey's 1.5-IQR rule and replace flagged numeric observations with missing values for subsequent analysis.
3. **Missingness diagnostics:** inspect patterns and test the MCAR assumption. The report records a p-value of 0.856; this means the test fails to reject MCAR, not that MCAR has been proven.
4. **Imputation:** use Multiple Imputation by Chained Equations (MICE) with predictive mean matching (PMM), generating ten imputed datasets.
5. **Dimensionality reduction:** apply PCA and inspect scree plots, loadings and variable contributions.
6. **Clustering:** compare K-means and hierarchical clustering on PCA coordinates, using three clusters in the reported analysis.

## Findings reported in the coursework

- The supplied data file contains **183 observations** and six columns (Date plus five gas variables).
- The report identifies CO and CO2 as the variables with missing observations.
- Reported MCAR-test p-value: **0.856**.
- MICE configuration: **m = 10**, method = **PMM**.
- The report selects **three clusters**.
- The reported K-means between-cluster sum-of-squares ratio is approximately **75.77%**.

**PCA reporting discrepancy:** the methods section describes retaining two principal components after reaching at least 85% cumulative variance, while the discussion says that two components explain 97%. These statements should be reconciled against the original PCA output before either is quoted as definitive.

## Code and data

- R/atmospheric_gas_analysis.R: curated, project-relative R workflow based on the supplied analysis. It makes the cluster-count choice explicit and uses the objects actually created in the script.
- data/README.md: input data provenance note.

The original MaunaLoa_miss.csv is not included. The supplied archive did not identify its upstream source or redistribution licence. Add an authorised copy at data/MaunaLoa_miss.csv only after confirming that it can be shared.

## Run

From this project directory, install the packages listed below, place the authorised data file in data/, then run source("R/atmospheric_gas_analysis.R").

The script has not been executed end-to-end in this documentation pass because the raw data file is not included and a package lockfile was not supplied.

## R packages

tidyverse, naniar, ggplot2, corrplot, GGally, FactoMineR, factoextra, cluster, mice, VIM, dendextend, and reshape2.

## Methodological cautions

- The supplied workflow uses the first completed MICE dataset for PCA and clustering rather than pooling clustering/PCA results across imputations.
- An MCAR test is a diagnostic and does not prove a missingness mechanism.
- Extreme atmospheric observations may be scientifically meaningful; outlier treatment requires domain validation.
- The PCA variance statements in the report are inconsistent.
- A more complete time-series analysis would model temporal structure explicitly and assess cluster stability across imputed datasets.

## Future work

Potential extensions include explicit temporal modelling, sensitivity analysis across imputation strategies, stability analysis across imputations, and adding external covariates such as seasonality or known atmospheric events.
