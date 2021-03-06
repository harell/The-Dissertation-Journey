#' Active learning with "Query by SVM"
#' 
query_svm <- function(labeled_set,
                      unlabeled_set,
                      num_query=NA)
{
    ##################
    # Initialization #
    ##################
    n = nrow(unlabeled_set)
    p = ncol(unlabeled_set)-1
    # Empty unlabeled set
    if(n==0)
        return(as.list(data.frame(index=NULL, confident=NULL, rank=NULL)))
    
    
    ################
    # Disagreement #
    ################
    #################################
    # Fit model to the training-set #
    #################################
    set.seed(20160323)
    ## e1071 package
    model_e1071 = e1071::svm(label ~ ., data=labeled_set,
                             kernel="radial", cost=1e0,
                             scale=T, probability=TRUE)
    y.te_hat = predict(model_e1071, unlabeled_set, probability=TRUE)
    y.te_hat = attr(y.te_hat, "probabilities")
    predictions = as.vector(y.te_hat[,"minority"])
    
    
    ###################
    # Find the offset #
    ###################
    ## Option 1: Fit beta distribution to the labeled-set conditioned on the minority class
    # y.tr_hat = predict(model_e1071, labeled_set, probability=TRUE)
    # y.tr_hat = attr(y.tr_hat, "probabilities")[,"minority"]
    # tr.minority.ind = labeled_set[,"label"] %in% "minority" 
    # BETA_parms = tryCatch(
    #     {
    #         beta.tr.minority = fitdistrplus::fitdist(y.tr_hat[tr.minority.ind], "beta")
    #         alpha_MLE = beta.tr.minority$estimate[1]
    #         beta_MLE  = beta.tr.minority$estimate[2]
    #         names(alpha_MLE) = names(beta_MLE) = NULL
    #         list(alpha_MLE=alpha_MLE, beta_MLE=beta_MLE)
    #     }, error = function(cond){
    #         return(list(alpha_MLE=0.5,beta_MLE=0.5)) # -> offset = 0.5/(0.5+0.5) = 0.5
    #     }# end error
    # )# end tryCatch
    # alpha_MLE = BETA_parms[["alpha_MLE"]]
    # beta_MLE  = BETA_parms[["beta_MLE"]]  
    # offset    = alpha_MLE/(alpha_MLE+beta_MLE)
    
    ## Option 2: Fix offset
    offset = 0.5
    
    
    ################
    # Disagreement #
    ################
    informativeness  = abs(predictions-offset)                  # predictions is the informativeness quantity up to a scaling factor
    minority_rank    = rank(1-predictions, ties.method="first") # the closer to 1 the rank is, the better

    
    ##################
    # Query and Rank #
    ##################
    #' We apply ranking only on the unlabeled pool
    #' The closer an instance rank is to 0, the less confident we are about its true class label
    query = data.frame(index=1:n,
                       confident=informativeness,
                       rank=rank(informativeness))
    #' head(query,3)
    #       index confident  rank
    # 1     1     0.2924867  168
    # 2     2     0.9444969  544
    # 3     3     0.8582473  495
    
    
    #' Determine the order of the unlabeled observations by informativeness
    #' measure.
    query = query[order(query$rank, decreasing=FALSE),]
    #' head(query,3)
    #       index    confident       rank
    # 349   349      0.0002911843    1
    # 392   392      0.0013148428    2
    # 356   356      0.0019311362    3
    
    
    ################
    # Arrange Data #
    ################
    if(is.na(num_query) | num_query>n) num_query=n
    query = query[1:num_query, ] # subset query 
    
    
    return(as.list(query))
} # end query_svm


# as.list(query)
# $index
# [1] 265 540 260 241 439   3 174 215 339  58 580 344  22 295  70 276  55 560 200  16
# [21] 546 481 117  62  10   2 423 387  45 452  42 267 419 125 389 470 493 219 335 468
# [41] 376 133  48 236 585 511 322 182  28 185
# 
# $confident
# [1] 0.4421500 0.4492891 0.4587982 0.4593601 0.4595304 0.4616977 0.4625850 0.4629902
# [9] 0.4630032 0.4678740 0.4680590 0.4684109 0.4684325 0.4696240 0.4700450 0.4724061
# [17] 0.4729881 0.4730749 0.4759688 0.4761249 0.4762985 0.4765847 0.4770680 0.4771581
# [25] 0.4773700 0.4778350 0.4778717 0.4779820 0.4780752 0.4782133 0.4783216 0.4786879
# [33] 0.4787826 0.4788859 0.4789874 0.4790288 0.4793916 0.4796133 0.4796662 0.4797532
# [41] 0.4798744 0.4799151 0.4799810 0.4800343 0.4800785 0.4801510 0.4805574 0.4805965
# [49] 0.4806909 0.4807460
# 
# $rank
# [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27
# [28] 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50
