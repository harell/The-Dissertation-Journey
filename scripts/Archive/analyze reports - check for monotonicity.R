################################################################################
# Analyze Reports - Check for Monotonicity
################################################################################
## Initialization
cat("\014"); rm(list = ls())
source("scripts/load_libraries.R")
invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))
options(digits=3)


################
# Get the data #
################
reports_folder = file.path(getwd(),"reports")
reports = import.reports(reports_folder)
reports = dplyr::arrange(reports,Policy,Repetition)
colnames(reports)


##################
# Pro-processing #
##################
unique_params = unique(reports[,c("Policy","Repetition")])

for(u in 1:nrow(unique_params)){
    ## Setup
    current_Policy = unique_params[u,"Policy"]
    current_Repetition = unique_params[u,"Repetition"]
    cat("\n# ", "Policy/Repetition: ", current_Policy, "/", current_Repetition, sep="")
    ## Subset the data
    report = subset(reports,
                    Policy==current_Policy & Repetition==current_Repetition)
    ## Check for Monotonicity in Nl_minority
    x = report[,"Nl_minority"]
    if(any(diff(x)<0)) 
        cat("\tNot good",sep="")
    else
        cat("\tOK",sep="")
    ## Check for NAs in Nl_minority
    if(any(is.na(x))) 
        cat("\tFound NA's",sep="")
} # end for unique_params