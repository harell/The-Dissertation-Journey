# ################################################################################
# # Unit testing for split_dataset 
# ################################################################################
# require(testthat)
# context("Load Dataset")
# 
# 
# #####################
# # 1. Initialization #
# #####################
# source("functions/load_dataset.R")
# 
# 
# #################################
# # 2. Generate syntactic dataset #
# #################################
# dataset_name = c("Letter",       # 1
#                  "Satimage",     # 2
#                  "Abalone",      # 3
#                  "Adult")        # 4
# 
# 
# ##############################################################
# # test that load_dataset() returns standardize columns names #
# ##############################################################
# test_that("load_dataset returns standardize columns names for all available datasets", {
#     for(k in 1:length(dataset_name)){
#         dataset = load_dataset(dataset_name=dataset_name[k])
#         p = ncol(dataset) - 1
#         # Check col names
#         for(j in 1:(length(dataset_name)-1))
#             expect_equal(colnames(dataset)[j],paste0('X',j))
#         expect_equal(colnames(dataset)[p+1],'label')
#     } # end for dataset_name
# })
# 
# 
# ####################################################################
# # test that load_dataset() displays information about the datasets #
# ####################################################################
# test_that("load_dataset returns standardize columns names for all available datasets", {
#     load_dataset(NA)
# })
# 
# 
