# 加载必要的库
library(dplyr)
library(readr)

# 读取 TSV 文件
df <- read_tsv("sentences.tsv", col_types = cols())

# 检查列名
print(colnames(df))

# 假设你的列名为 "Text-ID", "Sentence-ID", 和 "Text"
# 如果不一致，请根据实际情况修改列名

# 按照 Text-ID 和 Sentence-ID 排序，并合并 Text

merged_df <- df %>%
  group_by(`Text-ID`) %>%
  summarise(
    `Sentence-ID` = 1,
    Text = paste(Text, collapse = " ")
  )

# 保存为新的 TSV 文件
write_tsv(merged_df, "merged_sentences.tsv")

# 提示完成
cat("合并完成，保存为 merged_sentences.tsv\n")


df <- read_tsv("labels.tsv", col_types = cols())
print(colnames(df))

result <- df %>%
  group_by(`Text-ID`) %>%
  summarise(across(where(is.numeric), ~ as.numeric(any(. == 1))), .groups = "drop") %>%
  mutate(`Sentence-ID` = 1) %>%
  relocate(`Sentence-ID`, .after = `Text-ID`)
# 查看结果
print(result)
write_tsv(result, "merged_labels.tsv")


#labels
df <- read_tsv("labels.tsv", col_types = cols())
print(colnames(df))

result <- df %>%
  group_by(`Text-ID`) %>%
  summarise(across(where(is.numeric), ~ as.numeric(any(. == 1))), .groups = "drop") %>%
  mutate(`Sentence-ID` = 1) %>%
  relocate(`Sentence-ID`, .after = `Text-ID`)
# 查看结果
print(result)
write_tsv(result, "merged_labels.tsv")


#PVD
df <- read_csv("PVD_merged_result.csv", col_types = cols())

# 将数值列中所有非0值替换为1
df[ , 3:ncol(df)] <- lapply(df[ , 3:ncol(df)], function(x) ifelse(x != 0, 1, 0))

# 查看结果
print(df)

write_tsv(df, "merged_PVD0-1.tsv")

#ValuesML
df <- read_tsv("test_predictions.tsv", col_types = cols())
print(colnames(df))

result <- df %>%
  group_by(`Text-ID`) %>%
  summarise(across(where(is.numeric), ~ as.numeric(any(. == 1))), .groups = "drop") %>%
  mutate(`Sentence-ID` = 1) %>%
  relocate(`Sentence-ID`, .after = `Text-ID`)
# 查看结果
print(result)
write_tsv(result, "merged_ValuesML.tsv")

