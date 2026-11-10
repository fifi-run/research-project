# Lexical Rules or Learned Representations?
## Assessing Dictionary and Machine Learning Models of Human Values in Political Discourse

**Author:** Ziyi Wang  
**Degree:** Master of Data Science, Durham University  
**Project:** Data Science Research Project 24/25  
**Dissertation:** September 2025

[Detailed methodology and implementation notes](docs/METHODOLOGY.md)

---

## Abstract

This project compares two computational approaches to detecting human values in political discourse: the theory-driven Personal Values Dictionary (PVD) and the transformer-based ValuesML model. Grounded in Schwartz's theory of basic human values, the study evaluates how text granularity (sentence versus paragraph) and PVD score binarisation (hard versus soft) affect predictive performance. The comparison uses a common ten-category label space and reports precision, recall, F1-score and accuracy at aggregate and category levels.

The dissertation reports that ValuesML achieves the highest macro-F1 in both sentence- and paragraph-level experiments. Paragraph context substantially improves PVD, consistent with its dependence on lexical coverage. The analysis also illustrates how threshold choice changes the precision–recall balance of dictionary predictions.

## Research question

> How do dictionary-based (PVD) and machine-learning-based (ValuesML) methods compare in their ability to detect human values in political speeches, in terms of performance and applicability?

### Contributions

1. Comparative evaluation of a theory-driven lexical resource and a contextual transformer model.
2. Sentence- and paragraph-level input comparison.
3. Two strategies for converting PVD frequency scores into binary predictions.
4. Harmonisation of ValuesML's fine-grained labels into the ten broad PVD categories.
5. Aggregate and category-level evaluation.

## Conceptual background

| Approach | Principle | Strength | Limitation |
|---|---|---|---|
| PVD | Match words associated with ten Schwartz value categories and derive category scores | Transparent and theory-grounded | Literal lexical matching has limited access to context and implicit meaning |
| ValuesML | Transformer-based contextual prediction over a fine-grained value label space | Can model contextual and semantically varied expressions | Less directly interpretable |

The study evaluates existing tools and their outputs; it does not claim to train a new transformer architecture from scratch.

## Data

The repository includes ValuesCorpus task data under `valueeval24/`, with this visible split structure:

- `training/` and `training-english/`: sentence and label TSV files.
- `validation/` and `validation-english/`: sentence and label TSV files.
- `test/` and `test-english/`: sentence TSV files.
- `sentences.tsv`: an additional sentence file at the data-directory root.

The dissertation states that the experiment uses the English-language subset of the validation split. It reports **14,904 sentence units** and constructs **523 paragraph units** by grouping sentences by `Text_ID` and concatenating them in `Sentence_ID` order.

The task annotation scheme is based on Schwartz's refined values: 19 values distinguished as attained or constrained, resulting in 38 fine-grained labels. The project maps these to ten broad categories for the main comparison.

Data source: [CLEF 2024 Touché / ValuesCorpus data portal](https://webis.de/data.html?q=touche24). Consult the original dataset licence and terms before redistribution. The presence of data files in this repository does not independently establish redistribution rights.

## Methodology

### Experimental dimensions

| Dimension | Conditions |
|---|---|
| Text granularity | Sentence; paragraph |
| PVD binarisation | Hard; soft |
| Compared systems | PVD; ValuesML |
| Common label space | Ten broad value categories |
| Metrics | Precision; recall; F1; accuracy |

This produces six main configurations: ValuesML, PVD-hard and PVD-soft at each of the two text granularities.

### PVD hard binarisation

The strict method converts every non-zero PVD category score to 1 and leaves zero scores as 0. It is transparent, but treats all non-zero matches as equivalent evidence.

### PVD soft scoring and thresholding

The dissertation describes a soft procedure in which PVD category scores are min–max scaled to [0, 1], followed by category-specific threshold selection using an F1-based search. The dissertation specifies thresholds from 0.1 to 0.9 in increments of 0.1.

**Implementation note:** the repository contains multiple exploratory R scripts for PVD normalisation and thresholding. Some scripts perform row-wise min–max scaling and contain alternative threshold-search variants. These should not all be assumed to implement one identical final procedure. See [Implementation notes](docs/METHODOLOGY.md#implementation-notes-and-reproducibility-cautions).

### ValuesML and label harmonisation

ValuesML outputs in the refined 38-label scheme are aggregated into ten broad Schwartz categories. The conceptual mapping documented in the dissertation is:

| Broad PVD category | ValuesML subcategories |
|---|---|
| Self-Direction (`Values_SD`) | Self-direction: thought; self-direction: action |
| Stimulation (`Values_ST`) | Stimulation |
| Hedonism (`Values_HE`) | Hedonism |
| Achievement (`Values_AC`) | Achievement; face |
| Power (`Values_PO`) | Power: dominance; power: resources |
| Security (`Values_SE`) | Security: personal; security: societal |
| Tradition (`Values_TR`) | Tradition; humility |
| Conformity (`Values_CO`) | Conformity: rules; conformity: interpersonal |
| Benevolence (`Values_BE`) | Benevolence: caring; benevolence: dependability |
| Universalism (`Values_UN`) | Universalism: concern; universalism: nature; universalism: tolerance |

The mapping is from fine-grained ValuesML labels to the broad ten-category space. A broad PVD class is not projected back into multiple fine-grained labels.

### Evaluation

Precision measures the proportion of positive predictions that are correct. Recall measures the proportion of reference positives detected. F1 is the harmonic mean of precision and recall. Accuracy is reported but should be interpreted cautiously in sparse multi-label data, where abundant negative decisions can produce high accuracy despite poor positive-label detection.

Macro-averaged metrics weight categories equally. Category-level results help reveal where the systems have different error profiles.

## Main findings

The following table reproduces the dissertation's reported macro results for the ten-category comparison.

| Granularity | Model | Macro-F1 | Precision | Recall | Accuracy |
|---|---|---:|---:|---:|---:|
| Sentence | ValuesML | **0.244** | 0.166 | 0.459 | 0.837 |
| Sentence | PVD-hard | 0.126 | 0.095 | 0.184 | 0.853 |
| Sentence | PVD-soft | 0.152 | 0.118 | 0.216 | 0.863 |
| Paragraph | ValuesML | **0.800** | 0.722 | 0.896 | 0.804 |
| Paragraph | PVD-hard | 0.651 | 0.504 | 0.918 | 0.570 |
| Paragraph | PVD-soft | 0.644 | 0.486 | 0.953 | 0.540 |

### Interpretation

- ValuesML has the highest macro-F1 in both granularity conditions.
- Paragraph input markedly improves PVD, consistent with longer texts providing more opportunities for dictionary terms to occur.
- Sentence-level PVD-soft performs better than PVD-hard on F1 (0.152 versus 0.126).
- Paragraph-level PVD-soft has higher recall than PVD-hard (0.953 versus 0.918), but lower precision and slightly lower F1 (0.644 versus 0.651).
- Accuracy alone is not a reliable summary of positive value detection in this sparse multi-label setting.

### Category-level comparison

The dissertation reports paragraph-level ValuesML category F1 values between 0.79 (Hedonism) and 0.90 (Security), compared with PVD-soft values between 0.22 (Tradition and Hedonism) and 0.63 (Conformity).

Two examples show the different error profiles:

- **Tradition:** ValuesML has recall 1.00 and precision 0.19 (F1 0.32); PVD-soft has precision 0.56 and recall 0.14 (F1 0.22).
- **Hedonism:** ValuesML has precision 0.95 and recall 0.67; PVD-soft has precision 0.33 and recall 0.16.

## Repository structure

This overview is based on files currently present on the `main` branch.

```text
research-project/
├── README.md
├── .gitignore
├── picture/
│   ├── sentence-level comparison plots and metric CSVs
│   ├── paragraph-level comparison plots and metric CSVs
│   └── ten-category and fine-grained comparison outputs
├── results/
│   ├── sentence- and paragraph-level R analysis scripts
│   ├── PVD score and binary-prediction tables
│   ├── mapped ValuesML and reference-label TSV files
│   ├── comparison metric CSV files
│   ├── figures generated during analysis
│   └── merged result/
│       ├── data aggregation scripts
│       ├── label mapping scripts
│       ├── PVD normalisation / thresholding scripts
│       └── model comparison and plotting scripts
└── valueeval24/
    ├── sentences.tsv
    ├── training/ and training-english/
    ├── validation/ and validation-english/
    └── test/ and test-english/
```

### Key analysis scripts

| Script | Observed role from code |
|---|---|
| `results/10_sentence_compare.R` | Align sentence-level reference labels, ValuesML predictions and PVD scores; calculate category and overall metrics; create plots |
| `results/merged result/merged.R` | Aggregate sentence text, labels, PVD outputs and ValuesML outputs by text |
| `results/merged result/10-38.R` | Aggregate fine-grained label columns into ten broad categories |
| `results/merged result/Compare_10map_min-max_paragraph.R` | Compare paragraph-level ten-category ValuesML and PVD predictions |
| `results/merged result/min-max_compareall.R` | Fine-grained comparison workflow and per-label metric functions |
| `results/整体结果对比.R` | Plot results across sentence/paragraph units and ten/38 label configurations |

These descriptions reflect code inspection, not a guaranteed execution order. See the methodology document for implementation cautions.

## Technology

The inspected scripts use **R** and packages including:

- `tidyverse` (including data manipulation and plotting workflows)
- `readr`
- `dplyr`
- `tidyr`
- `ggplot2`
- `MLmetrics`
- `caret` (in some scripts)
- `PRROC` (in some scripts)

The original repository README also identifies Python as part of the technology stack, but the visible file tree is predominantly R scripts and TSV/CSV outputs. A complete Python dependency list and a pinned R package lockfile are not present in the inspected top-level tree.

## Reproducibility

The repository contains analysis scripts and intermediate results, but does not currently provide one verified entry point that runs the full pipeline end-to-end. Several scripts refer to input filenames that are not at the same relative path as the script, and some refer to intermediate files not present in the repository tree.

To inspect the source:

```bash
git clone https://github.com/fifi-run/research-project.git
cd research-project
```

Then inspect each script's input filenames, set its working directory or paths, install the packages it imports, and run scripts independently. There is intentionally no blanket `source()` command: the current scripts use different intermediate filenames and working-directory assumptions.

## Limitations and future work

The dissertation identifies limited language/domain coverage, loss of detail during label aggregation, calibration overfitting risk, the semantic limitations of dictionaries, and untested temporal/cultural variation.

Possible extensions include multilingual and diachronic corpora, an independent held-out test set, semi-supervised dictionary expansion, and hybrid systems combining transparent lexical evidence with contextual language representations.

## References

- Ponizovskiy, V. et al. (2020). Development and validation of the Personal Values Dictionary: A theory-driven tool for investigating references to basic human values in text. *European Journal of Personality*, 34(5), 885–902. https://doi.org/10.1002/per.2294
- Legkas, A. et al. (2024). ValuesML: A large-scale multilingual dataset for human value detection. *Proceedings of ACL 2024*. https://ceur-ws.org/Vol-3740/paper-330.pdf
- Schwartz, S. H. et al. (2012). Refining the theory of basic individual values. *Journal of Personality and Social Psychology*, 103(4), 663–688. https://doi.org/10.1037/a0029393
- ValuesCorpus / CLEF 2024 Touché data portal: https://webis.de/data.html?q=touche24

## Citation

Wang, Z. (2025). *Lexical Rules or Learned Representations? Assessing Dictionary and Machine Learning Models of Human Values in Political Discourse*. Master's dissertation, Master of Data Science, Durham University.

---

**Ziyi Wang** · Durham University · September 2025
