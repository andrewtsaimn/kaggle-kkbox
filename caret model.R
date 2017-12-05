library(dplyr)
library(caret)
library(doMC)
registerDoMC(cores = 23)

kkbox_data <- read.csv("dataset-2.csv", header=TRUE)
# submission_sample <- read.csv("sample_submission_zero.csv")

kkbox_data <- kkbox_raw %>% filter(sec_last_num_25 != '\\N')
kkbox_data$sec_last_num_25 <- as.integer(as.character(kkbox_data$sec_last_num_25))
kkbox_data$sec_last_num_50 <- as.integer(as.character(kkbox_data$sec_last_num_50))
kkbox_data$sec_last_num_75 <- as.integer(as.character(kkbox_data$sec_last_num_75))
kkbox_data$sec_last_num_985 <- as.integer(as.character(kkbox_data$sec_last_num_985))
kkbox_data$sec_last_num_100 <- as.integer(as.character(kkbox_data$sec_last_num_100))
kkbox_data$sec_last_num_unq <- as.integer(as.character(kkbox_data$sec_last_num_unq))
kkbox_data$sec_last_total_secs <- as.integer(as.character(kkbox_data$sec_last_total_secs))

kkbox_data <- kkbox_data[complete.cases(kkbox_data),]

# write.csv(kkbox_data, "kkbox_train.csv")

split <- .3
sample_index <- createDataPartition(kkbox_data$is_churn, p=split, list=FALSE)

training <- kkbox_data[sample_index,]
testing <- kkbox_data[-sample_index,]

training <- training[,colnames(training)!="msno"]
training$is_churn <- as.factor(training$is_churn)
training[,1:20] <- scale(training[,1:20])

testing <- testing[,colnames(testing)!="msno"]
testing$is_churn <- as.factor(testing$is_churn)
testing[,1:20] <- scale(testing[,1:20])


trctrl <- trainControl(method="repeatedcv", number=10, repeats=3)
set.seed(3333)

kkbox_xgb_fit <- train(is_churn ~ ., data = training, method = "xgbTree",
  trControl = trctrl)

kkbox_xgb_pred <- predict(kkbox_xgb_fit, newdata = testing)
confusionMatrix(kkbox_xgb_pred, testing$is_churn)

saveRDS(kkbox_xgb_fit, "kkbox_xgb.RDS")
