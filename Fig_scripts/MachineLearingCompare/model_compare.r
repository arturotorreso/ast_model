library(caret)
library(pROC)
library(ranger)
library(ggsci)
setwd("D://R/projects/Genskey/RJ_PA_resistantance_prediction/20230423MachineLearingCompare/ipm/")


input<-read.table("lm.input.xls",header=T,row.names =1,sep="\t")
input$Group <- ifelse(
  input$Group == 'R',
  1,
  0
)
input$Group = factor(input$Group)


fitControl <- trainControl(method = "cv", number = 10)
##LASSO
trainIndex <- createDataPartition(input$Group, p = 1, list = FALSE)
train <- input[trainIndex, ]
test <- input[-trainIndex, ]

lassoModel <- train(Group ~ .,
                    data = train,
                    method = "glmnet",
                    trControl = fitControl,
                    tuneGrid = expand.grid(alpha = 1, lambda = seq(0, 1, by = 0.01)))
# 训练集AUC
lassoModel_train_pred <- predict(lassoModel, newdata = train, type = "prob")[,2]
lassoModel_train_roc <- roc(train$Group, lassoModel_train_pred)
lassoModel_train_auc<-round(lassoModel_train_roc$auc,3)

# # 测试集AUC
# lassoModel_test_pred <- predict(lassoModel, newdata = test, type = "prob")[,2]
# lassoModel_test_roc <- roc(test$Group, lassoModel_test_pred)
# lassoModel_test_auc<-round(lassoModel_test_roc$auc,3)

##lm
svmModel <- train(Group ~ .,
                    data = train,
                 method = "svmLinear",
                    trControl = fitControl)
# 训练集AUC
svmModel_train_pred <- predict(svmModel, newdata = train)
svmModel_train_pred <- as.numeric(svmModel_train_pred)
svmModel_train_roc <- roc(train$Group, svmModel_train_pred)
svmModel_train_auc<-round(svmModel_train_roc$auc,3)

# # 测试集AUC
# svmModel_test_pred <- predict(svmModel, newdata = test)
# svmModel_test_pred <- as.numeric(svmModel_test_pred)
# svmModel_test_roc <- roc(test$Group, svmModel_test_pred)
# svmModel_test_auc<-round(svmModel_test_roc$auc,3)


##randomforest
randomforestModel <- train(Group ~ ., 
                   data = train, 
                   method = "ranger",
                   trControl = fitControl)
# 训练集AUC
randomforestModel_train_pred <- predict(randomforestModel, newdata = train)
randomforestModel_train_pred <- as.numeric(randomforestModel_train_pred)
randomforestModel_train_roc <- roc(train$Group, randomforestModel_train_pred)
randomforestModel_train_auc<-round(randomforestModel_train_roc$auc,3)

# # 测试集AUC
# randomforestModel_test_pred <- predict(randomforestModel, newdata = test)
# randomforestModel_test_pred <- as.numeric(randomforestModel_test_pred)
# randomforestModel_test_roc <- roc(test$Group, randomforestModel_test_pred)
# randomforestModel_test_auc<-round(test_roc$auc,3)

##神经网络
neuralnetworkModel <- train(Group ~ ., 
                              data = train, 
                              method = "nnet",
                            trControl = fitControl)
# 训练集AUC
neuralnetworkModel_train_pred <- predict(neuralnetworkModel, newdata = train)
neuralnetworkModel_train_pred <- as.numeric(neuralnetworkModel_train_pred)
neuralnetworkModel_train_roc<- roc(train$Group, neuralnetworkModel_train_pred)
neuralnetworkModel_train_auc <-round(roc(train$Group, neuralnetworkModel_train_pred)$auc,3)

# # 测试集AUC
# neuralnetworkModel_test_pred <- predict(neuralnetworkModel, newdata = test)
# neuralnetworkModel_test_pred <- as.numeric(neuralnetworkModel_test_pred)
# neuralnetworkModel_test_roc<-roc(test$Group, neuralnetworkModel_test_pred)
# neuralnetworkModel_test_auc <- round(neuralnetworkModel_test_roc$auc,3)


#XGBOOST
##神经网络
XGBOOSTModel <- train(Group ~ ., 
                            data = train, 
                            method = "xgbTree",
                            trControl = fitControl)
# 训练集AUC
XGBOOSTModel_train_pred <- predict(XGBOOSTModel, newdata = train)
XGBOOSTModel_train_pred <- as.numeric(XGBOOSTModel_train_pred)
XGBOOSTModel_train_roc<- roc(train$Group, XGBOOSTModel_train_pred)
XGBOOSTModel_train_auc <-round(roc(train$Group, XGBOOSTModel_train_pred)$auc,3)
# 
# # 测试集AUC
# XGBOOSTModel_test_pred <- predict(XGBOOSTModel, newdata = test)
# XGBOOSTModel_test_pred <- as.numeric(XGBOOSTModel_test_pred)
# XGBOOSTModel_test_roc<-roc(test$Group, XGBOOSTModel_test_pred)
# XGBOOSTModel_test_auc <- round(XGBOOSTModel_test_roc$auc,3)

roc_data_train <- rbind(
  data.frame(fpr = 1-lassoModel_train_roc$specificities, tpr = lassoModel_train_roc$sensitivities, Model = "LASSO"),
  data.frame(fpr = 1-randomforestModel_train_roc$specificities, tpr = randomforestModel_train_roc$sensitivities, Model = "RandomForest"),
  data.frame(fpr = 1-neuralnetworkModel_train_roc$specificities, tpr = neuralnetworkModel_train_roc$sensitivities, Model = "Feed-Forward Neural Networks"),
  data.frame(fpr = 1-svmModel_train_roc$specificities, tpr = svmModel_train_roc$sensitivities, Model = "Liner SVM"),
  data.frame(fpr = 1-XGBOOSTModel_train_roc$specificities, tpr = XGBOOSTModel_train_roc$sensitivities, Model = "XGBOOST")

)


fig<-  ggplot() +  
  geom_path(data = roc_data_train, aes(x = fpr, y = tpr, color = Model), size=0.8)  +
  labs(x = "False Positive Rate", y = "True Positive Rate", color = "Model") +
  scale_color_lancet() + scale_color_lancet()+
  ggtitle("IPM ROC Curves for Different Models") +
  theme(plot.title = element_text(hjust = 0.5))+
  theme(axis.text = element_text(size = 12, color="black", vjust=0.5, hjust=0.5)) + 
  theme(axis.title= element_text(size = 12, color="black", vjust=0.5, hjust=0.5))+
  theme_bw()+
  theme(legend.text = element_text(color = 'black',size = 12, family = 'Arial', face = 'plain'),
        panel.background = element_blank(),
        plot.title = element_text(hjust = 0.5, size = 12),
        panel.grid = element_blank(),
        axis.text = element_text(color = 'black',size = 12, family = 'Arial', face = 'plain'),
        axis.text.x = element_text(angle = 0),
        axis.title = element_text(color = 'black',size = 12, family = 'Arial', face = 'plain'),
        axis.ticks = element_line(color = 'black'),
        axis.ticks.x = element_blank())+
  scale_x_continuous(limits = c(0,1), expand = c(0,0)) +
  scale_y_continuous(limits = c(0,1), expand = c(0,0))+
  geom_abline(intercept = 0, slope = 1, linetype = "dashed",size=0.8)+
annotate("text", x = 0.4, y = 0.25, label = paste0("Lasso (AUC=", lassoModel_train_auc,")"), color = "black", size = 3,hjust=0) +
annotate("text", x = 0.4, y = 0.2, label = paste0("Feed-Forward Neural Networks (AUC=", neuralnetworkModel_train_auc,")"), color = "black", size = 3,hjust=0) +
annotate("text", x = 0.4, y = 0.15, label = paste0("RandomForest (AUC=", randomforestModel_train_auc,")"), color = "black", size = 3,hjust=0) +
annotate("text", x = 0.4, y = 0.1, label = paste0("Liner SVM (AUC=", svmModel_train_auc,")"), color = "black", size = 3,hjust=0) +
  annotate("text", x = 0.4, y = 0.05, label = paste0("XGBOOST (AUC=", XGBOOSTModel_train_auc,")"), color = "black", size = 3,hjust=0) 

  fig
ggsave(fig,file="IPM.roc.compare.png",width = 8,height = 5,limitsize = F)
ggsave(fig,file="IPM.roc.compare.svg",width = 8,height = 5,limitsize = F)
#ggsave(fig,file="IPM.roc.compare.pdf",width = 8,height = 5,limitsize = F)



setwd("D://R/projects/Genskey/RJ_PA_resistantance_prediction/20230423MachineLearingCompare/mem/")


input<-read.table("lm.input.xls",header=T,row.names =1,sep="\t")
input$Group <- ifelse(
  input$Group == 'R',
  1,
  0
)
input$Group = factor(input$Group)


fitControl <- trainControl(method = "cv", number = 10)
##LASSO
trainIndex <- createDataPartition(input$Group, p = 1, list = FALSE)
train <- input[trainIndex, ]
test <- input[-trainIndex, ]

lassoModel <- train(Group ~ .,
                    data = train,
                    method = "glmnet",
                    trControl = fitControl,
                    tuneGrid = expand.grid(alpha = 1, lambda = seq(0, 1, by = 0.01)))
# 训练集AUC
lassoModel_train_pred <- predict(lassoModel, newdata = train, type = "prob")[,2]
lassoModel_train_roc <- roc(train$Group, lassoModel_train_pred)
lassoModel_train_auc<-round(lassoModel_train_roc$auc,3)

# # 测试集AUC
# lassoModel_test_pred <- predict(lassoModel, newdata = test, type = "prob")[,2]
# lassoModel_test_roc <- roc(test$Group, lassoModel_test_pred)
# lassoModel_test_auc<-round(lassoModel_test_roc$auc,3)

##lm
svmModel <- train(Group ~ .,
                  data = train,
                  method = "svmLinear",
                  trControl = fitControl)
# 训练集AUC
svmModel_train_pred <- predict(svmModel, newdata = train)
svmModel_train_pred <- as.numeric(svmModel_train_pred)
svmModel_train_roc <- roc(train$Group, svmModel_train_pred)
svmModel_train_auc<-round(svmModel_train_roc$auc,3)

# # 测试集AUC
# svmModel_test_pred <- predict(svmModel, newdata = test)
# svmModel_test_pred <- as.numeric(svmModel_test_pred)
# svmModel_test_roc <- roc(test$Group, svmModel_test_pred)
# svmModel_test_auc<-round(svmModel_test_roc$auc,3)


##randomforest
randomforestModel <- train(Group ~ ., 
                           data = train, 
                           method = "ranger",
                           trControl = fitControl)
# 训练集AUC
randomforestModel_train_pred <- predict(randomforestModel, newdata = train)
randomforestModel_train_pred <- as.numeric(randomforestModel_train_pred)
randomforestModel_train_roc <- roc(train$Group, randomforestModel_train_pred)
randomforestModel_train_auc<-round(randomforestModel_train_roc$auc,3)

# # 测试集AUC
# randomforestModel_test_pred <- predict(randomforestModel, newdata = test)
# randomforestModel_test_pred <- as.numeric(randomforestModel_test_pred)
# randomforestModel_test_roc <- roc(test$Group, randomforestModel_test_pred)
# randomforestModel_test_auc<-round(test_roc$auc,3)

##神经网络
neuralnetworkModel <- train(Group ~ ., 
                            data = train, 
                            method = "nnet",
                            trControl = fitControl)
# 训练集AUC
neuralnetworkModel_train_pred <- predict(neuralnetworkModel, newdata = train)
neuralnetworkModel_train_pred <- as.numeric(neuralnetworkModel_train_pred)
neuralnetworkModel_train_roc<- roc(train$Group, neuralnetworkModel_train_pred)
neuralnetworkModel_train_auc <-round(roc(train$Group, neuralnetworkModel_train_pred)$auc,3)

# # 测试集AUC
# neuralnetworkModel_test_pred <- predict(neuralnetworkModel, newdata = test)
# neuralnetworkModel_test_pred <- as.numeric(neuralnetworkModel_test_pred)
# neuralnetworkModel_test_roc<-roc(test$Group, neuralnetworkModel_test_pred)
# neuralnetworkModel_test_auc <- round(neuralnetworkModel_test_roc$auc,3)


#XGBOOST
##神经网络
XGBOOSTModel <- train(Group ~ ., 
                      data = train, 
                      method = "xgbTree",
                      trControl = fitControl)
# 训练集AUC
XGBOOSTModel_train_pred <- predict(XGBOOSTModel, newdata = train)
XGBOOSTModel_train_pred <- as.numeric(XGBOOSTModel_train_pred)
XGBOOSTModel_train_roc<- roc(train$Group, XGBOOSTModel_train_pred)
XGBOOSTModel_train_auc <-round(roc(train$Group, XGBOOSTModel_train_pred)$auc,3)
# 
# # 测试集AUC
# XGBOOSTModel_test_pred <- predict(XGBOOSTModel, newdata = test)
# XGBOOSTModel_test_pred <- as.numeric(XGBOOSTModel_test_pred)
# XGBOOSTModel_test_roc<-roc(test$Group, XGBOOSTModel_test_pred)
# XGBOOSTModel_test_auc <- round(XGBOOSTModel_test_roc$auc,3)

roc_data_train <- rbind(
  data.frame(fpr = 1-lassoModel_train_roc$specificities, tpr = lassoModel_train_roc$sensitivities, Model = "LASSO"),
  data.frame(fpr = 1-randomforestModel_train_roc$specificities, tpr = randomforestModel_train_roc$sensitivities, Model = "RandomForest"),
  data.frame(fpr = 1-neuralnetworkModel_train_roc$specificities, tpr = neuralnetworkModel_train_roc$sensitivities, Model = "Feed-Forward Neural Networks"),
  data.frame(fpr = 1-svmModel_train_roc$specificities, tpr = svmModel_train_roc$sensitivities, Model = "Liner SVM"),
  data.frame(fpr = 1-XGBOOSTModel_train_roc$specificities, tpr = XGBOOSTModel_train_roc$sensitivities, Model = "XGBOOST")
  
)


fig<-  ggplot() +  
  geom_path(data = roc_data_train, aes(x = fpr, y = tpr, color = Model), size=0.8)  +
  labs(x = "False Positive Rate", y = "True Positive Rate", color = "Model") +
  scale_color_lancet() + scale_color_lancet()+
  ggtitle("MEM ROC Curves for Different Models") +
  theme(plot.title = element_text(hjust = 0.5))+
  theme(axis.text = element_text(size = 12, color="black", vjust=0.5, hjust=0.5)) + 
  theme(axis.title= element_text(size = 12, color="black", vjust=0.5, hjust=0.5))+
  theme_bw()+
  theme(legend.text = element_text(color = 'black',size = 12, family = 'Arial', face = 'plain'),
        panel.background = element_blank(),
        plot.title = element_text(hjust = 0.5, size = 12),
        panel.grid = element_blank(),
        axis.text = element_text(color = 'black',size = 12, family = 'Arial', face = 'plain'),
        axis.text.x = element_text(angle = 0),
        axis.title = element_text(color = 'black',size = 12, family = 'Arial', face = 'plain'),
        axis.ticks = element_line(color = 'black'),
        axis.ticks.x = element_blank())+
  scale_x_continuous(limits = c(0,1), expand = c(0,0)) +
  scale_y_continuous(limits = c(0,1), expand = c(0,0))+
  geom_abline(intercept = 0, slope = 1, linetype = "dashed",size=0.8)+
  annotate("text", x = 0.4, y = 0.25, label = paste0("Lasso (AUC=", lassoModel_train_auc,")"), color = "black", size = 3,hjust=0) +
  annotate("text", x = 0.4, y = 0.2, label = paste0("Feed-Forward Neural Networks (AUC=", neuralnetworkModel_train_auc,")"), color = "black", size = 3,hjust=0) +
  annotate("text", x = 0.4, y = 0.15, label = paste0("RandomForest (AUC=", randomforestModel_train_auc,")"), color = "black", size = 3,hjust=0) +
  annotate("text", x = 0.4, y = 0.1, label = paste0("Liner SVM (AUC=", svmModel_train_auc,")"), color = "black", size = 3,hjust=0) +
  annotate("text", x = 0.4, y = 0.05, label = paste0("XGBOOST (AUC=", XGBOOSTModel_train_auc,")"), color = "black", size = 3,hjust=0) 

fig
ggsave(fig,file="MEM.roc.compare.png",width = 8,height = 5,limitsize = F)
ggsave(fig,file="MEM.roc.compare.svg",width = 8,height = 5,limitsize = F)
#ggsave(fig,file="MEM.roc.compare.pdf",width = 8,height = 5,limitsize = F)



for (j in names(getModelInfo()[9])){
   Model <- train(Group ~ .,
                              data = input,
                              method = j)
                          #    trControl = fitControl)
  # 训练集AUC
  train_pred <- predict(Model, newdata = train)
  train_pred <- as.numeric(train_pred)
  train_auc <- roc(train$Group, train_pred)$auc
  cat(j,"train_auc: ", train_auc, "\n")
  # 测试集AUC
  test_pred <- predict(neuralnetworkModel, newdata = test)
  test_pred <- as.numeric(test_pred)
  test_auc <- roc(test$Group, test_pred)$auc
  cat(j,"test_auc: ", test_auc, "\n")
}
