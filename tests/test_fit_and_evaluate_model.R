################################################################################
# Unit testing for fit_and_evaluate_model 
################################################################################
require(testthat)
context("Fitting and Evaluating model")

#####################
# 1. Initialization #
#####################
# source("scripts/load_libraries.R")
# source("functions/fit_and_evaluate_model.R")
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


#############################################################################
# test that fit_and_evaluate_model() returns the currect criteria in a list #
#############################################################################
test_that("split_dataset encompass the whole dataset", {
    index_list = split_dataset(dataset[,1:p],dataset[,p+1],
                               1/10, 2015,
                               1/3, 2017)
    info_list = fit_and_evaluate_model(train_set=dataset[index_list[["index_train"]],],
                                           test_set=dataset[index_list[["index_test"]],],
                                           inducer="RF",
                                           seed=1984)
    expect_that(info_list, is_a("list"))
    expect_that(info_list$AUC, is_a("numeric"))
})