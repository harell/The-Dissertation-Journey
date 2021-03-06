################################################################################
# Unit testing for split_dataset 
################################################################################
require(testthat)
context("Split Dataset")


#####################
# 1. Initialization #
#####################
# source("functions/split_dataset.R")


#################################
# 2. Generate syntactic dataset #
#################################
p = 10
n = 100*p
## Imbalance ratios (#minority/#majority)
Imb.R = 1
n_majority = round(n/(1+Imb.R))
n_minority = n-n_majority
## Generate the design matrix
set.seed(2016)
x_majority = MASS::mvrnorm(n_majority, mu=rep(-1,p), Sigma=diag(rep(1,p)))
x_minority = MASS::mvrnorm(n_minority, mu=rep(+1,p), Sigma=diag(rep(1,p)))

x     = rbind(x_majority, x_minority)
label = factor(c(rep("majority",n_majority),rep("minority",n_minority)))
### Assamble the variables
dataset           = data.frame(x,label)
colnames(dataset) = c(paste0("X",1:p),"label")  


#########################################################
# test that split_dataset() encompass the whole dataset #
#########################################################
test_that("split_dataset encompass the whole dataset", {
    index_list = split_dataset(X=dataset[,1:p], y=dataset[,p+1],
                               train_pct=1/10, seed_train=2015,
                               test_pct=1/3, seed_test=2017,
                               imbalance_ratio=NA)
    
    complete_index = c(index_list[[1]],index_list[[2]],index_list[[3]])
    
    expect_that(index_list, is_a("list"))
    expect_equal(length(complete_index),n)
})


#############################################
# test that split_dataset() is reproducable #
#############################################
test_that("split_dataset is reproducible", {
    index_list_1 = split_dataset(dataset[,1:p],dataset[,p+1],
                                 1/10, 2015,
                                 1/3, 2017)
    index_list_2 = split_dataset(dataset[,1:p],dataset[,p+1],
                                 1/10, 2015,
                                 1/3, 2017)
    index_list_3 = split_dataset(dataset[,1:p],dataset[,p+1],
                                 1/10, 2016,
                                 1/3, 2017)
    # Test query_random()
    expect_that(index_list_1 , is_identical_to(index_list_2))
    expect_that(length(setdiff(index_list_1,index_list_3)), is_more_than(0))
})


################################################################################
# test that split_dataset() under-sample the data (when imbalance_ratio exist) #
################################################################################
test_that("split_dataset under-sample the data (when imbalance_ratio exist)", {
    index_list = split_dataset(X=dataset[,1:p], y=dataset[,p+1],
                               train_pct=1/10, seed_train=2017,
                               test_pct=1/3, seed_test=2017,
                               imbalance_ratio=3)
    index_train     = index_list[["index_train"]]
    index_test      = index_list[["index_test"]]
    index_unlabeled = index_list[["index_unlabeled"]]

    unlabeled_class_counts = table(dataset[index_unlabeled,p+1])
    unlabeled_ratio        = unlabeled_class_counts[["minority"]]/unlabeled_class_counts[["majority"]]
    unlabeled_ratio
    # complete_index = c(index_list[[1]],index_list[[2]],index_list[[3]])
    # 
    # expect_that(index_list, is_a("list"))
    # expect_equal(length(complete_index),n)
})
