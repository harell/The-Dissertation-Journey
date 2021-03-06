#' Fit and Evaluate model
#'
#' @param train_set
#' @param test_set
#' @param inducer; if input argument is a svm object then the function use it 
#'                 to evaluate the datasets. Else first fit the model and then 
#'                 evaluate.
#' @param verbose
#' 
#' @return criteria list
#' 
fit_and_evaluate_model = function(train_set,
                                  test_set,
                                  inducer=c("SVM","GLM"),
                                  seed=1984,
                                  verbose=TRUE){
    return_list = list()
    options(warn=-1)
    
    
    ###############################################
    # Ensure the input space is sufficiently rich #
    ###############################################
    #' Make sure each explanatory variable has variance
    # Check the training set for the above condition
    p = ncol(train_set)-1
    ## Convert multi-level factors to dummy variables in the train set
    train_set_X = train_set[,1:p]
    train_set_y = train_set[,p+1]
    train_set_X = data.frame(model.matrix(~.-1, data=train_set_X))
    ## Transform the new numeric variables into factor variables 
    factor_indicator = !(colnames(train_set_X) %in% colnames(train_set[,-(p+1)]))
    if(sum(factor_indicator)>0)
        for(j in (1:ncol(train_set_X))[factor_indicator])
            train_set_X[,j] = factor(train_set_X[,j], levels=0:1)
    ## Check condition
    for(j in ncol(train_set_X):1)
    {
        if(class(train_set_X[,j]) == "factor"){                        ## Is that a factor variable?
            if((sum(table(train_set_X[,j])>0)) < 2)                    ## Does it have less than 2 unique values?
                train_set_X = train_set_X[,-j]                         ## Drop the variable
        }# factor variable verification
    }# condition check
    # Convert multi-level factors to dummy variables in the test set 
    test_set_X = test_set[,1:p]
    test_set_y = test_set[,p+1]
    test_set_X = data.frame(model.matrix(~.-1, data=test_set_X))
    ## Transform the new numeric variables into factor variables 
    factor_indicator = !(colnames(test_set_X) %in% colnames(test_set[,-(p+1)]))
    if(sum(factor_indicator)>0)
        for(j in (1:ncol(test_set_X))[factor_indicator])
            test_set_X[,j] = factor(test_set_X[,j], levels=0:1)
    # Match the training set and test set column names
    train_set_col_names = colnames(train_set_X)
    test_set_col_names  = colnames(test_set_X)
    matching_col_names  = intersect(train_set_col_names,test_set_col_names)
    train_set_X = train_set_X[,matching_col_names]
    test_set_X  = test_set_X[,matching_col_names]
    
    
    ###############################
    # Standardize variables names #
    ###############################
    train_set = cbind(train_set_X,train_set_y)
    test_set  = cbind(test_set_X,test_set_y)
    rm(train_set_X, train_set_y, test_set_X, test_set_y)
    colnames(train_set) = c(paste0("X",1:(ncol(train_set)-1)),"label")  
    colnames(test_set)  = c(paste0("X",1:(ncol(test_set)-1)),"label")  
    n_te_minority = sum(test_set$label %in% "minority")
    n_te_majority = sum(test_set$label %in% "majority")
    n_tr_minority = sum(train_set$label %in% "minority")
    n_tr_majority = sum(train_set$label %in% "majority")
    # stopifnot(n_tr_minority>0, n_tr_majority>0)
    # stopifnot(n_te_minority>0, n_te_majority>0)
    
    
    #################################
    # Fit model to the training-set #
    #################################
    set.seed(seed)
    
    if(any(class(inducer) %in% c("svm","cv.glmnet"))){
        model = inducer
        return_list[["Model"]] = model
        
    } else if(tolower(inducer) %in% "svm"){
        if(verbose) cat("\n# fitting and evaluating SVM model",
                        "\n# Dataset size",paste0('[',nrow(train_set),"x",ncol(train_set),"]"))
        model = e1071::svm(label ~ ., data=train_set,
                           kernel="radial", cost=1e0,
                           scale=T, probability=TRUE)
        return_list[["Model"]] = model
        
    } else if(tolower(inducer) %in% "glm"){
        if(verbose) cat("\n# fitting and evaluating GLM model",
                        "\n# Dataset size",paste0('[',nrow(train_set),"x",ncol(train_set),"]"))
        model = glmnet::cv.glmnet(x=data.matrix(train_set[,-ncol(train_set)]),
                                  y=train_set[,ncol(train_set)],
                                  family="binomial")
        return_list[["Model"]] = model
        
    } else
        stop("Unknown inducer")
    
    
    #######################################
    # Extract elements of the SVM object  #
    #######################################
    # Support Vectors information
    if(tolower(inducer) %in% "glm" | any(class(inducer) %in% "cv.glmnet"))
    {
        return_list[["SV_total"]]    = NA
        return_list[["SV_minority"]] = NA
        return_list[["SV_majority"]] = NA 
    } else if((tolower(inducer) %in%"svm" | any(class(inducer) %in% "svm"))) {
        SV_index = rownames(model$SV)
        return_list[["SV_total"]]    = length(SV_index)
        return_list[["SV_minority"]] = table(train_set[SV_index,"label"])[["minority"]]
        return_list[["SV_majority"]] = table(train_set[SV_index,"label"])[["majority"]] 
    } # end if glm or svm
    
    
    #########################################
    # Predict the training set and test set #
    #########################################
    # If test-set is empty then don't proceed to observations estimation phase
    if(nrow(test_set)<=0) return(return_list) # no test-set was supplied
    
    if(tolower(inducer) %in% "svm" | any(class(inducer) %in% "svm")){
        
        est_te = predict(model, test_set, probability=TRUE)
        est_te = attr(est_te, "probabilities") 
        predictions_te = unlist(est_te[,"minority"])
        ind_te = as.numeric(names(est_te[,"minority"]))
        
        est_tr = predict(model, train_set, probability=TRUE)
        est_tr = attr(est_tr, "probabilities")
        predictions_tr = unlist(est_tr[,"minority"])
        ind_tr = as.numeric(names(est_tr[,"minority"]))
        
    } else if(tolower(inducer) %in% "glm" | any(class(inducer) %in% "cv.glmnet")){
        
        est_te = predict(model,
                         newx=data.matrix(test_set[,-ncol(test_set)]),
                         s="lambda.min")
        ind_te = as.numeric(rownames(est_te))
        predictions_te = as.numeric(1 / (1 + exp(-est_te)))
        
        est_tr = predict(model,
                         newx=data.matrix(train_set[,-ncol(train_set)]),
                         s="lambda.min")
        ind_tr = as.numeric(rownames(est_tr))
        predictions_tr = as.numeric(1 / (1 + exp(-est_tr)))
        
    }# end prediction
    
    # Replace NA's within the prediction vector with 0 probabilities
    # In case we replace the unseen factor levels with NAs, the corresponding 
    # estimated probabilities are also NA's
    if(any(is.na(predictions_te))) warning("fit_and_evaluate_model detected NAs predictions in test-set and replced then with 0")
    if(any(is.na(predictions_tr))) warning("fit_and_evaluate_model detected NAs predictions in train-set and replced then with 0")
    predictions_te[is.na(predictions_te)] = 0
    predictions_tr[is.na(predictions_tr)] = 0
    
    
    # Store prediction
    test_set_predictions = data.frame("Index"=ind_te,
                                      "Minority_Probability"=predictions_te,
                                      "Ground_Truth"=test_set$label)
    rownames(test_set_predictions) = NULL
    
    train_set_predictions = data.frame("Index"=ind_tr,
                                       "Minority_Probability"=predictions_tr,
                                       "Ground_Truth"=train_set$label)
    rownames(train_set_predictions) = NULL
    
    
    ############################
    # Output model estimations #
    ############################
    return_list[["Test_set_predictions"]]  = test_set_predictions[order(test_set_predictions$Index),]
    return_list[["Train_set_predictions"]] = train_set_predictions[order(train_set_predictions$Index),]
    # If test-set has no minority-class or no majority-class then don't proceed 
    # to model evaluation phase 
    if(n_te_minority<1 | n_te_majority<1) return(return_list) 
    
    
    ##################################
    # Evaluate model on the test-set #
    ##################################
    pred  = ROCR::prediction(predictions_te, test_set[,"label"])
    ## Precision and Recall
    PR_obj        = ROCR::performance(pred, "prec", "rec")
    Recall_vec    = unlist(PR_obj@x.values)[-50:-1] # Remove first 50 values = 0
    Precision_vec = unlist(PR_obj@y.values)[-50:-1] # Remove first 50 values = 0
    ## PRBEP (Precision Recall Break-Even Point)
    Precision_Recall_diff  = abs(Recall_vec-Precision_vec)
    PREBP_index            = which.min(Precision_Recall_diff)[1]
    return_list[["PRBEP"]] = Recall_vec[PREBP_index] #= Precision_vec[PREBP_index]
    ## AUC
    AUC_obj = ROCR::performance(pred,"auc")
    return_list[["AUC"]] = AUC_obj@y.values[[1]]
    ## Lift value as a function of "rate of poisitve predictions"
    LIFT_obj = ROCR::performance(pred, measure="lift", x.measure="rpp")
    return_list[["LIFT"]] = unlist(LIFT_obj@y.values)[1086] # unlist(LIFT_obj@x.values)[[1086]]=0.1
    
    
    options(warn=0)
    return(return_list)
} # end fit_and_evaluate_model
