################################################################################
# SVM sandbox
################################################################################


##################
# Initialization #
##################
rm(list = ls()); cat("\014")
source("scripts/load_libraries.R")
invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))


################
# Load dataset #
################
dataset_name = c("Letter",       # 1
                 "Satimage",     # 2
                 "Abalone",      # 3
                 "Adult")[4]     # 4
dataset = load_dataset(dataset_name)
p = ncol(dataset)-1
n = nrow(dataset)


#####################
# Split the dataset #
#####################
index_list = split_dataset(X=dataset[,1:p], y=dataset[,p+1],
                           train_pct=1/10, seed_train=2015,
                           test_pct=1/3, seed_test=2017)


#######################################
# Assign data-points into their group #
#######################################
DS_train     = dataset[index_list[["index_train"]],]
DS_test      = dataset[index_list[["index_test"]],]
DS_unlabeled = dataset[index_list[["index_unlabeled"]],]
DS_labeled   = dataset[index_list[["index_labeled"]],]
round(prop.table(table(DS_train$label)),2)
round(prop.table(table(DS_test$label)),2)


#################################
# Fit model to the training-set #
#################################
set.seed(20160323)
## e1071 package
model_e1071 = e1071::svm(label ~ ., data=DS_train,
                         kernel="radial", cost=1e0,
                         scale=T, probability=TRUE)
y_hat = predict(model_e1071, DS_test, probability=TRUE)
y_hat = attr(y_hat, "probabilities")
predictions = as.vector(y_hat[,"minority"])
## kernlab package
#<http://127.0.0.1:20239/library/kernlab/html/ksvm.html>
# model_kl = kernlab::ksvm(label ~ ., data=DS_train, 
#                          kernel="rbfdot", C=1e0, 
#                          prob.model=TRUE)
# y_hat = predict(model_kl, DS_test, type="probabilities")
# predictions = as.vector(y_hat[,"minority"])


############################################
# Evaluate the model with the training-set #
############################################
criteria_list = list()
pred  = ROCR::prediction(predictions, DS_test[,"label"])
## AUC
AUC_obj = ROCR::performance(pred,"auc")
criteria_list[["AUC"]] = AUC_obj@y.values[[1]]
## PRBEP (Precision Recall Break-Even Point)
PRBEP_obj = ROCR::performance(pred,"prbe")
criteria_list[["PRBEP"]] = PRBEP_obj@y.values[[1]]
## LIFT 
### Lift value as a function of Cutoff
LIFT_obj = ROCR::performance(pred,"lift")
criteria_list[["LIFT"]] = unlist(LIFT_obj@y.values)[511] # unlist(LIFT_obj@x.values)[[511]]=0.9
plot(LIFT_obj)
### Lift value as a function of "rate of poisitve predictions"
# <http://stats.stackexchange.com/questions/172585/r-lift-chart-analysis-classification-tree-rocr>
LIFT_obj = ROCR::performance(pred, measure="lift", x.measure="rpp")
criteria_list[["LIFT"]] = unlist(LIFT_obj@y.values)[1086] # unlist(LIFT_obj@x.values)[[1086]]=0.1
plot(LIFT_obj)
# ## Precision-recall F measure
# F_obj = ROCR::performance(pred, "f")
# 
# plot(F_obj)
# ## Geometric mean
# G_cutoff = 0.5
# F_obj = ROCR::performance(pred, "f")








#############################################################################
# Plot the test-set estimated probabilities for being in the minority class #
#############################################################################
library("ggplot2")
library("plotly")
est_prob = data.frame(predictions=predictions,labels=DS_test$label)
vline = quantile(predictions,0.5)
## Density plot
p1a <- ggplot(est_prob, aes(x=predictions)) + 
    geom_density(alpha=0.25) + 
    geom_vline(xintercept = round(vline,2))
p1b <- ggplot(est_prob, aes(x=predictions, fill=labels)) + 
    geom_density(alpha=0.25) + 
    theme(legend.position="top") + 
    geom_vline(xintercept = round(vline,2))
# grid.arrange(p1a, p1b, nrow=2)
ggplotly(p1a)
ggplotly(p1b)
## Box plot
p2 <- ggplot(est_prob, aes(x=labels, y=predictions)) + 
    geom_boxplot() +
    geom_hline(yintercept = round(vline,2))
ggplotly(p2)


##############################
# Elements of the svm object #
##############################
# str(model_e1071)
# str(model_kl)

# w_e1071 <- t(model_e1071$coefs) %*% model_e1071$SV
# w_e1071 <- t(model_e1071$coefs) %*% model_e1071$SV

# model_e1071$index



##
#
##
#' predict.svm() gives the decision values which are the distances we are 
#' looking for (up to a scaling constant)
median(predictions)
informativeness = abs(predictions-median(predictions))
rank(c(0,1,0), ties.method="first")
minority_rank    = rank(1-predictions, ties.method="first") # the smaller the rank the better
uncertainty_rank = rank(informativeness)                    # the smaller the rank the less confident we have 

