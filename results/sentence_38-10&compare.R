# 读取数据
df <- read.delim("ValuesML_sentence_38.tsv", check.names = FALSE)

# 添加 doc_id（从 Sentence-ID 复制）
df$doc_id <- df$`Sentence-ID`

# 定义每个高阶价值对应的原始列名（可以根据实际需要调整）
value_mapping <- list(
  Values_SE = c("Security: personal attained", "Security: personal constrained", 
                "Security: societal attained", "Security: societal constrained"),
  Values_CO = c("Conformity: rules attained", "Conformity: rules constrained", 
                "Conformity: interpersonal attained", "Conformity: interpersonal constrained"),
  Values_TR = c("Tradition attained", "Tradition constrained", "Humility attained", "Humility constrained"),
  Values_BE = c("Benevolence: caring attained", "Benevolence: caring constrained", 
                "Benevolence: dependability attained", "Benevolence: dependability constrained"),
  Values_UN = c("Universalism: concern attained", "Universalism: concern constrained",
                "Universalism: nature attained", "Universalism: nature constrained",
                "Universalism: tolerance attained", "Universalism: tolerance constrained"),
  Values_SD = c("Self-direction: thought attained", "Self-direction: thought constrained",
                "Self-direction: action attained", "Self-direction: action constrained"),
  Values_ST = c("Stimulation attained", "Stimulation constrained"),
  Values_HE = c("Hedonism attained", "Hedonism constrained"),
  Values_AC = c("Achievement attained", "Achievement constrained", 
                "Face attained", "Face constrained"),
  Values_PO = c("Power: dominance attained", "Power: dominance constrained",
                "Power: resources attained", "Power: resources constrained"),
  Text_ID = "Text-ID"  # 保留原始 ID
)

# 生成新数据框
result <- df[, c("Text-ID", "doc_id")]

# 为每个高阶价值生成一列，值为 1 或 0
for (value_name in names(value_mapping)[1:10]) {
  cols <- value_mapping[[value_name]]
  result[[value_name]] <- as.integer(rowSums(df[, cols]) > 0)
}

# 查看结果
print(head(result))
write.table(result, "10mapped_ValuesML_sentence.tsv", sep = "\t", row.names = FALSE, quote = FALSE)






# 读取数据
df <- read.delim("labels.tsv", check.names = FALSE)

# 添加 doc_id（从 Sentence-ID 复制）
df$doc_id <- df$`Sentence-ID`

# 定义每个高阶价值对应的原始列名（可以根据实际需要调整）
value_mapping <- list(
  Values_SE = c("Security: personal attained", "Security: personal constrained", 
                "Security: societal attained", "Security: societal constrained"),
  Values_CO = c("Conformity: rules attained", "Conformity: rules constrained", 
                "Conformity: interpersonal attained", "Conformity: interpersonal constrained"),
  Values_TR = c("Tradition attained", "Tradition constrained", "Humility attained", "Humility constrained"),
  Values_BE = c("Benevolence: caring attained", "Benevolence: caring constrained", 
                "Benevolence: dependability attained", "Benevolence: dependability constrained"),
  Values_UN = c("Universalism: concern attained", "Universalism: concern constrained",
                "Universalism: nature attained", "Universalism: nature constrained",
                "Universalism: tolerance attained", "Universalism: tolerance constrained"),
  Values_SD = c("Self-direction: thought attained", "Self-direction: thought constrained",
                "Self-direction: action attained", "Self-direction: action constrained"),
  Values_ST = c("Stimulation attained", "Stimulation constrained"),
  Values_HE = c("Hedonism attained", "Hedonism constrained"),
  Values_AC = c("Achievement attained", "Achievement constrained", 
                "Face attained", "Face constrained"),
  Values_PO = c("Power: dominance attained", "Power: dominance constrained",
                "Power: resources attained", "Power: resources constrained"),
  Text_ID = "Text-ID"  # 保留原始 ID
)

# 生成新数据框
result <- df[, c("Text-ID", "doc_id")]

# 为每个高阶价值生成一列，值为 1 或 0
for (value_name in names(value_mapping)[1:10]) {
  cols <- value_mapping[[value_name]]
  result[[value_name]] <- as.integer(rowSums(df[, cols]) > 0)
}

# 查看结果
print(head(result))
write.table(result, "10mapped_labels_sentence.tsv", sep = "\t", row.names = FALSE, quote = FALSE)











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
# === Step 4: 合并为一个表格用于二值化 ===
data_joined <- labels %>%
  rename_with(~ paste0(., "_label"), all_of(label_cols)) %>%
  bind_cols(
    valuesml %>% select(all_of(label_cols)) %>% rename_with(~ paste0(., "_valuesml")),
    pvd %>% select(all_of(label_cols))  # pvd不重命名，保持原列名
  )

# === Step 5: 二值化函数 ===
to_bin <- function(df, cols) {
  df %>%
    select(all_of(cols)) %>%
    mutate(across(everything(), ~ ifelse(. >= 0.5, 1, 0)))
}

# === Step 6: 应用二值化 ===
labels_bin <- to_bin(data_joined, paste0(label_cols, "_label"))
valuesml_bin <- to_bin(data_joined, paste0(label_cols, "_valuesml"))
pvd_bin <- to_bin(data_joined, label_cols)

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
  preds = pvd_bin %>% select(all_of(value_cols)),
  truths = labels %>% select(all_of(value_cols)),
  label_cols = value_cols
)

# === Step 6: 合并对比表格并保存 ===

# 保证每个 Label 只有一行
# 去重：确保每个 Label 只出现一次
metrics_valuesml_unique <- metrics_valuesml %>%
  distinct(Label, .keep_all = TRUE)

metrics_pvd_unique <- metrics_pvd %>%
  distinct(Label, .keep_all = TRUE)

# 合并
comparison <- metrics_valuesml_unique %>%
  rename_with(~ paste0("ValuesML_", .), -Label) %>%
  left_join(
    metrics_pvd_unique %>% rename_with(~ paste0("PVD_", .), -Label),
    by = "Label"
  )


print(comparison, n = Inf)
write_csv(comparison, "3.10_min-max_sentence_all_comparison_metrics.csv")

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
  preds = pvd_bin %>% select(all_of(value_cols)),
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
