################################################################################
# Unit testing for AUCTM 
################################################################################
require(testthat)
context("AUCTM")


#####################
# Initialization #
#####################
# cat("\014"); rm(list = ls())
# source("scripts/load_libraries.R")
# invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))


################
# Get the data #
################
reports_folder = file.path(getwd(),"reports")
reports = import.reports(reports_folder)
reports = dplyr::arrange(reports, Policy, Repetition)


###################
# Subset the data #
###################
report = subset(reports, 
                (Policy %in% "max_tuv_SVM") & (Repetition %in% 1),
                select=c("Nl","Nl_minority"))
x = report[,"Nl"]
y = report[,"Nl_minority"]
x_max = 1800
y_max = max(y)

##############
# Test AUCTM #
##############
par(mar=c(4,4,1,1), mfrow=c(1,2))
# right trapezoid
AUCTM(x=x, y=y, x_max=3e3, y_max=y_max, plot=T)
# right triangle
AUCTM(x=x, y=y, x_max=3e2, y_max=y_max, plot=T)
