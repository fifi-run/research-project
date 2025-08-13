library(tidyverse)
library(caret)
library(MLmetrics)





# 1. Load Data
labels <- read_tsv("merged_labels.tsv")
valuesml <- read_tsv("merged_ValuesML.tsv")
pvd <- read_tsv("merged_PVD0-1.tsv")

# 2. 公共列用于 merge
key_cols <- c("Text-ID", "Sentence-ID")

# 3. 提取标签列（39个值）
label_cols <- setdiff(colnames(labels), key_cols)

# 4. PVD 到 Schwartz-39 映射
pvd_map <- list(
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

# 5. 构造 pvd_39 的标签结构
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
    pvd_39[[label]] <- 0
  }
}

# 6. 合并三份数据
data_joined <- labels %>%
  inner_join(valuesml, by = key_cols, suffix = c("_label", "_valuesml")) %>%
  inner_join(pvd_39, by = key_cols, suffix = c("", "_pvd"))

# 7. 二进制化函数
to_bin <- function(df, cols) {
  df %>%
    select(all_of(cols)) %>%
    mutate(across(everything(), ~ ifelse(. >= 0.5, 1, 0)))
}

labels_bin <- to_bin(data_joined, paste0(label_cols, "_label"))
valuesml_bin <- to_bin(data_joined, paste0(label_cols, "_valuesml"))
pvd_bin <- to_bin(data_joined, label_cols)

# 8. 指标计算函数
macro_metrics <- function(true, pred) {
  df_true <- as.data.frame(true)
  df_pred <- as.data.frame(pred)
  
  per_class <- mapply(function(t, p) {
    list(
      F1 = F1_Score(t, p, positive = "1"),
      Precision = Precision(t, p, positive = "1"),
      Recall = Recall(t, p, positive = "1"),
      Accuracy = Accuracy(t, p)
    )
  }, df_true, df_pred, SIMPLIFY = FALSE)
  
  per_class_df <- bind_rows(per_class)
  per_class_df[is.na(per_class_df)] <- 0
  
  macro <- colMeans(per_class_df)
  list(macro = macro, per_class = per_class_df)
}

# 9. 计算指标
metrics_valuesml <- macro_metrics(labels_bin, valuesml_bin)
metrics_pvd <- macro_metrics(labels_bin, pvd_bin)

# 10. 打印宏平均指标
cat("Macro Metrics:\n")
summary_df <- data.frame(
  Model = c("ValuesML", "PVD"),
  F1 = c(metrics_valuesml$macro["F1"], metrics_pvd$macro["F1"]),
  Precision = c(metrics_valuesml$macro["Precision"], metrics_pvd$macro["Precision"]),
  Recall = c(metrics_valuesml$macro["Recall"], metrics_pvd$macro["Recall"]),
  Accuracy = c(metrics_valuesml$macro["Accuracy"], metrics_pvd$macro["Accuracy"])
)

summary_df[, 2:5] <- round(summary_df[, 2:5], 3)
print(summary_df)


# 11. 可视化对比（条形图）
library(ggplot2)

macro_df <- data.frame(
  Model = rep(c("ValuesML", "PVD"), each = 4),
  Metric = rep(c("F1", "Precision", "Recall", "Accuracy"), 2),
  Score = c(
    metrics_valuesml$macro[c("F1", "Precision", "Recall", "Accuracy")],
    metrics_pvd$macro[c("F1", "Precision", "Recall", "Accuracy")]
  )
)
# 变成长格式，方便 ggplot 使用
long_df <- summary_df %>%
  pivot_longer(cols = -Model, names_to = "Metric", values_to = "Score")

# 绘图
ggplot(long_df, aes(x = Metric, y = Score, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_text(aes(label = Score), 
            position = position_dodge(width = 0.9), 
            vjust = -0.3, size = 3.5) +
  labs(title = "Model Performance Comparison",
       y = "Score", x = "Metric") +
  scale_y_continuous(limits = c(0, 1)) +
  theme_minimal()









# 加载绘图包
library(tidyr)
library(dplyr)

# 添加类别列
f1_per_class <- data.frame(
  Label = label_cols,
  ValuesML = metrics_valuesml$per_class$F1,
  PVD = metrics_pvd$per_class$F1
)

# 转换为长格式
f1_long <- pivot_longer(f1_per_class, cols = -Label, names_to = "Model", values_to = "F1")

# 排序标签
f1_long$Label <- factor(f1_long$Label, levels = label_cols)

# 绘图
ggplot(f1_long, aes(x = Label, y = F1, fill = Model)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  labs(title = "F1 Score per Value Category",
       y = "F1 Score", x = "Value Category") +
  scale_y_continuous(limits = c(0, 1)) +
  theme_minimal()

library(tidyr)
library(dplyr)

# 假设 metrics_valuesml$per_class 和 metrics_pvd$per_class 已计算

# 构建 per-class dataframe
perclass_df <- data.frame(
  Label = label_cols,
  F1_ValuesML = metrics_valuesml$per_class$F1,
  Precision_ValuesML = metrics_valuesml$per_class$Precision,
  Recall_ValuesML = metrics_valuesml$per_class$Recall,
  F1_PVD = metrics_pvd$per_class$F1,
  Precision_PVD = metrics_pvd$per_class$Precision,
  Recall_PVD = metrics_pvd$per_class$Recall
)

# 计算差异
perclass_df <- perclass_df %>%
  mutate(
    F1_diff = F1_ValuesML - F1_PVD,
    Recall_diff = Recall_ValuesML - Recall_PVD,
    Precision_diff = Precision_ValuesML - Precision_PVD
  )

# 输出前10条对比
head(perclass_df %>% arrange(desc(F1_diff)), 38)







install.packages("fmsb")  # 如果未安装
library(fmsb)

# 准备数据
radar_data <- rbind(
  rep(1, 4),  # 最大值
  rep(0, 4),  # 最小值
  summary_df[summary_df$Model == "ValuesML", 2:5],
  summary_df[summary_df$Model == "PVD", 2:5]
)

rownames(radar_data) <- c("Max", "Min", "ValuesML", "PVD")

# 绘图
radarchart(radar_data,
           axistype = 1,
           pcol = c("blue", "red"),
           pfcol = c(rgb(0,0,1,0.3), rgb(1,0,0,0.3)),
           plwd = 2,
           cglcol = "grey",
           cglty = 1,
           axislabcol = "grey",
           vlcex = 0.8,
           title = "Model Radar Chart (Macro Avg)")
legend("topright", legend = c("ValuesML", "PVD"),
       col = c("blue", "red"), lty = 1, bty = "n")

# 比较 recall 得分
recall_per_class <- data.frame(
  Label = label_cols,
  ValuesML = metrics_valuesml$per_class$Recall,
  PVD = metrics_pvd$per_class$Recall
)

recall_diff <- recall_per_class %>%
  mutate(Diff = ValuesML - PVD) %>%
  arrange(desc(Diff))

head(recall_diff, 10)  # Top 10 ValuesML 优势明显的标签












