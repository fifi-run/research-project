# Wine quality analysis: LASSO regression and Random Forest classification
# Curated from the submitted coursework script. Regression and classification
# are evaluated separately because their metrics answer different questions.
#
# Expected input: data/winequality-red.csv (semicolon-delimited)
# Packages: caret, glmnet, randomForest, ggplot2, dplyr, corrplot, GGally, reshape2

required <- c("caret", "glmnet", "randomForest", "ggplot2", "dplyr",
              "corrplot", "GGally", "reshape2")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install required packages first: ", paste(missing, collapse = ", "))
}

library(caret)
library(glmnet)
library(randomForest)
library(ggplot2)
library(dplyr)
library(corrplot)
library(GGally)
library(reshape2)

data_path <- file.path("data", "winequality-red.csv")
if (!file.exists(data_path)) {
  stop("Missing input: ", data_path,
       ". Download the UCI red-wine file and save it in this project data folder.")
}

wine <- read.csv(data_path, sep = ";")
stopifnot("quality" %in% names(wine))
predictors <- setdiff(names(wine), "quality")

# Outlier counts based on the 1.5-IQR rule (not automatically discarded).
iqr_outlier_counts <- vapply(wine[predictors], function(x) {
  bounds <- quantile(x, c(0.25, 0.75), na.rm = TRUE)
  spread <- IQR(x, na.rm = TRUE)
  sum(x < bounds[1] - 1.5 * spread | x > bounds[2] + 1.5 * spread, na.rm = TRUE)
}, integer(1))
print(iqr_outlier_counts)

# The submitted analysis also used domain-informed filters. They are retained
# below for comparability; justify each threshold before using in new research.
wine_clean <- wine |>
  filter(citric.acid <= 1.5,
         chlorides <= 0.2,
         pH >= 2.5 & pH <= 4.2,
         sulphates >= 0.2 & sulphates <= 1.5,
         density >= 0.975 & density <= 1.02,
         fixed.acidity >= 3 & fixed.acidity <= 12,
         volatile.acidity <= 1.5,
         alcohol >= 7 & alcohol <= 16)

set.seed(42)
train_index <- caret::createDataPartition(wine_clean$quality, p = 0.75, list = FALSE)
train <- wine_clean[train_index, , drop = FALSE]
test <- wine_clean[-train_index, , drop = FALSE]

x_train <- as.matrix(train[, predictors, drop = FALSE])
x_test <- as.matrix(test[, predictors, drop = FALSE])
y_train <- train$quality
y_test <- test$quality

# Task A: numeric quality-score regression with LASSO.
set.seed(42)
lasso_cv <- glmnet::cv.glmnet(x_train, y_train, alpha = 1, nfolds = 10)
lasso_prediction <- as.numeric(predict(lasso_cv, newx = x_test, s = "lambda.min"))
regression_metrics <- data.frame(
  RMSE = sqrt(mean((y_test - lasso_prediction)^2)),
  MAE = mean(abs(y_test - lasso_prediction)),
  R_squared = 1 - sum((y_test - lasso_prediction)^2) /
    sum((y_test - mean(y_test))^2)
)
print(regression_metrics)

# Task B: categorical quality classification with Random Forest.
# This is a separate task and must not be compared numerically to regression
# metrics as though the prediction targets were identical.
train$quality_class <- factor(train$quality)
test$quality_class <- factor(test$quality, levels = levels(train$quality_class))
rf_data <- train[, c(predictors, "quality_class")]
set.seed(42)
rf_model <- randomForest::randomForest(quality_class ~ ., data = rf_data,
                                       ntree = 500, importance = TRUE)
rf_prediction <- predict(rf_model, newdata = test[, predictors, drop = FALSE])
rf_prediction <- factor(rf_prediction, levels = levels(test$quality_class))
cm <- caret::confusionMatrix(rf_prediction, test$quality_class)
print(cm)
print(caret::confusionMatrix(rf_prediction, test$quality_class,
                             mode = "everything")$byClass)
print(randomForest::importance(rf_model))
varImpPlot(rf_model)

# Report regression and classification metrics in separate tables.
# For imbalanced classes, include per-class recall/F1 and balanced accuracy.
