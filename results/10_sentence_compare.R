# === 加载依赖 ===
library(tidyverse)
library(MLmetrics)

# === Step 1: 读取数据 ===
labels <- read_tsv("10mapped_labels_sentence.tsv")
valuesml <- read_tsv("10mapped_ValuesML_sentence.tsv")
pvd <- read_csv("PVD_sentence_10.csv")

# === Step 2: 统一 ID 合并 ===
labels <- labels %>% mutate(ID = paste(`Text-ID`, doc_id, sep = "_"))
valuesml <- valuesml %>% mutate(ID = paste(`Text-ID`, doc_id, sep = "_"))
pvd <- pvd %>% mutate(ID = paste(`Text-ID`, `Sentence-ID`, sep = "_"))

# 校验所有 ID 都存在
stopifnot(all(labels$ID %in% valuesml$ID))
stopifnot(all(labels$ID %in% pvd$ID))

# 排序对齐（可选）
labels <- labels %>% arrange(ID)
valuesml <- valuesml %>% arrange(ID)
pvd <- pvd %>% arrange(ID)

# === Step 3: 定义标签列 ===
value_cols <- c("Values_SE", "Values_CO", "Values_TR", "Values_BE", "Values_UN",
                "Values_SD", "Values_ST", "Values_HE", "Values_AC", "Values_PO")

# === Step 4: 定义函数（逐标签 + 宏平均） ===
evaluate_model <- function(preds, truths, label_cols) {
  metrics <- tibble(Label = label_cols)
  
  metrics <- metrics %>%
    rowwise() %>%
    mutate(
      TP = sum(preds[[Label]] == 1 & truths[[Label]] == 1, na.rm = TRUE),
      FP = sum(preds[[Label]] == 1 & truths[[Label]] == 0, na.rm = TRUE),
      FN = sum(preds[[Label]] == 0 & truths[[Label]] == 1, na.rm = TRUE),
      TN = sum(preds[[Label]] == 0 & truths[[Label]] == 0, na.rm = TRUE),
      Precision = if ((TP + FP) > 0) TP / (TP + FP) else 0,
      Recall    = if ((TP + FN) > 0) TP / (TP + FN) else 0,
      F1        = if ((TP + FP + FN) > 0 && (2 * TP) > 0) 2 * TP / (2 * TP + FP + FN) else 0,
      Accuracy  = (TP + TN) / (TP + FP + FN + TN)
    ) %>%
    select(Label, Precision, Recall, F1, Accuracy)
  
  macro_avg <- metrics %>%
    summarise(
      Label = "Macro Avg.",
      Precision = mean(Precision),
      Recall = mean(Recall),
      F1 = mean(F1),
      Accuracy = mean(Accuracy)
    )
  
  bind_rows(metrics, macro_avg)
}

# === Step 5: 计算逐标签指标 ===
metrics_valuesml <- evaluate_model(
  preds = valuesml %>% select(all_of(value_cols)),
  truths = labels %>% select(all_of(value_cols)),
  label_cols = value_cols
)

metrics_pvd <- evaluate_model(
  preds = pvd %>% select(all_of(value_cols)),
  truths = labels %>% select(all_of(value_cols)),
  label_cols = value_cols
)

# === Step 6: 合并对比表格并保存 ===
# 保证每个 Label 只有一行
metrics_valuesml_clean <- metrics_valuesml %>%
  group_by(Label) %>%
  slice(1) %>%  # 若有重复，仅取第一行
  ungroup()

metrics_pvd_clean <- metrics_pvd %>%
  group_by(Label) %>%
  slice(1) %>%
  ungroup()

# 再进行合并
comparison <- metrics_valuesml_clean %>%
  rename_with(~ paste0("ValuesML_", .), -Label) %>%
  left_join(metrics_pvd_clean %>% rename_with(~ paste0("PVD_", .), -Label), by = "Label")


print(comparison, n = Inf)
write_csv(comparison, "model_comparison_metrics.csv")

# === Step 7: 可视化每个标签的指标 ===
comparison %>%
  filter(Label != "Macro Avg.") %>%
  pivot_longer(cols = -Label, names_to = "Metric_Model", values_to = "Value") %>%
  separate(Metric_Model, into = c("Model", "Metric"), sep = "_") %>%
  ggplot(aes(x = Label, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap(~ Metric, scales = "free_y") +
  coord_flip() +
  labs(title = "Model Comparison (Per Value)", y = "Score", x = "Value Label") +
  theme_minimal()

# === Step 8: 总体指标函数 ===
evaluate_model_overall <- function(preds, truths, model_name = "Model") {
  preds_mat <- as.matrix(preds)
  truths_mat <- as.matrix(truths)
  
  TP <- sum(preds_mat == 1 & truths_mat == 1, na.rm = TRUE)
  FP <- sum(preds_mat == 1 & truths_mat == 0, na.rm = TRUE)
  FN <- sum(preds_mat == 0 & truths_mat == 1, na.rm = TRUE)
  TN <- sum(preds_mat == 0 & truths_mat == 0, na.rm = TRUE)
  
  Precision <- if ((TP + FP) > 0) TP / (TP + FP) else 0
  Recall    <- if ((TP + FN) > 0) TP / (TP + FN) else 0
  F1        <- if ((TP + FP + FN) > 0) 2 * TP / (2 * TP + FP + FN) else 0
  Accuracy  <- (TP + TN) / (TP + FP + FN + TN)
  
  tibble(
    Model = model_name,
    Precision = Precision,
    Recall = Recall,
    F1 = F1,
    Accuracy = Accuracy
  )
}

# === Step 9: 计算整体指标 ===
scores_valuesml <- evaluate_model_overall(
  preds = valuesml %>% select(all_of(value_cols)),
  truths = labels %>% select(all_of(value_cols)),
  model_name = "ValuesML"
)

scores_pvd <- evaluate_model_overall(
  preds = pvd %>% select(all_of(value_cols)),
  truths = labels %>% select(all_of(value_cols)),
  model_name = "PVD"
)

overall_scores <- bind_rows(scores_valuesml, scores_pvd)

# === Step 10: 可视化整体指标 ===
scores_long <- overall_scores %>%
  pivot_longer(cols = c(Precision, Recall, F1, Accuracy),
               names_to = "Metric", values_to = "Score")

ggplot(scores_long, aes(x = Metric, y = Score, fill = Model)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.6) +
  scale_fill_manual(values = c("ValuesML" = "#1f77b4", "PVD" = "#ff7f0e")) +
  labs(title = "Comparison of Overall Performance by Model",
       y = "Score", x = NULL) +
  ylim(0, 1) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top")

# 加上分数标签
ggplot(scores_long, aes(x = Metric, y = Score, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_text(aes(label = round(Score, 3)), 
            position = position_dodge(width = 0.9), 
            vjust = -0.3, size = 3.5) +
  labs(title = "Model Performance Comparison",
       y = "Score", x = "Metric") +
  scale_y_continuous(limits = c(0, 1)) +
  theme_minimal()
