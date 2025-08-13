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



























