library(tidyverse)
library(caret)
library(MLmetrics)

# 1. Load Data
labels <- read_tsv("labels.tsv")
valuesml <- read_tsv("test_predictions.tsv")
pvd <- read_csv("PVD_sentence_10.csv")

# 2. 保留公共列（用于 merge）
key_cols <- c("Text-ID", "Sentence-ID")

# 3. 提取 labels 的标签列（39个值）
label_cols <- setdiff(colnames(labels), key_cols)

# 4. 创建 PVD 到 Schwartz-39 的映射
pvd_mapping <- list(
  "Values_SD" = c("Self-direction: thought attained", "Self-direction: thought constrained",
                  "Self-direction: action attained", "Self-direction: action constrained"),
  "Values_ST" = c("Stimulation attained", "Stimulation constrained"),
  "Values_HE" = c("Hedonism attained", "Hedonism constrained"),
  "Values_AC" = c("Achievement attained", "Achievement constrained"),
  "Values_PO" = c("Power: dominance attained", "Power: dominance constrained",
                  "Power: resources attained", "Power: resources constrained"),
  "Values_SE" = c("Security: personal attained", "Security: personal constrained",
                  "Security: societal attained", "Security: societal constrained"),
  "Values_TR" = c("Tradition attained", "Tradition constrained"),
  "Values_CO" = c("Conformity: rules attained", "Conformity: rules constrained",
                  "Conformity: interpersonal attained", "Conformity: interpersonal constrained"),
  "Values_BE" = c("Benevolence: caring attained", "Benevolence: caring constrained",
                  "Benevolence: dependability attained", "Benevolence: dependability constrained"),
  "Values_UN" = c("Universalism: concern attained", "Universalism: concern constrained",
                  "Universalism: nature attained", "Universalism: nature constrained",
                  "Universalism: tolerance attained", "Universalism: tolerance constrained")
)


# 5. 初始化 pvd_39 与 labels 同结构
pvd_39 <- labels[key_cols]
for (label in label_cols) {
  matched <- FALSE
  for (pvd_col in names(pvd_map)) {
    if (label %in% pvd_map[[pvd_col]]) {
      pvd_39[[label]] <- pvd[[pvd_col]]
      matched <- TRUE
      break
    }
  }
  if (!matched) {
    pvd_39[[label]] <- 0  # fallback
  }
}

# 6. 合并三份数据，只保留交集
data_joined <- labels %>%
  inner_join(valuesml, by = key_cols, suffix = c("_label", "_valuesml")) %>%
  inner_join(pvd_39, by = key_cols, suffix = c("", "_pvd"))

# 7. 生成三份二进制矩阵
to_bin <- function(df, cols) {
  df %>%
    select(all_of(cols)) %>%
    mutate(across(everything(), ~ ifelse(. >= 0.5, 1, 0)))
}

labels_bin <- to_bin(data_joined, paste0(label_cols, "_label"))
valuesml_bin <- to_bin(data_joined, paste0(label_cols, "_valuesml"))
pvd_bin <- to_bin(data_joined, label_cols)  # 注意：pvd 列名没有后缀

# 8. F1宏平均分数计算函数
macro_f1 <- function(true, pred) {
  f1s <- mapply(function(t, p) {
    F1_Score(t, p, positive = "1")
  }, as.data.frame(true), as.data.frame(pred), SIMPLIFY = TRUE, USE.NAMES = TRUE)
  f1s[is.na(f1s)] <- 0
  list(macro = mean(f1s), per_class = f1s)
}

f1_valuesml <- macro_f1(labels_bin, valuesml_bin)


cat("labels_bin columns:", ncol(labels_bin), "\n")
cat("pvd_bin columns:", ncol(pvd_bin), "\n")

cat("Labels colnames:\n")
print(colnames(labels_bin)[1:5])  # 只打印前5列
cat("PVD colnames:\n")
print(colnames(pvd_bin)[1:5])



f1_pvd <- macro_f1(labels_bin, pvd_bin)

# 9. 输出结果
cat("Macro F1 Scores:\n")
cat(sprintf("ValuesML vs. Human Labels: %.3f\n", f1_valuesml$macro))
cat(sprintf("PVD Dictionary vs. Human Labels: %.3f\n", f1_pvd$macro))





