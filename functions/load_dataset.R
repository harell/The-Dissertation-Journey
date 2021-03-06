#' Load dataset
#' 
#' @Xi i=1,...,P are the independent variables
#' @verbose if set to TRUE, information about the dataset is presented
#' -1 majority class
#' +1 minority class
#' 
load_dataset <- function(dataset_name, verbose=FALSE){
    dataset_name = tolower(dataset_name[1])
    
    # Display datasets infomration
    known_datasets = c("bank","letter","satimage","abalone","adult")
    if(is.na(dataset_name)){
        for(dataset_name in known_datasets) load_dataset(dataset_name,verbose=TRUE)
        return()
    } # end if dataset_name is NA
    
    if(dataset_name=="bank"){
        dataset = read.csv(file.path(getwd(),"data",dataset_name,"dataset.csv"))
        dataset = dataset[,c("age","job","marital","education","default","balance","housing","loan","label")]
        dataset$label = factor(ifelse(dataset[,"label"]=="yes","minority","majority"))
        colnames(dataset) = c(paste0("X",1:(ncol(dataset)-1)),"label")
        
    } else if(dataset_name=="letter"){
        dataset = read.csv(file.path(getwd(),"data",dataset_name,"dataset.csv"))
        dataset$label = factor(ifelse(dataset[,1]=="A","minority","majority"))
        dataset = dataset[,-1]
    } else if (dataset_name=="satimage"){
        dataset = read.csv(file.path(getwd(),"data",dataset_name,"dataset.csv"))
        dataset$label = factor(ifelse(dataset[,"label"]==4,"minority","majority"))
    } else if (dataset_name=="abalone"){
        # biology dataset (sea ears)
        # https://en.wikipedia.org/wiki/Abalone
        dataset = read.csv(file.path(getwd(),"data",dataset_name,"dataset.csv"))
        dataset$label = factor(ifelse(dataset[,"Rings"]==7,"minority","majority"))
        dataset = dataset[,-9]
    } else if (dataset_name=="adult"){
        dataset = read.csv(file.path(getwd(),"data",dataset_name,"dataset.csv"))
        dataset$label = factor(ifelse(dataset[,"label"]==' >50K',"minority","majority"))
    } else
        stop("dataset name is worng")
    
    #########################
    # Remove rows with NA's #
    #########################
    dataset = dataset[complete.cases(dataset),]
    
    
    ###############################
    # Display dataset information #
    ###############################
    if(verbose){
        N_minority = sum(dataset[,"label"]=="minority")
        N_majority = sum(dataset[,"label"]=="majority")
        N = N_minority+N_majority
        p = ncol(dataset)-1
        cat('\n# ',toupper(dataset_name[1]),' has n/p ', paste0(N,"/",p,": "),
            N_minority, ' (',round(100*N_minority/N),'%) minority', ' and ', 
            N_majority, ' (',round(100*N_majority/N),'%) majority', ' instances', 
            ', that is Imb.R=',round(N_majority/N_minority,1),
            sep='')
    }
    
    
    
    # Set colomn names
    colnames(dataset) = c(paste0("X",1:(ncol(dataset)-1)),"label")  
    return(dataset)
} # end load_dataset