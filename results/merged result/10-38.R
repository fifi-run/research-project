# 读取数据
df <- read.delim("merged_labels.tsv", check.names = FALSE)

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
write.table(result, "10mapped_labels.tsv", sep = "\t", row.names = FALSE, quote = FALSE)



# 读取数据
df <- read.delim("merged_ValuesML.tsv", check.names = FALSE)

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
write.table(result, "10mapped_ValuesML.tsv", sep = "\t", row.names = FALSE, quote = FALSE)




# 读取数据
df <- read.delim("merged_ValuesML.tsv", check.names = FALSE)

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
write.table(result, "10mapped_ValuesML.tsv", sep = "\t", row.names = FALSE, quote = FALSE)



