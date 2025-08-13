library(tidyverse)
library(MLmetrics)

# === Step 1: 读取数据 ===
labels <- read_tsv("10mapped_labels_sentence.tsv")
valuesml <- read_tsv("10mapped_ValuesML_snetence.tsv")
pvd <- read_tsv("10mapped_PVD0-1_sentence.tsv")  

# === Step 2: 定义标签列 ===
value_cols <- c("Values_SE", "Values_CO", "Values_TR", "Values_BE", "Values_UN",
                "Values_SD", "Values_ST", "Values_HE", "Values_AC", "Values_PO")

# === Step 3: 确保 ID 对齐（Text-ID 是唯一标识符） ===
stopifnot(all(labels$`Text-ID` == valuesml$`Text-ID`))
stopifnot(all(labels$`Text-ID` == pvd$`Text-ID`))

# === Step 4: 定义指标计算函数（每个标签一个指标） ===
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



# === Step 5: 对两个模型分别计算指标 ===
metrics_valuesml <- evaluate_model(valuesml[, value_cols], labels[, value_cols], value_cols)
metrics_pvd <- evaluate_model(pvd[, value_cols], labels[, value_cols], value_cols)

# === Step 6: 合并对比表格 ===
comparison <- metrics_valuesml %>%
  rename_with(~ paste0("ValuesML_", .), -Label) %>%
  left_join(metrics_pvd %>% rename_with(~ paste0("PVD_", .), -Label), by = "Label")

print(comparison, n = Inf)  # 显示所有行
write_csv(comparison, "model_comparison_metrics.csv")

library(ggplot2)

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











library(tidyverse)

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

# label_cols 是你的标签列名，例如:
label_cols <- c("Values_SE", "Values_CO", "Values_TR", "Values_BE", "Values_UN",
                "Values_SD", "Values_ST", "Values_HE", "Values_AC", "Values_PO")

# 两组模型预测值分别命名为 valuesml_preds 和 pvd_preds，真实标签是 labels
scores_valuesml <- evaluate_model_overall(
  preds = valuesml[, label_cols],
  truths = labels[, label_cols],
  model_name = "ValuesML"
)

scores_pvd <- evaluate_model_overall(
  preds = pvd[, label_cols],
  truths = labels[, label_cols],
  model_name = "PVD"
)

# 合并为一个 tibble
overall_scores <- bind_rows(scores_valuesml, scores_pvd)

# 数据整理为长格式以便绘图
scores_long <- overall_scores %>%
  pivot_longer(cols = c(Precision, Recall, F1, Accuracy),
               names_to = "Metric", values_to = "Score")

scores_long
# 使用 ggplot 可视化
library(ggplot2)

ggplot(scores_long, aes(x = Metric, y = Score, fill = Model)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.6) +
  scale_fill_manual(values = c("ValuesML" = "#1f77b4", "PVD" = "#ff7f0e")) +
  labs(title = "Comparison of Overall Performance by Model",
       y = "Score", x = NULL) +
  ylim(0, 1) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top")

ggplot(scores_long, aes(x = Metric, y = Score, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_text(aes(label = round(Score, 3)), 
            position = position_dodge(width = 0.9), 
            vjust = -0.3, size = 3.5) +
  labs(title = "Model Performance Comparison",
       y = "Score", x = "Metric") +
  scale_y_continuous(limits = c(0, 1)) +
  theme_minimal()



# 使用 ggplot 可视化并显示数值标签
ggplot(scores_long, aes(x = Metric, y = Score, fill = Model)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.6) +
  scale_fill_manual(values = c("ValuesML" = "#1f77b4", "PVD" = "#ff7f0e")) +
  labs(title = "Comparison of Overall Performance by Model",
       y = "Score", x = NULL) +
  ylim(0, 1) +  # 限定纵轴范围
  theme_minimal(base_size = 14) +
  theme(legend.position = "top") +
  geom_text(aes(label = round(Score, 3)),  # 显示数值并保留3位小数
            position = position_dodge(width = 0.6), vjust = -0.3, size = 4)










