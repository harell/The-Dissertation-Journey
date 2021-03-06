#' Active learning with "Query by Random"
#' 
query_random <- function(labeled_set,
                         unlabeled_set,
                         num_query=NA)
{
    ##################
    # Initialization #
    ##################
    n = nrow(unlabeled_set)
    p = ncol(unlabeled_set)-1
    
    
    ################
    # Disagreement #
    ################
    # create informativeness (disagreement) dummy 
    informativeness = runif(n)
    
    
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
} # end query_random