# Atmospheric gas analysis: exploratory workflow
# Curated from the submitted coursework script. The input CSV is not bundled
# because the submitted archive did not document its upstream licence.
#
# Expected input: data/MaunaLoa_miss.csv
# Packages: tidyverse, naniar, mice, FactoMineR, factoextra, corrplot,
#           GGally, VIM, dendextend, reshape2, cluster

required <- c("tidyverse", "naniar", "mice", "FactoMineR", "factoextra",
              "corrplot", "GGally", "VIM", "dendextend", "reshape2", "cluster")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install required packages first: ", paste(missing, collapse = ", "))
}

library(tidyverse)
library(naniar)
library(mice)
library(FactoMineR)
library(factoextra)
library(corrplot)
library(GGally)
library(VIM)
library(dendextend)
library(cluster)

data_path <- file.path("data", "MaunaLoa_miss.csv")
if (!file.exists(data_path)) {
  stop("Missing input: ", data_path,
       ". Obtain an authorised copy and place it in this project data folder.")
}

df <- readr::read_csv(data_path, show_col_types = FALSE) |>
  mutate(Date = as.Date(Date))

gas_cols <- setdiff(names(df), "Date")
numeric_cols <- gas_cols[vapply(df[gas_cols], is.numeric, logical(1))]
if (length(numeric_cols) < 2L) stop("Expected at least two numeric gas variables.")

gas <- df |> select(all_of(numeric_cols))

# Exploratory summaries and correlation structure
print(summary(df))
GGally::ggpairs(gas)
cor_matrix <- cor(gas, use = "pairwise.complete.obs")
corrplot::corrplot(cor_matrix, method = "color", type = "upper",
                   addCoef.col = "grey30", tl.srt = 45)

# Tukey 1.5-IQR outlier flagging. Flagged values are set to NA for the
# submitted coursework workflow; inspect domain meaning before adopting this.
flag_tukey <- function(x) {
  q <- quantile(x, c(0.25, 0.75), na.rm = TRUE)
  spread <- IQR(x, na.rm = TRUE)
  which(x < q[1] - 1.5 * spread | x > q[2] + 1.5 * spread)
}

gas_clean <- gas
outlier_counts <- vapply(gas_clean, function(x) length(flag_tukey(x)), integer(1))
print(outlier_counts)
for (nm in names(gas_clean)) {
  idx <- flag_tukey(gas_clean[[nm]])
  if (length(idx)) gas_clean[[nm]][idx] <- NA_real_
}

# Missingness diagnostics. A non-significant MCAR test does not prove MCAR.
print(colSums(is.na(gas_clean)))
print(naniar::mcar_test(gas_clean))
VIM::aggr(gas_clean, numbers = TRUE, sortVars = TRUE)

# Multiple imputation by predictive mean matching.
set.seed(123)
imp <- mice::mice(gas_clean, m = 10, method = "pmm", seed = 123, printFlag = FALSE)
print(summary(imp))

# The submitted coursework uses one completed dataset for PCA and clustering.
# This is a simplifying choice; it does not propagate imputation uncertainty.
completed <- mice::complete(imp, action = 1)
pca <- FactoMineR::PCA(completed, scale.unit = TRUE, graph = FALSE)
print(pca$eig)
factoextra::fviz_eig(pca, addlabels = TRUE)
factoextra::fviz_pca_biplot(pca, repel = TRUE)

cumulative <- cumsum(pca$eig[, 2])
n_components <- which(cumulative >= 85)[1]
message("Components required for >=85% cumulative variance: ", n_components)

pca_coordinates <- as.data.frame(pca$ind$coord[, seq_len(n_components), drop = FALSE])

# The report's selected solution uses k = 3. Inspect WSS/silhouette and stability.
factoextra::fviz_nbclust(pca_coordinates, stats::kmeans, method = "wss")
factoextra::fviz_nbclust(pca_coordinates, stats::kmeans, method = "silhouette")

set.seed(123)
km <- stats::kmeans(pca_coordinates, centers = 3, nstart = 25)
between_total_pct <- 100 * km$betweenss / km$totss
message("K-means between/total sum-of-squares (%): ", round(between_total_pct, 2))
factoextra::fviz_cluster(list(data = pca_coordinates, cluster = km$cluster))

# Hierarchical clustering using Ward's method and the same three-cluster cut.
hc <- stats::hclust(stats::dist(pca_coordinates), method = "ward.D2")
hc_cluster <- stats::cutree(hc, k = 3)
factoextra::fviz_dend(hc, k = 3, rect = TRUE)
print(table(KMeans = km$cluster, Hierarchical = hc_cluster))

# PCA variance percentages in the submitted report differ between sections.
# Reconcile those figures against the source outputs before formal reporting.
