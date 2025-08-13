library(tidyverse)
library(caret)
library(MLmetrics)

library(tidyverse)
library(PRROC)  # 或 precrec

# 1. 读取原始 PVD 打分（假设已经读取为 dataframe: pvd_scores）
# 示例: pvd_scores <- read.csv("pvd_scores.csv")
# 你应已有这一步，确保包含以下列：
value_cols <- c("Values_SE", "Values_CO", "Values_TR", "Values_BE", "Values_UN",
                "Values_SD", "Values_ST", "Values_HE", "Values_AC", "Values_PO")
pvd_scores <- read.csv("PVD_merged_result.csv")
# 2. 行级 min-max scaling（近似 soft scores）
normalize_row <- function(x) {
  rng <- range(x)
  if (rng[1] == rng[2]) {
    return(rep(0, length(x)))
  } else {
    return((x - rng[1]) / (rng[2] - rng[1]))
  }
}

pvd_soft <- pvd_scores %>%
  select(all_of(value_cols)) %>%
  as.data.frame() %>%
  apply(1, normalize_row) %>%
  t() %>%
  as.data.frame()
colnames(pvd_soft) <- value_cols

# 对每一行进行 min-max 归一化
pvd_soft_norm <- t(apply(pvd_soft, 1, function(x) {
  rng <- range(x, na.rm = TRUE)
  if (rng[1] == rng[2]) {
    rep(0, length(x))  # 若所有值相同，则归一为0
  } else {
    (x - rng[1]) / (rng[2] - rng[1])
  }
}))

# 转回数据框，并保留列名
pvd_soft_norm <- as.data.frame(pvd_soft_norm)
colnames(pvd_soft_norm) <- colnames(pvd_soft)

# 可选：将 Text-ID 和 Sentence-ID 添加回来（若需要）
pvd_soft_norm <- cbind(labels[, key_cols], pvd_soft_norm)


pvd_soft_norm



library(dplyr)
library(purrr)
library(ggplot2)

# 假设你已经有这两个数据框
# pvd_soft_norm：归一化后的 soft score
# binary_labels：真实标签 (0/1)
labels <- read_tsv("10mapped_labels.tsv")




# === Step 3: 定义阈值搜索函数 ===
find_best_threshold <- function(scores, truths, min_threshold = 0.2) {
  df <- data.frame(score = scores, truth = truths)
  df <- df[!is.na(df$truth), ]
  df <- df[order(-df$score), ]
  
  tp <- cumsum(df$truth == 1)
  fp <- cumsum(df$truth == 0)
  fn <- sum(df$truth == 1) - tp
  
  precision <- tp / (tp + fp + 1e-6)
  recall <- tp / (tp + fn + 1e-6)
  f1 <- 2 * precision * recall / (precision + recall + 1e-6)
  
  # 找出满足最小阈值限制的候选项
  valid_indices <- which(df$score >= min_threshold)
  
  if (length(valid_indices) == 0) {
    # 如果所有 score 都小于 min_threshold，返回默认值
    return(list(threshold = min_threshold, f1 = 0))
  }
  
  # 在满足条件的 index 中找最大 f1
  best_idx <- valid_indices[which.max(f1[valid_indices])]
  best_threshold <- df$score[best_idx]
  
  return(list(threshold = best_threshold, f1 = f1[best_idx]))
}


setdiff(colnames(labels)[-(1:2)], colnames(pvd_soft_norm)[-(1:2)])
colnames(labels)
colnames(pvd_soft_norm)

# === Step 4: 为每个标签计算最佳阈值 ===
thresholds <- sapply(common_cols, function(col) {
  scores <- as.numeric(pvd_soft_norm[[col]])
  truths <- as.numeric(labels[[col]])
  if (sum(truths, na.rm = TRUE) == 0) return(NA)  # 没有正例
  find_best_threshold(scores, truths)$threshold
})

# === Step 5: 应用阈值将 soft score 转为 0/1 预测 ===
pvd_soft_norm <- pvd_soft_norm
for (col in names(thresholds)) {
  thr <- thresholds[[col]]
  if (!is.na(thr)) {
    pvd_soft_norm[[col]] <- ifelse(pvd_soft_norm[[col]] >= thr, 1, 0)
  } else {
    pvd_soft_norm[[col]] <- 0  # 若无正例，则全部为 0
  }
}

# === Step 6: 检查输出是否为 0/1 ===
table(unlist(pvd_soft_norm[ , -(1:2)]))  # 应只含 0 和 1

# （可选）保存为 CSV
write.csv(pvd_soft_norm, "pvd_pred_38_binary.csv", row.names = FALSE)














library(tidyverse)
library(caret)
library(MLmetrics)

library(tidyverse)
library(PRROC)  # 或 precrec

# 1. 读取原始 PVD 打分（假设已经读取为 dataframe: pvd_scores）
# 示例: pvd_scores <- read.csv("pvd_scores.csv")
# 你应已有这一步，确保包含以下列：
value_cols <- c("Values_SE", "Values_CO", "Values_TR", "Values_BE", "Values_UN",
                "Values_SD", "Values_ST", "Values_HE", "Values_AC", "Values_PO")
pvd_scores <- read.csv("PVD_merged_result.csv")
# 2. 行级 min-max scaling（近似 soft scores）
normalize_row <- function(x) {
  rng <- range(x)
  if (rng[1] == rng[2]) {
    return(rep(0, length(x)))
  } else {
    return((x - rng[1]) / (rng[2] - rng[1]))
  }
}

pvd_soft <- pvd_scores %>%
  select(all_of(value_cols)) %>%
  as.data.frame() %>%
  apply(1, normalize_row) %>%
  t() %>%
  as.data.frame()
colnames(pvd_soft) <- value_cols

# 对每一行进行 min-max 归一化
pvd_soft_norm <- t(apply(pvd_soft, 1, function(x) {
  rng <- range(x, na.rm = TRUE)
  if (rng[1] == rng[2]) {
    rep(0, length(x))  # 若所有值相同，则归一为0
  } else {
    (x - rng[1]) / (rng[2] - rng[1])
  }
}))

# 转回数据框，并保留列名
pvd_soft_norm <- as.data.frame(pvd_soft_norm)
colnames(pvd_soft_norm) <- colnames(pvd_soft)

# 可选：将 Text-ID 和 Sentence-ID 添加回来（若需要）
pvd_soft_norm <- cbind(labels[, key_cols], pvd_soft_norm)


pvd_soft_norm



library(dplyr)
library(purrr)
library(ggplot2)

# 假设你已经有这两个数据框
# pvd_soft_norm：归一化后的 soft score
# binary_labels：真实标签 (0/1)
labels <- read_tsv("merged_labels.tsv")



# === Step 1: 定义 PVD 到 38类值的映射 ===
pvd_to_38_map <- list(
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

# === Step 2: 构建 pvd_soft_38（复制 soft scores 到 38列） ===
pvd_soft_38 <- labels[, 1:2]  # 保留 Text-ID 和 Sentence-ID
for (from_col in names(pvd_to_38_map)) {
  to_cols <- pvd_to_38_map[[from_col]]
  for (to_col in to_cols) {
    pvd_soft_38[[to_col]] <- pvd_soft_norm[[from_col]]
  }
}

# === Step 3: 定义阈值搜索函数 ===
find_best_threshold <- function(scores, truths) {
  df <- data.frame(score = scores, truth = truths)
  df <- df[!is.na(df$truth), ]  # 删除 NA
  df <- df[order(-df$score), ]  # 按 score 从大到小排序
  
  tp <- cumsum(df$truth == 1)
  fp <- cumsum(df$truth == 0)
  fn <- sum(df$truth == 1) - tp
  
  precision <- tp / (tp + fp + 1e-6)
  recall <- tp / (tp + fn + 1e-6)
  f1 <- 2 * precision * recall / (precision + recall + 1e-6)
  
  best_idx <- which.max(f1)
  best_threshold <- df$score[best_idx]
  
  return(list(threshold = best_threshold, f1 = f1[best_idx]))
}

setdiff(colnames(labels)[-(1:2)], colnames(pvd_soft_38)[-(1:2)])
colnames(labels)
colnames(pvd_soft_38)

# === Step 4: 为每个标签计算最佳阈值 ===
thresholds <- sapply(common_cols, function(col) {
  scores <- as.numeric(pvd_soft_38[[col]])
  truths <- as.numeric(labels[[col]])
  if (sum(truths, na.rm = TRUE) == 0) return(NA)  # 没有正例
  find_best_threshold(scores, truths)$threshold
})

# === Step 5: 应用阈值将 soft score 转为 0/1 预测 ===
pvd_pred_38 <- pvd_soft_38
for (col in names(thresholds)) {
  thr <- thresholds[[col]]
  if (!is.na(thr)) {
    pvd_pred_38[[col]] <- ifelse(pvd_soft_38[[col]] >= thr, 1, 0)
  } else {
    pvd_pred_38[[col]] <- 0  # 若无正例，则全部为 0
  }
}

# === Step 6: 检查输出是否为 0/1 ===
table(unlist(pvd_pred_38[ , -(1:2)]))  # 应只含 0 和 1

# （可选）保存为 CSV
write.csv(pvd_pred_38, "pvd_pred_38_binary.csv", row.names = FALSE)





common_cols





library(MLmetrics)

# === Step 1: 读取数据 ===
# 真实标签（二值）
merged_labels <- read.delim("10mapped_labels_paragraph.tsv", check.names = FALSE)

# 预测 soft score
pvd <- read.csv("PVD_merged_result.csv", check.names = FALSE)

# 标签列
label_cols <- c("Values_SE","Values_CO","Values_TR","Values_BE","Values_UN",
                "Values_SD","Values_ST","Values_HE","Values_AC","Values_PO")

# === Step 2: 对每一行进行 min-max 归一化 ===
pvd_normalized <- pvd
row_min <- apply(pvd[label_cols], 1, min)
row_max <- apply(pvd[label_cols], 1, max)
range <- row_max - row_min
range[range == 0] <- 1  # 防止除以0
pvd_normalized[label_cols] <- t((t(pvd[label_cols]) - row_min) / range)

# === Step 3: 合并真实标签与归一化预测 ===
merged <- merge(merged_labels, pvd_normalized, by = c("Text-ID", "doc_id"), suffixes = c("_true", "_pred"))

# === Step 4: 为每个标签计算最佳阈值（按 F1-score 最大化）===
best_thresholds <- numeric(length(label_cols))
names(best_thresholds) <- label_cols

min_threshold <- 0.2  # ✅ 设置你想要的最小阈值

for (label in label_cols) {
  true_vals <- merged[[paste0(label, "_true")]]
  pred_scores <- merged[[label]]  # 已归一化列
  
  if (all(true_vals == 0)) {
    warning(paste("标签", label, "的真实值全为0，跳过此列。"))
    next
  }
  
  # ✅ 只从 min_threshold 起遍历
  thresholds <- seq(min_threshold, 1, by = 0.01)
  
  f1_scores <- sapply(thresholds, function(t) {
    preds <- as.integer(pred_scores >= t)
    
    if (all(preds == 0) && all(true_vals == 0)) {
      return(1)
    } else if (all(preds == 0)) {
      return(0)
    } else {
      return(F1_Score(y_true = true_vals, y_pred = preds))
    }
  })
  
  if (all(is.na(f1_scores))) {
    warning(paste("标签", label, "的 F1 分数全部为 NA，无法计算最佳阈值。"))
    next
  }
  
  best_thresholds[label] <- thresholds[which.max(f1_scores)]
}


# 输出最佳阈值
print(best_thresholds)

# === Step 5: 应用最佳阈值，得到二值预测 ===
for (label in label_cols) {
  threshold <- best_thresholds[label]
  merged[[paste0(label, "_bin_pred")]] <- as.integer(merged[[label]] >= threshold)
}

# === Step 6（可选）: 提取预测结果用于评估或保存 ===
binary_predictions <- merged[, c("Text-ID", "doc_id", paste0(label_cols, "_bin_pred"))]

# 去除后缀，重命名列为原始标签名
colnames(binary_predictions) <- c("Text-ID", "doc_id", label_cols)

# 保存结果
write.table(binary_predictions, "PVD_binary_predictions.tsv", sep = "\t", row.names = FALSE, quote = FALSE)





















library(tidyverse)

# === Step 1: 读取数据 ===
value_cols <- c("Values_SE", "Values_CO", "Values_TR", "Values_BE", "Values_UN",
                "Values_SD", "Values_ST", "Values_HE", "Values_AC", "Values_PO")

pvd_scores <- read.csv("PVD_merged_result.csv")
labels <- read_tsv("10mapped_labels_paragraph.tsv")

# 确保对齐
# 确保对齐

# 然后比较
stopifnot(identical(
  labels%>% select(`Text-ID`),
  pvd_scores %>% select(`Text.ID`)
))



colnames(pvd_scores)
colnames(labels)
# === Step 2: 对每一行 value 打分做 min-max 归一化 ===
normalize_row <- function(x) {
  if (sum(x, na.rm = TRUE) == 0) return(rep(0, length(x)))
  rng <- range(x, na.rm = TRUE)
  if (rng[1] == rng[2]) rep(0, length(x)) else (x - rng[1]) / (rng[2] - rng[1])
}


pvd_soft <- pvd_scores %>%
  select(all_of(value_cols)) %>%
  as.data.frame() %>%
  apply(1, normalize_row) %>%
  t() %>%
  as.data.frame()

colnames(pvd_soft) <- value_cols

# === Step 3: 找最佳阈值 ===
find_best_threshold <- function(scores, truths) {
  df <- data.frame(score = scores, truth = truths)
  df <- df[!is.na(df$truth), ]
  df <- df[order(-df$score), ]
  
  tp <- cumsum(df$truth == 1)
  fp <- cumsum(df$truth == 0)
  fn <- sum(df$truth == 1) - tp
  
  precision <- tp / (tp + fp + 1e-6)
  recall <- tp / (tp + fn + 1e-6)
  f1 <- 2 * precision * recall / (precision + recall + 1e-6)
  
  best_idx <- which.max(f1)
  best_threshold <- df$score[best_idx]
  
  # 添加下限限制
  return(max(best_threshold, 0.5))
}

# 只对非全为 0 的标签计算阈值
non_zero_labels <- value_cols[which(colSums(labels[, value_cols], na.rm = TRUE) > 0)]

thresholds <- sapply(non_zero_labels, function(col) {
  scores <- as.numeric(pvd_soft[[col]])
  truths <- as.numeric(labels[[col]])
  find_best_threshold(scores, truths)
})

# === Step 4: 应用阈值生成 binary prediction ===
binary_preds <- pvd_soft
for (col in value_cols) {
  if (col %in% names(thresholds)) {
    thr <- thresholds[[col]]
    binary_preds[[col]] <- ifelse(binary_preds[[col]] >= thr, 1, 0)
  } else {
    binary_preds[[col]] <- 0
  }
}

# 检查是否只包含 0/1
print(table(unlist(binary_preds[, value_cols])))  # ✅ 只应该是 0 和 1
colnames(pvd_scores)
# （可选）保存结果
binary_preds <- cbind(pvd_scores[, c("Text.ID", "doc_id")], binary_preds)
write.csv(binary_preds, "10pvd_min-max_paragraph.csv", row.names = FALSE)








