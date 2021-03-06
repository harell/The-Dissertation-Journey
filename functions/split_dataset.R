#' Split dataset
#' 
#' @param X
#' @param y
#' @param train_pct; percentage (fraction) or number (integer)
#' @param seed_train
#' @param test_pct; percentage (fraction) or number (integer)
#' @param seed_test
#' @param imbalance_ratio=N_majority/N_minority, if imbalance_ratio=NA then the 
#' ratio is untouched. Other wise the ratio achieved by under sampling.
#' 
#' @return list of 4 indices vectors namely: 
#' index_train, index_test, index_unlabeled and labeled set
#' 
split_dataset <- function(X, y,
                          train_pct=1/10, seed_train=2015,
                          test_pct=1/2, seed_test=2015,
                          imbalance_ratio=NA)
{
    ###############################
    # Set dataset imbalance ratio #
    ###############################
    # Validate the imbalance_ratio
    if(!is.na(imbalance_ratio) & is.numeric(imbalance_ratio))
        stopifnot(1<=imbalance_ratio)
    # Find the majority and minority class instances indices
    index_majority = (1:nrow(X))[y %in% "majority"]
    index_minority = (1:nrow(X))[y %in% "minority"]
    if(is.numeric(imbalance_ratio) & (1<=imbalance_ratio))
    {
        # Calculate the frequencies of each class
        n_majority = table(y)[["majority"]]
        n_minority = table(y)[["minority"]]
        n          = n_majority + n_minority
        # Calculate the desired frequencies (according to the imbalance ratio)
        n_majority_desired = round(n_minority*imbalance_ratio)
        n_minority_desired = round(n_majority/imbalance_ratio)
        # Data under-sampling
        set.seed(seed_test)
        if(n_minority_desired<=n_minority)
            # under-sample the minority class
            index_minority = sample(index_minority, n_minority_desired)
        else
            # under-sample the majority class
            index_majority = sample(index_majority, n_majority_desired)
    } # end setting dataset imbalance ratio
    
    
    ########################
    # Instances assignment #
    ########################
    index_available = c(index_minority,index_majority)
    n = length(index_available)
    # Assign observation to testing set
    set.seed(seed_test)
    if(0<=test_pct & test_pct<1)      
        index_test = sample(index_available, ceiling(test_pct*n))
    else
        index_test = sample(index_available, test_pct)
    # Assign observation to training set
    THERE_ARE_MINORITY_CASES_IN_THE_TRAINING_SET = FALSE
    set.seed(seed_train)
    while(!THERE_ARE_MINORITY_CASES_IN_THE_TRAINING_SET)
    {
        if(0<=train_pct & train_pct<1)      
            index_train = sample(setdiff(index_available,index_test), ceiling(train_pct*n))
        else
            index_train = sample(setdiff(index_available,index_test), train_pct)
        # Check that the trainins set includes at least 5 minority cases
        THERE_ARE_MINORITY_CASES_IN_THE_TRAINING_SET = table(y[index_train])["minority"] >= 5 
    }# end while
    # Assign observation to unlabeled set
    index_unlabeled = setdiff(index_available, c(index_test,index_train))
    # Assign observation to labeled set
    index_labeled = index_train

    
    ################
    # Sanity Check #
    ################
    n_after_assignment = length(c(index_test,index_train,index_unlabeled))
    stopifnot(n==n_after_assignment)
    
    
    return(list(index_train=index_train,
                index_test=index_test,
                index_unlabeled=index_unlabeled,
                index_labeled=index_labeled))  
} # end split_dataset
