# Research Methodology and Implementation Notes

## 1. Research question

How do dictionary-based (PVD) and machine-learning-based (ValuesML) methods compare in their ability to detect human values in political speeches, in terms of performance and applicability?

The research evaluates input granularity, PVD binarisation, label harmonisation and model metrics.

## 2. Data and experimental units

The dissertation reports using the English-language validation subset of ValuesCorpus from CLEF 2024 Touché. It reports 14,904 sentence units and 523 paragraph units.

Paragraphs are constructed by grouping sentences under their text identifier and concatenating them in their original sentence order. The annotated scheme consists of 19 refined Schwartz values, each distinguished as attained or constrained (38 labels).

The GitHub repository contains the task splits and labels in `valueeval24/`, while `results/` contains derived data and model outputs.

## 3. Methods

### 3.1 Personal Values Dictionary

PVD is a dictionary-based method grounded in Schwartz's ten basic values. The study evaluates its frequency-based category scores after two binarisation approaches:

- **Hard:** positive if a category score is non-zero; otherwise negative.
- **Soft:** min–max normalisation followed by category-specific thresholding according to F1.

The dissertation describes a grid of thresholds from 0.1 to 0.9 in increments of 0.1.

### 3.2 ValuesML

ValuesML is a transformer-based system for multilingual human-value detection. It produces predictions in a 38-label space (19 values with attained/constrained status). The project aggregates these outputs into ten broad labels for the cross-model comparison.

### 3.3 Label mapping

| Ten-category label | Fine-grained values aggregated |
|---|---|
| Values_SD | Self-direction: thought; self-direction: action |
| Values_ST | Stimulation |
| Values_HE | Hedonism |
| Values_AC | Achievement; face |
| Values_PO | Power: dominance; power: resources |
| Values_SE | Security: personal; security: societal |
| Values_TR | Tradition; humility |
| Values_CO | Conformity: rules; conformity: interpersonal |
| Values_BE | Benevolence: caring; benevolence: dependability |
| Values_UN | Universalism: concern; universalism: nature; universalism: tolerance |

For each broad category, its corresponding ValuesML sub-labels are aggregated to a broad prediction. The mapping is not reversed: a broad category prediction does not identify which specific fine-grained subtype is present.

## 4. Design matrix

| Input granularity | ValuesML | PVD-hard | PVD-soft |
|---|---|---|---|
| Sentence | ✓ | ✓ | ✓ |
| Paragraph | ✓ | ✓ | ✓ |

## 5. Evaluation

Precision, recall, F1-score and accuracy are reported. Macro metrics are computed over the ten broad value categories so that each category contributes equally to the aggregate. Category-level metrics are also used to inspect different model error profiles.

## 6. Reported macro results

| Input | Model | F1 | Precision | Recall | Accuracy |
|---|---|---:|---:|---:|---:|
| Sentence | ValuesML | 0.244 | 0.166 | 0.459 | 0.837 |
| Sentence | PVD-hard | 0.126 | 0.095 | 0.184 | 0.853 |
| Sentence | PVD-soft | 0.152 | 0.118 | 0.216 | 0.863 |
| Paragraph | ValuesML | 0.800 | 0.722 | 0.896 | 0.804 |
| Paragraph | PVD-hard | 0.651 | 0.504 | 0.918 | 0.570 |
| Paragraph | PVD-soft | 0.644 | 0.486 | 0.953 | 0.540 |

ValuesML has the strongest macro-F1 in both settings. Paragraph-level text provides a particularly large benefit to PVD. At paragraph level, PVD-soft reaches higher recall than PVD-hard but has lower precision and slightly lower F1.

## 7. Implementation notes and reproducibility cautions

The repository is an evolving research workspace, not yet a single packaged pipeline. The source tree contains several versions of R scripts and intermediate outputs. They should be treated as distinct analysis artefacts rather than interchangeable implementations.

### Observed implementation patterns

- `results/10_sentence_compare.R` loads mapped sentence-level reference labels, ValuesML predictions and PVD scores; checks identifier alignment; calculates per-category and overall metrics; and creates plots.
- `results/merged result/merged.R` aggregates sentences, labels and predictions by `Text-ID`.
- `results/merged result/10-38.R` aggregates fine-grained label columns into ten broad value categories.
- `results/merged result/Compare_10map_min-max_paragraph.R` compares ten-category paragraph labels and predictions.
- `results/merged result/min-max_compareall.R` contains a fine-grained comparison workflow and per-label metric functions.
- `results/整体结果对比.R` builds a plotting data frame for comparisons across sentence/paragraph units and ten/38 label configurations.

### Cautions discovered from the source

1. **Working-directory assumptions:** scripts load files by bare filenames (for example `read_tsv("10mapped_labels_sentence.tsv")`). A user must run them from a directory where those files resolve or edit the paths.
2. **Intermediate files:** some scripts read derived files that are not present in the checked-in tree or exist under a different subdirectory. The repository does not yet include a fully specified pipeline order.
3. **Alternative soft-score code:** scripts contain multiple normalisation/thresholding variants. One script uses row-wise normalisation across categories, while the dissertation's textual description discusses category-wise scaling across samples. Those are not mathematically equivalent. The exact final analysis variant should be identified before claiming the README's formula and every script are identical.
4. **Threshold selection:** code variants calculate thresholds using labelled observations in the same data object used in downstream evaluation. Where the same records are used both for tuning and scoring, estimates may be optimistic. Independent development and test data would be preferable.
5. **Mapping discrepancy:** the dissertation's ten-category mapping includes Face under Achievement and Humility under Tradition. At least one visible code mapping (`results/final.R`) does not include these subcategories in its PVD-to-fine-grained mapping. Confirm the definitive mapping used for the final reported results.
6. **Potential code hygiene issues:** `results/final.R` references `df` in expressions where the loaded data object is named differently; it should not be presented as a verified executable entry point without correction.
7. **File naming and version drift:** several files contain misspellings or inconsistent suffixes (`snetence`, `parahraph`, and varying `Text.ID` / `Text-ID` conventions). These are relevant when attempting to rerun scripts.

### Reproduction guidance

At present, a fully reproducible one-command execution cannot be asserted from the checked-in files. A cautious inspection workflow is:

```bash
git clone https://github.com/fifi-run/research-project.git
cd research-project
```

Then inspect each script's inputs, set its working directory and run it independently after installing its imported packages. A future cleanup should introduce a single documented pipeline, consistent relative paths, a package lockfile, explicit configuration, and a separation between threshold calibration and final evaluation.

## 8. Limitations and extensions

The dissertation identifies limited language/domain coverage, loss of detail during label aggregation, calibration overfitting risk, the semantic limitations of dictionaries, and untested temporal/cultural variation.

Possible extensions include:
- independent hold-out evaluation;
- multilingual and cross-domain validation;
- diachronic analysis;
- semi-supervised lexicon expansion;
- hybrid dictionary–transformer approaches.
