############################
# Get Started with Testing #
############################
rm(list = ls()); cat("\014")
invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))
source("scripts/load_libraries.R")

# Watches code and tests for changes, rerunning tests as appropriate.
# auto_test(getwd() , file.path(getwd(),"tests")) 
test_dir(file.path(getwd(),"tests"))