################################################################################
# Unit testing for query_random 
################################################################################
require(testthat)
context("Query by Random")


#####################
# 1. Initialization #
#####################
# source("functions/query_random.R")
# source("functions/split_dataset.R")


#################################
# 2. Generate syntactic dataset #
#################################
set.seed(2015)
p = 10
n = 100*p
### Imbalance ratios (#minority/#majority)
Imb.R = 1/100
### Generate the design matrix
X <- MASS::mvrnorm(n, mu=rep(0,p), Sigma=diag(rep(1,p)))
### Generate coefficient vector
beta <- round(20*runif(p) - 10,1) # explanatory variables coefficients \in [-10,10]
### Create the dependent variable
y.sd  <- sd(X %*% beta)
noise <- 0*rnorm(n, mean=0, sd=1*y.sd) # Add white noise
### Create the dependent variable
y      <- X %*% beta + noise
labels <- ifelse(y < rep(quantile(y, Imb.R), n), "minority", "majority")
labels <- factor(labels)
### Assamble the variables
dataset <- data.frame(X,y=labels)
colnames(dataset) <- c(paste0("X",1:(ncol(dataset)-1)),"label")  


#########################
# 3. Split the data set #
#########################
index_list = split_dataset(dataset[,1:p],dataset[,p+1],
                           1/10, 2015,
                           1/3, 2017)


###########################################
# test that query_random() returns a list #
###########################################
test_that("query_random returns a list", {
    set.seed(2016)
    query_list = query_random(labeled_set=dataset[index_list[["index_train"]],],
                              unlabeled_set=dataset[index_list[["index_unlabeled"]],],
                              num_query=50)    
    # Test query_random()
    expect_that(query_list, is_a("list"))
})