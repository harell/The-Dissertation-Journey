################################################################################
# Reports Utilities
################################################################################
#' 1. import.reports; Import all the reports from the dest folder
#' 2. SparseMatrix_2_LongDataFrame; convert the estimated probabilities into a 
#'    long data frame
#' 3. find_the_purchased_instances;
#' 4. AUC_by_curve_integration; calculate the AUC of a curve
#' 


##################
# import.reports #
##################
import.reports <- function(reports_folder="./reports")
{
    # List the (csv) reports in the folder
    reports_list = list.files(pattern="[.]csv$", path=reports_folder, full.names=TRUE)
    
    
    # Phrase the reports names
    reports_metadata = data.frame(DATABASE_NAME=NA)
    for(k in 1:length(reports_list)){
        #' Find the indices of the metadata in the file name.
        #' The metadata is encapsulated between () (i.e. round brackets)
        index_metadata = gregexpr("\\((.*?)\\)", reports_list[k], TRUE)
        #' Check that the number of sub string composing the file name is as 
        #' defined in reports_metadata
        #stopifnot(ncol(reports_metadata)==length(index_metadata[[1]]))
        
        ## Extract the sub string to the metadata data frame
        for(l in 1:ncol(reports_metadata)){
            match_start  = index_metadata[[1]][l]
            match_length = attributes(index_metadata[[1]])$match.length[l]
            reports_metadata[k,l] = substr(reports_list[k],
                                           match_start+1,
                                           match_start+match_length-2)
        } # end extracting sub strings
    } # end extracting list_metadata
    
    
    ## Bind reports and add meta data
    reports = c()
    for(r in 1:length(reports_list)) 
    {
        report = data.table::fread(reports_list[r])
        report = as.data.frame(report)
        report[,"DATABASE_NAME"] = reports_metadata[r,"DATABASE_NAME"]
        reports = rbind(reports, report)
    } # end binding reports with metadata
    
    
    return(reports)
}# import.reports


################################
# SparseMatrix_2_LongDataFrame #
################################
#' @reports_folder RData file destination
#' @Policy the desired policy(ies)
#' @Repetition the desired Repetition(s)
SparseMatrix_2_LongDataFrame <- function(reports_folder="./reports",
                                         Policy=NA,
                                         Repetition=NA)
{
    library(Matrix)
    ##################################
    # Locate and Load the RData file #
    ##################################
    RData_file.path = list.files(pattern="[.]RData$", path=reports_folder, full.names=TRUE)
    load(RData_file.path)
    
    
    #################################
    # Check input arguments for NAs #
    #################################
    if(any(is.na(c(Policy,Repetition)))){
        params = data.frame()
        for(object in ls()){
            if(class(get(object))[1] == "dgCMatrix")
            {
                object_metadata = strsplit(object,"\\.")
                params = rbind(params,
                               data.frame(Policy=object_metadata[[1]][1],
                                          Repetition=object_metadata[[1]][2]))
            }# if class
        }# for environment_objects
        if(any(is.na(Policy)))     Policy = as.character(unique(params$Policy))
        if(any(is.na(Repetition))) Repetition = sort(as.numeric(as.character(unique(params$Repetition))))
    }# if is.na
    
    
    ############################################
    # Define the desired sparse matrices names #
    ############################################
    params = expand.grid(Policy=Policy,
                         Repetition=Repetition,
                         stringsAsFactors=FALSE)
    params$Name = paste0(params$Policy,".",params$Repetition)   
    
    
    #########################################################
    # Bind the desired matrices to a long format data frame #
    #########################################################
    RData_long_format = data.frame()
    for(p in 1:nrow(params))
    {
        cat("\n# Loading sparse matrix", p,"/", nrow(params))
        ## Get the desired matrix
        current_matrix = get(params[p,"Name"])
        ## Convert current sparse matrix to a data.frame
        current_df = data.frame(Policy=params[p,"Policy"],
                                Repetition=params[p,"Repetition"],
                                Epoch=summary(current_matrix)$j-1,
                                ID=summary(current_matrix)$i,
                                Est=summary(current_matrix)$x)
        ## Add the true class
        current_df$Class = ground_truth_labels_vector[current_df$ID]
        ## Accumulate results
        RData_long_format = rbind(RData_long_format,current_df)
    }# end for RData_long_format
    
    
    ################
    # Add metadata #
    ################
    # Add dataset name
    index_metadata = gregexpr("\\((.*?)\\)", RData_file.path, TRUE)
    match_start    = index_metadata[[1]][1]
    match_length   = attributes(index_metadata[[1]])$match.length[1]
    DATABASE_NAME  = substr(RData_file.path,
                            match_start+1,
                            match_start+match_length-2)
    # Add majority/minority ratio
    Imb.R = round(table(ground_truth_labels_vector)["majority"]/table(ground_truth_labels_vector)["minority"],1)
    Inducer = rep(NA,nrow(RData_long_format))
    Inducer[grepl("SVM",as.character(RData_long_format$Policy))] = "SVM"
    Inducer[grepl("GLM",as.character(RData_long_format$Policy))] = "GLM"
    Inducer[grepl("Ensemble",as.character(RData_long_format$Policy))] = "Ensemble"
    Inducer = factor(Inducer)
        
    RData_long_format = cbind(DATABASE_NAME=as.factor(DATABASE_NAME),
                              Imb.R=as.factor(Imb.R),
                              Inducer=Inducer,
                              RData_long_format)
    
    
    # RData_long_format = dplyr::arrange(RData_long_format,Policy,Repetition,Epoch,ID)
    return(RData_long_format)
}# SparseMatrix_2_LongDataFrame


################################
# find_the_purchased_instances #
################################
#' @est_prob_long long data frame of estimated probabilities resulted from 
#'                SparseMatrix_2_LongDataFrame
find_the_purchased_instances <- function(est_prob_long)
{
    params = unique(est_prob_long[,c("Policy","Repetition","Epoch")])
    sub_est_prob_long = data.frame()
    
    for(s in 1:nrow(params)){
        cat("\n# Finding the purchased instances",s,"/",nrow(params))
        chosen_Policy     = params[s,"Policy"]
        chosen_Repetition = params[s,"Repetition"]
        chosen_Epochs     = c(params[s,"Epoch"],params[s,"Epoch"]+1)
        
        ## Subset the long data frame
        sub_long_format = subset(est_prob_long, 
                                 Policy %in% chosen_Policy &
                                     Repetition %in% chosen_Repetition &
                                     Epoch %in% chosen_Epochs)
        ## Find the IDs of the t and t+1 epoches
        ID1 = subset(sub_long_format, Epoch %in% chosen_Epochs[1], select=ID)
        ID2 = subset(sub_long_format, Epoch %in% chosen_Epochs[2], select=ID)
        ## Find which IDs where in epoch t but not in epoch t+1 (because they were purchased)
        chosen_ID = unlist(setdiff(ID1,ID2))
        ## Subset the purchased instanses
        sub_long_format = subset(sub_long_format, 
                                 Policy %in% chosen_Policy &
                                     Repetition %in% chosen_Repetition &
                                     Epoch %in% chosen_Epochs[1] &
                                     ID %in% chosen_ID)
        
        sub_est_prob_long = rbind(sub_est_prob_long,sub_long_format)                       
    }# end params 
    
    return(sub_est_prob_long)
}# find_the_purchased_instances


############################
# AUC_by_curve_integration #
############################
#' @x x coordinate
#' @y y coordinate
#'
AUC_by_curve_integration <- function(x,y,
                                     xmin=NA,xmax=NA,
                                     ymin=NA,ymax=NA)
{
    x = unlist(x)
    y = unlist(y)
    if(is.na(xmin)) xmin = min(x)
    if(is.na(xmax)) xmax = max(x)
    if(is.na(ymin)) ymin = min(y)
    if(is.na(ymax)) ymax = max(y)
    #          a
    #     ___________
    #    /           \
    #   /          h \ S_max = (a+b)*h/2
    #  /      b      \
    #  ---------------
    # a = ymax + xmin
    # b = xmax - xmin
    # h = ymax - ymin
    # S_max = (a+b)*h/2
    
    x = x/(xmax-xmin)
    y = y/(ymax-ymin)
    
    S = vector("numeric",length(x)-1)
    for(i in 2:length(x)){
        a = x[i-1]
        b = x[i]
        f_a = y[i-1]
        f_b = y[i]
        # Trapezoidal rule
        # https://en.wikipedia.org/wiki/Trapezoidal_rule
        S[i] = ((b-a)/2)*(f_a+f_b)
    }
    
    return(sum(S))
} #end AUC_by_curve_integration