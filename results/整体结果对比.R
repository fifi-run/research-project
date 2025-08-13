library(ggplot2)
library(dplyr)
library(tidyr)

# 原始结果表
df <- data.frame(
  Input = c("sentence","sentence","sentence","sentence","sentence","sentence",
            "paragraph","paragraph","paragraph","paragraph","paragraph","paragraph"),
  Categories = c("38","38","38","10","10","10",
                 "38","38","38","10","10","10"),
  Model = c("ValuesML","PVD(hard)","PVD(soft)",
            "ValuesML","PVD(hard)","PVD(soft)",
            "ValuesML","PVD(hard)","PVD(soft)",
            "ValuesML","PVD(hard)","PVD(soft)"),
  F1 = c(0.618,0.051,0.064,0.244,0.126,0.152,
         0.700,0.291,0.344,0.800,0.651,0.644),
  Precision = c(0.634,0.031,0.027,0.166,0.095,0.118,
                0.681,0.186,0.245,0.722,0.504,0.486),
  Recall = c(0.669,0.212,0.185,0.459,0.184,0.216,
             0.773,0.904,0.672,0.896,0.918,0.953),
  Accuracy = c(0.963,0.873,0.883,0.837,0.853,0.863,
               0.888,0.325,0.583,0.804,0.570,0.540)
)

# 图1: F1 Score by Model & Input Granularity
ggplot(df, aes(x=Input, y=F1, fill=Model)) +
  geom_bar(stat="identity", position=position_dodge(width=0.9)) +
  geom_text(aes(label=sprintf("%.2f", F1)), 
            position=position_dodge(width=0.8), vjust=-0.3, size=3) +
  facet_wrap(~Categories, labeller = labeller(Categories = c("38" = "38 Categories", "10" = "10 Categories"))) +
  scale_fill_brewer(palette="Set2") +
  labs(title="F1 Score by Input Granularity and Label Configurations", 
       y="Macro-F1", x="Input Granularity") +
  theme_minimal(base_size = 12)

# 图2: F1 Score by Model & Label Configurations
ggplot(df, aes(x=Categories, y=F1, fill=Model)) +
  geom_bar(stat="identity", position=position_dodge(width=0.9)) +
  geom_text(aes(label=sprintf("%.2f", F1)), 
            position=position_dodge(width=0.8), vjust=-0.3, size=3) +
  facet_wrap(~Input) +
  scale_fill_brewer(palette="Set2") +
  labs(title="F1 Score by Label Configurations and Input Granularity", 
       y="Macro-F1", x="Label Configurations") +
  theme_minimal(base_size = 12)

# 图3: Precision–Recall Trade-off
df_long <- df %>%
  select(Input, Categories, Model, Precision, Recall) %>%
  pivot_longer(cols = c("Precision","Recall"), names_to="Metric", values_to="Score")

ggplot(df_long, aes(x=Metric, y=Score, fill=Model)) +
  geom_bar(stat="identity", position=position_dodge(width=0.9)) +
  geom_text(aes(label=sprintf("%.2f", Score)), 
            position=position_dodge(width=0.8), vjust=-0.3, size=3) +
  facet_grid(Input ~ Categories) +
  scale_fill_brewer(palette="Set2") +
  labs(title="Precision–Recall Trade-off", y="Score", x="Metric") +
  theme_minimal(base_size = 12)

# 图4: Accuracy by Model & Settings
ggplot(df, aes(x=Model, y=Accuracy, fill=Model)) +
  geom_bar(stat="identity", position=position_dodge(width=0.8)) +
  geom_text(aes(label=sprintf("%.2f", Accuracy)), 
            position=position_dodge(width=0.8), vjust=-0.3, size=3) +
  facet_grid(Input ~ Categories) +
  scale_fill_brewer(palette="Set2") +
  labs(title="Accuracy by Model, Input, and Label Configurations", y="Accuracy", x="Model") +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle=45, hjust=1))



# only pvd
# 只保留 PVD 相关行
df_pvd <- df %>% filter(Model %in% c("PVD(hard)", "PVD(soft)"))

# 图1: F1 对比
ggplot(df_pvd, aes(x=Input, y=F1, fill=Model)) +
  geom_bar(stat="identity", position=position_dodge(width=0.9)) +
  geom_text(aes(label=sprintf("%.2f", F1)), 
            position=position_dodge(width=0.8), vjust=-0.3, size=3) +
  facet_wrap(~Categories, labeller = labeller(Categories = c("38" = "38 Categories", "10" = "10 Categories"))) +
  scale_fill_brewer(palette="Set2") +
  labs(title="PVD Performance Comparison (F1)", 
       y="Macro-F1", x="Input Granularity") +
  theme_minimal(base_size = 12)

# 图2: Precision–Recall 对比
df_pvd_long <- df_pvd %>%
  select(Input, Categories, Model, Precision, Recall) %>%
  pivot_longer(cols = c("Precision","Recall"), names_to="Metric", values_to="Score")

ggplot(df_pvd_long, aes(x=Metric, y=Score, fill=Model)) +
  geom_bar(stat="identity", position=position_dodge(width=0.8)) +
  geom_text(aes(label=sprintf("%.2f", Score)), 
            position=position_dodge(width=0.8), vjust=-0.3, size=3) +
  facet_grid(Input ~ Categories) +
  scale_fill_brewer(palette="Set2") +
  labs(title="PVD Precision–Recall Comparison", y="Score", x="Metric") +
  theme_minimal(base_size = 12)

# 图3: Accuracy 对比
ggplot(df_pvd, aes(x=Model, y=Accuracy, fill=Model)) +
  geom_bar(stat="identity", position=position_dodge(width=0.8)) +
  geom_text(aes(label=sprintf("%.2f", Accuracy)), 
            position=position_dodge(width=0.8), vjust=-0.3, size=3) +
  facet_grid(Input ~ Categories) +
  scale_fill_brewer(palette="Set2") +
  labs(title="PVD Accuracy Comparison", y="Accuracy", x="Model") +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle=45, hjust=1))
