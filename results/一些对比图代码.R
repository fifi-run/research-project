# 安装并加载所需包
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("tidyr")) install.packages("tidyr")
if (!require("fmsb")) install.packages("fmsb")
library(ggplot2)
library(tidyr)
library(fmsb)

# 构建性能数据
df <- data.frame(
  Model = rep(c("ValuesML", "PVD"), 2),
  Level = c("Sentence", "Sentence", "Paragraph", "Paragraph"),
  F1 = c(0.618, 0.049, 0.700, 0.275),
  Precision = c(0.634, 0.031, 0.681, 0.177),
  Recall = c(0.669, 0.202, 0.773, 0.827),
  Accuracy = c(0.963, 0.881, 0.888, 0.380)
)

# 转为长格式
df_long <- pivot_longer(df, cols = c("F1", "Precision", "Recall", "Accuracy"),
                        names_to = "Metric", values_to = "Score")

# 柱状图（带数值）
ggplot(df_long, aes(x = interaction(Model, Level), y = Score, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(), width = 0.7) +
  geom_text(aes(label = round(Score, 3)), vjust = -0.5, size = 3) +
  facet_wrap(~Metric, scales = "free_y") +
  labs(title = "Model Performance Comparison by Text Granularity",
       x = "Model and Input Level", y = "Score") +
  theme_minimal(base_size = 10) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  ylim(0, 1.05)

# 雷达图：准备数据（每行为一类模型+输入）
radar_df <- df
rownames(radar_df) <- paste(df$Model, df$Level, sep = "_")
radar_df <- radar_df[, c("F1", "Precision", "Recall", "Accuracy")]

# 添加最大最小行
radar_df <- rbind(
  max = c(1, 1, 1, 1),
  min = c(0, 0, 0, 0),
  radar_df
)

# 绘制雷达图
colors_border <- c("blue", "red", "darkgreen", "orange")
radarchart(radar_df,
           axistype = 1,
           pcol = colors_border,
           pfcol = scales::alpha(colors_border, 0.2),
           plwd = 2,
           plty = 1,
           cglcol = "grey",
           cglty = 1,
           axislabcol = "grey20",
           caxislabels = seq(0, 1, 0.2),
           cglwd = 0.6,
           vlcex = 1,
           title = "Radar Chart of Model Performance")

legend("topright", legend = rownames(radar_df)[-c(1,2)], 
       bty = "n", pch = 20, col = colors_border, text.col = "black", cex = 1.0)




















# 构建性能数据
df <- data.frame(
  Model = c("ValuesML", "PVD"),
  F1 = c(0.800, 0.651),
  Precision = c(0.722, 0.031, 0.681, 0.177),
  Recall = c(0.669, 0.202, 0.773, 0.827),
  Accuracy = c(0.963, 0.881, 0.888, 0.380)
)

# 转为长格式
df_long <- pivot_longer(df, cols = c("F1", "Precision", "Recall", "Accuracy"),
                        names_to = "Metric", values_to = "Score")

# 柱状图（带数值）
ggplot(df_long, aes(x = interaction(Model, Level), y = Score, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(), width = 0.7) +
  geom_text(aes(label = round(Score, 3)), vjust = -0.5, size = 3) +
  facet_wrap(~Metric, scales = "free_y") +
  labs(title = "Model Performance Comparison by Text Granularity",
       x = "Model and Input Level", y = "Score") +
  theme_minimal(base_size = 10) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  ylim(0, 1.05)

# 雷达图：准备数据（每行为一类模型+输入）
radar_df <- df
rownames(radar_df) <- paste(df$Model, df$Level, sep = "_")
radar_df <- radar_df[, c("F1", "Precision", "Recall", "Accuracy")]

# 添加最大最小行
radar_df <- rbind(
  max = c(1, 1, 1, 1),
  min = c(0, 0, 0, 0),
  radar_df
)

# 绘制雷达图
colors_border <- c("blue", "red", "darkgreen", "orange")
radarchart(radar_df,
           axistype = 1,
           pcol = colors_border,
           pfcol = scales::alpha(colors_border, 0.2),
           plwd = 2,
           plty = 1,
           cglcol = "grey",
           cglty = 1,
           axislabcol = "grey20",
           caxislabels = seq(0, 1, 0.2),
           cglwd = 0.6,
           vlcex = 1,
           title = "Radar Chart of Model Performance")

legend("topright", legend = rownames(radar_df)[-c(1,2)], 
       bty = "n", pch = 20, col = colors_border, text.col = "black", cex = 1.0)
