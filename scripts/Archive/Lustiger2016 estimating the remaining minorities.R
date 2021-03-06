################################################################################
# Lustiger2016 - Estimating the Remaining Minorities
################################################################################


##################
# Initialization #
##################
cat("\014"); rm(list = ls())
source("scripts/load_libraries.R")
invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))
options(digits=2)

param = expand.grid(
    # size of train set
    n_tr=(1:10)*100,
    # seed number
    seed_train=2016:2025,
    stringsAsFactors=FALSE)


################
# Load dataset #
################
load_dataset(NA) # display data sets attributes
dataset_name = c("Letter",           # 1
                 "Satimage",         # 2
                 "Abalone",          # 3
                 "Adult")[+2]        # 4
DS = load_dataset(dataset_name)
p = ncol(DS)-1
n = nrow(DS)

param$est.n_te = NA
for(s in 1:nrow(param))
{
    cat("\n# Testing",s,"/",nrow(param))
    #####################
    # Split the dataset #
    #####################
    index_list = split_dataset(X=DS[,1:p], y=DS[,p+1],
                               train_pct=param[s,"n_tr"], 
                               seed_train=param[s,"seed_train"],
                               test_pct=1e3, 
                               seed_test=2306,
                               imbalance_ratio=NA)
    table(DS[index_list[["index_train"]],p+1])
    table(DS[index_list[["index_test"]],p+1])
    
    
    #######################################
    # Assign data-points into their group #
    #######################################
    DS_train     = DS[index_list[["index_train"]],]
    DS_test      = DS[index_list[["index_test"]],]
    DS_unlabeled = DS[index_list[["index_unlabeled"]],]
    DS_labeled   = DS[index_list[["index_labeled"]],]
    
    
    ###############################
    # Fit model on the train set  #
    ###############################
    set.seed(20160323)
    model_svm = e1071::svm(label ~ ., data=DS_train,
                           kernel="radial", cost=1e0,
                           scale=T, probability=TRUE)
    
    
    #########################
    # Predict the test set #
    #########################
    est_te   = predict(model_svm, DS_test, probability=TRUE)
    est_te   = attr(est_te, "probabilities")
    y.tr_svm = as.vector(est_te[,"minority"])
    
    
    param[s,"est.n_te"] = sum(y.tr_svm)
} # end for param

head(param)
# param_agg = aggregate(est.n_te ~ n_tr,
#                       param, 
#                       function(x) c(mean(x),mean(x),mean(x)))
boxplot(est.n_te ~ n_tr, data=param)
abline(h=sum(DS_test$label %in% "minority"), lty=2, col=2)


x1-x2+x3-x4+x5-x6...
