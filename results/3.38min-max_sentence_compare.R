library(readr)
library(dplyr)
library(MLmetrics)

# === Step 1: 读入数据 ===
pred_pvd <- read_csv("pvd_sentence_38_binary.csv")               # PVD 聚合预测
pred_valml <- read_tsv("ValuesML_sentence_38.tsv")                # ValuesML 预测
labels <- read_tsv("labels.tsv")                      # 人工标注标签

# === Step 2: 确定有效标签列 ===
# 1. 去除 Text.ID / Sentence.ID
# 2. 去除 PVD 缺失的 Face/Humility 四列
exclude_cols <- c("Face attained", "Face constrained", "Humility attained", "Humility constrained")
label_cols <- intersect(intersect(colnames(pred_pvd), colnames(pred_valml)), colnames(labels))
label_cols <- setdiff(label_cols, c("Text.ID", "Sentence.ID", exclude_cols))


colnames(labels)
colnames(pred_pvd)
colnames(pred_valml)

# === Step 3: 合并数据 ===
all_data <- labels %>%
  inner_join(pred_pvd, by = c("Text-ID", "Sentence-ID"), suffix = c(".true", ".pvd")) %>%
  inner_join(pred_valml, by = c("Text-ID", "Sentence-ID"), suffix = c("", ".valml"))

# === Step 4: 定义宏平均指标函数 ===
macro_f1 <- function(true_mat, pred_mat) {
  f1s <- numeric(ncol(true_mat))
  for (i in seq_len(ncol(true_mat))) {
    true <- true_mat[, i]
    pred <- pred_mat[, i]
    
    TP <- sum(true == 1 & pred == 1, na.rm = TRUE)
    FP <- sum(true == 0 & pred == 1, na.rm = TRUE)
    FN <- sum(true == 1 & pred == 0, na.rm = TRUE)
    
    precision <- if ((TP + FP) == 0) NA else TP / (TP + FP)
    recall <- if ((TP + FN) == 0) NA else TP / (TP + FN)
    
    f1 <- if (is.na(precision) || is.na(recall) || (precision + recall) == 0) NA else {
      2 * precision * recall / (precision + recall)
    }
    f1s[i] <- f1
  }
  mean(f1s, na.rm = TRUE)
}

macro_precision <- function(true_mat, pred_mat) {
  precisions <- numeric(ncol(true_mat))
  for (i in seq_len(ncol(true_mat))) {
    true <- true_mat[, i]
    pred <- pred_mat[, i]
    TP <- sum(true == 1 & pred == 1, na.rm = TRUE)
    FP <- sum(true == 0 & pred == 1, na.rm = TRUE)
    precisions[i] <- if ((TP + FP) == 0) NA else TP / (TP + FP)
  }
  mean(precisions, na.rm = TRUE)
}

macro_recall <- function(true_mat, pred_mat) {
  recalls <- numeric(ncol(true_mat))
  for (i in seq_len(ncol(true_mat))) {
    true <- true_mat[, i]
    pred <- pred_mat[, i]
    TP <- sum(true == 1 & pred == 1, na.rm = TRUE)
    FN <- sum(true == 1 & pred == 0, na.rm = TRUE)
    recalls[i] <- if ((TP + FN) == 0) NA else TP / (TP + FN)
  }
  mean(recalls, na.rm = TRUE)
}

macro_accuracy <- function(true_mat, pred_mat) {
  accs <- numeric(ncol(true_mat))
  for (i in seq_len(ncol(true_mat))) {
    true <- true_mat[, i]
    pred <- pred_mat[, i]
    accs[i] <- mean(true == pred, na.rm = TRUE)
  }
  mean(accs, na.rm = TRUE)
}

# === Step 5: 准备比较矩阵 ===

# 1. 原始标签列（可能包含 PVD 未覆盖的标签）
label_cols_all <- setdiff(colnames(labels), c("Text-ID", "Sentence-ID"))

# 2. 找出哪些标签是共同存在于 labels 和 pvd_soft_38 中的
common_label_cols <- intersect(
  intersect(label_cols_all, paste0(colnames(pvd_pred_38)[-(1:2)])),  # PVD 的预测标签
  colnames(pred_valml)[-(1:2)]  # ValuesML 的预测标签
)

# 3. 提取对应标签的矩阵（.true / .pvd / 无后缀）
true_mat <- all_data %>% select(all_of(paste0(common_label_cols, ".true"))) %>% as.matrix()
pvd_mat  <- all_data %>% select(all_of(paste0(common_label_cols, ".pvd"))) %>% as.matrix()
valml_mat <- all_data %>% select(all_of(common_label_cols)) %>% as.matrix()  # 无后缀即 ValuesML



colSums(true_mat)
colSums(pvd_mat)
colSums(valml_mat)
summary(true_mat)
summary(pvd_mat)
summary(valml_mat)
colnames(all_data)


# === Step 6: 输出对比指标 ===
cat("=== PVD 模型指标 ===\n")
cat("Macro-F1:", macro_f1(true_mat, pvd_mat), "\n")
cat("Macro-Precision:", macro_precision(true_mat, pvd_mat), "\n")
cat("Macro-Recall:", macro_recall(true_mat, pvd_mat), "\n\n")

cat("=== ValuesML 模型指标 ===\n")
cat("Macro-F1:", macro_f1(true_mat, valml_mat), "\n")
cat("Macro-Precision:", macro_precision(true_mat, valml_mat), "\n")
cat("Macro-Recall:", macro_recall(true_mat, valml_mat), "\n")



# 找出三方都有的标签列
label_cols_all <- setdiff(colnames(labels), c("Text-ID", "Sentence-ID"))
pvd_cols <- setdiff(colnames(pred_pvd), c("Text-ID", "Sentence-ID"))
valml_cols <- setdiff(colnames(pred_valml), c("Text-ID", "Sentence-ID"))

common_label_cols <- Reduce(intersect, list(label_cols_all, pvd_cols, valml_cols))

# 检查是否都为数字，否则强制转换
labels[common_label_cols] <- lapply(labels[common_label_cols], function(x) as.numeric(as.character(x)))
pred_pvd[common_label_cols] <- lapply(pred_pvd[common_label_cols], function(x) as.numeric(as.character(x)))
pred_valml[common_label_cols] <- lapply(pred_valml[common_label_cols], function(x) as.numeric(as.character(x)))

# 合并
all_data <- labels %>%
  inner_join(pred_pvd, by = c("Text-ID", "Sentence-ID"), suffix = c(".true", ".pvd")) %>%
  inner_join(pred_valml, by = c("Text-ID", "Sentence-ID"), suffix = c("", ".valml"))

# 转换为 matrix
true_mat <- all_data %>% select(all_of(paste0(common_label_cols, ".true"))) %>% as.matrix()
pvd_mat  <- all_data %>% select(all_of(paste0(common_label_cols, ".pvd"))) %>% as.matrix()
valml_mat <- all_data %>% select(all_of(common_label_cols)) %>% as.matrix()

# 输出指标
cat("=== PVD 模型指标 ===\n")
cat("Macro-F1:", macro_f1(true_mat, pvd_mat), "\n")
cat("Macro-Precision:", macro_precision(true_mat, pvd_mat), "\n")
cat("Macro-Recall:", macro_recall(true_mat, pvd_mat), "\n\n")
cat("Macro-Accuracy:", macro_accuracy(true_mat, pvd_mat), "\n\n")

cat("=== ValuesML 模型指标 ===\n")
cat("Macro-F1:", macro_f1(true_mat, valml_mat), "\n")
cat("Macro-Precision:", macro_precision(true_mat, valml_mat), "\n")
cat("Macro-Recall:", macro_recall(true_mat, valml_mat), "\n")
cat("Macro-Accuracy:", macro_accuracy(true_mat, valml_mat), "\n")



library(dplyr)
library(ggplot2)
library(tidyr)

# 逐标签评估函数
per_label_metrics <- function(true_mat, pred_mat, label_names, model_name = "Model") {
  metrics <- data.frame(
    Label = label_names,
    Precision = NA,
    Recall = NA,
    F1 = NA,
    Accuracy = NA,
    Model = model_name
  )
  
  for (i in seq_along(label_names)) {
    true <- true_mat[, i]
    pred <- pred_mat[, i]
    
    TP <- sum(true == 1 & pred == 1, na.rm = TRUE)
    FP <- sum(true == 0 & pred == 1, na.rm = TRUE)
    FN <- sum(true == 1 & pred == 0, na.rm = TRUE)
    TN <- sum(true == 0 & pred == 0, na.rm = TRUE)
    
    precision <- if ((TP + FP) == 0) NA else TP / (TP + FP)
    recall    <- if ((TP + FN) == 0) NA else TP / (TP + FN)
    f1        <- if (is.na(precision) || is.na(recall) || (precision + recall) == 0) NA else {
      2 * precision * recall / (precision + recall)
    }
    acc       <- mean(true == pred, na.rm = TRUE)
    
    metrics$Precision[i] <- precision
    metrics$Recall[i] <- recall
    metrics$F1[i] <- f1
    metrics$Accuracy[i] <- acc
  }
  
  return(metrics)
}

label_cols
cat("True matrix shape: ", dim(true_mat), "\n")
cat("PVD matrix shape: ", dim(pvd_mat), "\n")
cat("ValuesML matrix shape: ", dim(valml_mat), "\n")

# 假设 label_cols 已经是你想比较的列名顺序
pvd_metrics <- per_label_metrics(true_mat, pvd_mat, label_names = common_label_cols, model_name = "PVD")
valml_metrics <- per_label_metrics(true_mat, valml_mat, label_names = common_label_cols, model_name = "ValuesML")

# 合并成一个数据框
all_metrics <- bind_rows(pvd_metrics, valml_metrics)

# 打印表格
print(all_metrics)

write_csv(all_metrics, "3.38_min-max_sentence_comparison_metrics.csv")


ggplot(all_metrics, aes(x = Label, y = F1, fill = Model)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  labs(title = "Per-label F1 Score Comparison", y = "F1 Score", x = "Value Label") +
  theme_minimal(base_size = 9) +
  theme(
    axis.text.y = element_text(size = 7),
    plot.title = element_text(size = 11, face = "bold"),
    legend.title = element_blank(),
    legend.text = element_text(size = 8)
  )


comparison %>%
  filter(Label != "Macro Avg.") %>%
  select(Label, F1, F1_PVD) %>%
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

# 加载所需库
library(ggplot2)
library(tibble)
library(dplyr)

# 指标数据
metrics <- c("Macro-F1", "Macro-Precision", "Macro-Recall", "Macro-Accuracy")
pvd_values <- c(0.064, 0.027, 0.185, 0.883)
valml_values <- c(0.618, 0.604, 0.672, 0.961)

# 创建数据框
df <- tibble(
  Metric = rep(metrics, times = 2),
  Value = c(pvd_values, valml_values),
  Model = rep(c("PVD", "ValuesML"), each = length(metrics))
)

# 绘图

ggplot(df, aes(x = Metric, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_text(aes(label = Value), 
            position = position_dodge(width = 0.9), 
            vjust = -0.3, size = 3.5) +
  labs(title = "Model Performance Comparison",
       y = "Score", x = "Metric") +
  scale_y_continuous(limits = c(0, 1)) +
  theme_minimal()
