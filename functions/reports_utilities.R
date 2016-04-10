################################################################################
# Reports Utilities
################################################################################
#' 1. import.reports; Import all the reports from the dest folde


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
        report = read.csv(reports_list[r])
        report[,"DATABASE_NAME"] = reports_metadata[r,"DATABASE_NAME"]
        reports = rbind(reports, report)
    } # end binding reports with metadata
    
    
    return(reports)
} # import.reports