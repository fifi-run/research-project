
#38
library(tidyverse)

library(dplyr)
library(tidyr)
library(ggplot2)
library(readr)
library(MLmetrics)

# 1. Load Data
labels <- read_tsv("labels.tsv")
valuesml <- read_tsv("ValuesML_sentence_38.tsv")
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
  "Values_AC" = c("Achievement attained", "Achievement constrained", "Face attained", "Face constrained"),
  "Values_PO" = c("Power: dominance attained", "Power: dominance constrained",
                  "Power: resources attained", "Power: resources constrained"),
  "Values_SE" = c("Security: personal attained", "Security: personal constrained",
                  "Security: societal attained", "Security: societal constrained"),
  "Values_TR" = c("Tradition attained", "Tradition constrained", "Humility attained", "Humility constrained"),
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
  for (pvd_col in names(pvd_mapping)) {
    if (label %in% pvd_mapping[[pvd_col]]) {
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

# 10. 额外指标计算函数
macro_metrics <- function(true, pred) {
  precision <- mapply(function(t, p) Precision(t, p, positive = "1"), as.data.frame(true), as.data.frame(pred))
  recall <- mapply(function(t, p) Recall(t, p, positive = "1"), as.data.frame(true), as.data.frame(pred))
  f1 <- mapply(function(t, p) F1_Score(t, p, positive = "1"), as.data.frame(true), as.data.frame(pred))
  acc <- mapply(function(t, p) Accuracy(t, p), as.data.frame(true), as.data.frame(pred))
  
  precision[is.na(precision)] <- 0
  recall[is.na(recall)] <- 0
  f1[is.na(f1)] <- 0
  acc[is.na(acc)] <- 0
  
  data.frame(
    Label = names(f1),
    Precision = precision,
    Recall = recall,
    F1 = f1,
    Accuracy = acc
  ) %>%
    mutate(across(-Label, round, 3))
}

metrics_valuesml <- macro_metrics(labels_bin, valuesml_bin)
metrics_pvd <- macro_metrics(labels_bin, pvd_bin)

# 11. 添加宏平均行
macro_row_valuesml <- data.frame(
  Label = "Macro Avg.",
  t(colMeans(metrics_valuesml[,-1]))
)
macro_row_pvd <- data.frame(
  Label = "Macro Avg.",
  t(colMeans(metrics_pvd[,-1]))
)

metrics_valuesml <- bind_rows(metrics_valuesml, macro_row_valuesml)
metrics_pvd <- bind_rows(metrics_pvd, macro_row_pvd)

# 12. 合并两模型结果以便可视化
comparison <- full_join(
  metrics_valuesml %>% rename_with(~paste0(.x, "_ValuesML"), -Label),
  metrics_pvd %>% rename_with(~paste0(.x, "_PVD"), -Label),
  by = "Label"
)

# 13. 可视化：单标签维度对比（按 F1 展示）
comparison %>%
  filter(Label != "Macro Avg.") %>%
  select(Label, F1_ValuesML, F1_PVD) %>%
  pivot_longer(cols = -Label, names_to = "Model", values_to = "F1_Score") %>%
  ggplot(aes(x = reorder(Label, -F1_Score), y = F1_Score, fill = Model)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  labs(title = "Per-Label F1 Score Comparison", x = "Label", y = "F1 Score") +
  theme_minimal(base_size = 9) +
  theme(
    axis.text.y = element_text(size = 7),
    plot.title = element_text(size = 11, face = "bold"),
    legend.title = element_blank(),
    legend.text = element_text(size = 8)
  )

# 14. 可视化：整体宏平均指标对比
comparison %>%
  filter(Label == "Macro Avg.") %>%
  pivot_longer(cols = -Label, names_to = "Metric_Model", values_to = "Score") %>%
  separate(Metric_Model, into = c("Metric", "Model"), sep = "_") %>%
  ggplot(aes(x = Metric, y = Score, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_text(aes(label = round(Score, 3)), 
            position = position_dodge(width = 0.9), 
            vjust = -0.3, size = 4) +
  labs(title = "Macro Average Comparison", y = "Score", x = "Metric") +
  theme_minimal(base_size = 10) +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.title = element_blank()
  )

overall_scores %>%
  pivot_longer(cols = -Model, names_to = "Metric", values_to = "Score") %>%
  ggplot(aes(x = Metric, y = Score, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_text(aes(label = round(Score, 3)), 
            position = position_dodge(width = 0.9), 
            vjust = -0.3, size = 4) +
  labs(title = "Overall Performance Comparison (Macro Avg.)",
       y = "Score", x = "Metric") +
  scale_y_continuous(limits = c(0, 1)) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top")
# 15. 保存 CSV 输出
write_csv(comparison, "1.38_sentence_comparison_metrics.csv")

write_csv(metrics_pvd, "38_sentence_pvd01_metrics.csv")

