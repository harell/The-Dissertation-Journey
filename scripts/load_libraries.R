# Sys.setlocale("LC_TIME", "English") #uses english opertaing system naming convention
#' 1. Load Libraries
#' 2. Environment Variables


################################################################################
## Load Libraries
################################################################################
## Github packages
# if (!require("devtools")) {
#         install.packages("devtools")
#         require("devtools")
# }
## Rtools
# if (!require("installr")) install.packages("installr")
# installr::install.Rtools()
## R for Data Science
# <http://r4ds.had.co.nz/>
# devtools::install_github("hadley/tidyverse")


# CRAN packages
packages.loader <- function(packages.list){
    suppressPackageStartupMessages(
        for (p in packages.list){
            if(!require(p, character.only=TRUE)){
                install.packages(p,dep=TRUE) # install form CRAN
                require(p, character.only=TRUE)
            } # end if require
        } # end for packages list
    ) # end suppressPackageStartupMessages
} # end functions packages.loader
packages.list = c("testthat","profvis",                   # Development tools for R
                  "dplyr","data.table","reshape2",        # Data Manipulation Tools
                  "Matrix",                               # Sparse and Dense Matrix Classes and Methods
                  "e1071","kernlab","ROCR","glmnet",      # Classification Tools
                  "ggplot2","gridExtra","plotly",         # Visualization Tools
                  "car","lattice","animation",            #
                  "httr",                                 # Prerequisites for plotly
                  "doParallel","foreach",                 # Parallel Tools
                  "fitdistrplus")                         # Fit of a Parametric Distribution     
packages.loader(packages.list)
## Clean Up
rm(packages.list, packages.loader)


################################################################################
## Environment Variables
################################################################################
pal <- colorRampPalette(c("purple","gold4","steelblue3","green4","red")) # returns a function

policies_metadata = data.frame(
    matrix(
        c(  # ORIGINAL NAME             | NEW NAME                     | ACRONYM     | COLOR      | LINE | PCH
            # SVM
            "random_instances_SVM",      "RANDOM-INSTANCES",      "RANDOM-INSTANCES", pal(05)[01], 1,     15,
            "random_policy_SVM",         "SEMI-UNIFORM",          "SEMI-UNIFORM",     pal(05)[02], 1,     16,
            "max_tuv_SVM",               "INFORMATIVENESS",       "INFORMATIVENESS",  pal(05)[03], 1,     17,
            "greedy_SVM",                "GREEDY",                "GREEDY",           pal(05)[04], 1,     18,
            "eps_greedy_SVM",            "eps-GREEDY",            "eps-GREEDY",       pal(05)[05], 1,     8,
            # GLM
            "random_instances_GLM",      "RANDOM-INSTANCES",      "RANDOM-INSTANCES", pal(05)[01], 1,     15,
            "random_policy_GLM",         "SEMI-UNIFORM",          "SEMI-UNIFORM",     pal(05)[02], 1,     16,
            "max_tuv_GLM",               "INFORMATIVENESS",       "INFORMATIVENESS",  pal(05)[03], 1,     17,
            "greedy_GLM",                "GREEDY",                "GREEDY",           pal(05)[04], 1,     18,
            "eps_greedy_GLM",            "eps-GREEDY",            "eps-GREEDY",       pal(05)[05], 1,     8,
            # Ensemble
            "random_instances_Ensemble", "RANDOM-INSTANCES", "RANDOM-INSTANCES",      pal(05)[01], 1,     15,
            "random_policy_Ensemble",    "SEMI-UNIFORM",     "SEMI-UNIFORM",          pal(05)[02], 1,     16,
            "max_tuv_Ensemble",          "INFORMATIVENESS",  "INFORMATIVENESS",       pal(05)[03], 1,     17,
            "greedy_Ensemble",           "GREEDY",           "GREEDY",                pal(05)[04], 1,     18, 
            "eps_greedy_Ensemble",       "eps-GREEDY",       "eps-GREEDY",            pal(05)[05], 1,     8
        ),
        ncol=6,byrow=T),stringsAsFactors=FALSE)  
colnames(policies_metadata) = c("names_original","names_new","acronym","col","lty","pch")
policies_metadata$lty       = as.numeric(policies_metadata$lty)
policies_metadata$pch       = as.numeric(policies_metadata$pch)
## Clean Up
rm(pal)



# Resources
## Colors
# <http://bxhorn.com/wp-content/uploads/2013/12/RColors1.png>
## Point types
# <http://www.statmethods.net/advgraphs/parameters.html>
# 15: Square
# 16: Circle
# 17: Triangle




