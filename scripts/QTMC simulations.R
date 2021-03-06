################################################################################
# Quickly Target Minority Cases (QTMC) simulations
################################################################################
# options(error=recover) # debugging mode


##################
# Initialization #
##################
rm(list = ls()); 
# cat("\014")
source("scripts/load_libraries.R")
invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))
options(digits=3)
verbose = TRUE
# Economy mode:
# If FALSE, all the features statistics are computed and store in two files: report and metadata
# If TRUE, only important statistics are computed and store in a report file
# Note, economy mode reduces the computation time significantly (by factor of 2).
ECONOMY_MODE = TRUE


################
# Load dataset #
################
load_dataset(NA) # display data sets attributes
dataset_name = c("Abalone",  # 1
                 "Bank",     # 2
                 "Letter",   # 3
                 "Satimage", # 4
                 "Adult")[1] # 5
DS = load_dataset(dataset_name)
p = ncol(DS)-1
n = nrow(DS)
Imb.R = table(DS[,p+1])[["majority"]]/table(DS[,p+1])[["minority"]]


##############################
# Control simulation nuances #
##############################
param = expand.grid(
    # Number of runs (enter series of values, such as 1:10)
    repetitions=1:20,
    # Number of epochs (if NA then run until pool is exhausted)
    iterations=NA,
    # Explore and Exploit Strategies
    strategy=c("Random_Instances", # 1 RANDOM-INSTANCES
               "Random_Policy",    # 2 SENI-RANDOM
               "Max_TUV",          # 3 INFORMATIVENESS
               "Greedy",           # 4 GREEDY
               "Eps_Greedy")       # 5 eps-GREEDY
    [c(1,2,3,4,5)], 
    # Classifier inducer
    inducer=c("GLM","SVM")[c(2)],
    # Additional parameters to CAL
    num_query=100, 
    # Train set ranom seed 
    seed_train=2016,
    # Train set percentage (fraction) or number (integer)
    train_pct=100,
    # Tess set ranom seed
    seed_test=20160324,
    # Test set percentage (fraction) or number (integer) 
    test_pct=1/3,
    # Data imbalance ratio (if NA the original ratio is preserved)
    imbalance_ratio=NA,
    stringsAsFactors=FALSE)
param$seed_train = param$repetitions + param$seed_train
param$seed_test  = param$repetitions + param$seed_test
param = unique(param)
cat("\n",rep("#",40),
    "\n# Running ",nrow(param)," simulations",
    "\n",rep("#",40), sep="")


##############
# Simulation #
##############
start.time = Sys.time()
cl <- makeCluster(detectCores(), outfile="")   
registerDoParallel(cl)
reports_list <- foreach(
    s = 1:nrow(param),
    .options.multicore=list(preschedule=TRUE),
    .errorhandling='stop') %dopar% {#'remove',#dopar
        #####################
        # Split the dataset #
        #####################
        index_list = split_dataset(X=DS[,1:p], y=DS[,p+1],
                                   train_pct=param[s,"train_pct"], 
                                   seed_train=param[s,"seed_train"],
                                   test_pct=param[s,"test_pct"], 
                                   seed_test=param[s,"seed_test"],
                                   imbalance_ratio=param[s,"imbalance_ratio"])
        N_unlabeled = length(index_list[["index_unlabeled"]])
        N_train = length(index_list[["index_train"]])
        
        
        ##########################
        # Repetition Allocations #
        ########################## 
        iterations = param[s,"iterations"]
        #' If iterations=NA or if the number of desired iteration exceeds the  
        #' numberof available iteration then run simulation until unlabeled pool  
        #' is exhausted
        Q = param[s,"num_query"]
        max_iterations = ceiling(N_unlabeled / Q)
        if(is.na(iterations) | max_iterations<iterations)
            iterations <- max_iterations
        Strategy    = tolower(param[s,"strategy"])
        Inducer     = param[s,"inducer"]
        Policy      = paste(Strategy, Inducer, sep="_")
        r = param[s,"repetitions"]
        repetition_data = data.frame()
        if(!ECONOMY_MODE)
            est_prob_matrix = Matrix::Matrix(0, nrow=nrow(DS), ncol=iterations+1, sparse=TRUE)
        
        
        if(verbose) cat('\n',rep('#',40),
                        '\n','# Starting simulation ',s,'/',nrow(param),
                        ": ", Policy,
                        '\n',rep('#',40),
                        sep='')
        
        
        for(i in 0:iterations){ 
            if(verbose) cat('\n','# Iteration ', i, '/', iterations, sep='')
            #######################################
            # Assign data-points into their group #
            #######################################
            DS_train     = DS[index_list[["index_train"]],]
            DS_test      = DS[index_list[["index_test"]],]
            DS_unlabeled = DS[index_list[["index_unlabeled"]],]
            DS_labeled   = DS[index_list[["index_labeled"]],]
            
            
            ##########################################
            #  Fit model on the labeled data-points  #
            #                   &                    #
            # Evaluate the model on the training set #
            ##########################################
            set.seed(20160322)
            return_list_te = fit_and_evaluate_model(train_set=DS_labeled,
                                                    test_set=DS_test,
                                                    inducer=Inducer)
            
            
            ############################
            # Probability Measurements #
            ############################
            mdl = return_list_te[["Model"]]
            # Get probabilities for the labeled and unlabeled data set
            return_list_ul = fit_and_evaluate_model(train_set=DS_labeled,
                                                    test_set=DS_unlabeled,
                                                    inducer=mdl)
            unlabeled_est = return_list_ul$Test_set_predictions
            labeled_est   = return_list_ul$Train_set_predictions
            # Check if unlabeled data set is empty
            if(is.null(unlabeled_est$Minority_Probability)){
                unlabeled_est = data.frame(Index=0,
                                           Minority_Probability=0,
                                           Ground_Truth=NA)
            }
            # > head(unlabeled_est)
            #   Index   Minority_Probability    Ground_Truth
            #   2       0.14070540              minority
            #   4       0.12606211              majority
            #   8       0.10945538              majority
            unlabeled_est = dplyr::arrange(unlabeled_est,desc(Minority_Probability))
            # > head(unlabeled_est)
            #   Index   Minority_Probability    Ground_Truth
            #   1767    0.8201248               minority
            #   1271    0.5307919               majority
            #   3722    0.4825680               majority
            n_unlabeled_est = min(Q,nrow(unlabeled_est)) # \in [1,Q]
            prob_vec = unlabeled_est[["Minority_Probability"]]
            ## Fit beta distribution for the estimated probabilities of the labeled set
            if(ECONOMY_MODE)
                # If ECONOMY_MODE is on, we skip these calculations to save time
                BETA_parms = list(alpha=0,          beta=0,
                                  alpha_minority=0, beta_minority=0,
                                  alpha_majority=0, beta_majority=0)
            else
                BETA_parms = tryCatch(
                    {
                        y.tr_hat = labeled_est[["Minority_Probability"]]
                        tr.minority_ind = labeled_est[["Ground_Truth"]] %in% "minority"
                        # p(y.tr_hat)
                        beta.fit = fitdistrplus::fitdist(y.tr_hat, "beta", keepdata = FALSE)
                        alpha = beta.fit$estimate[1]
                        beta  = beta.fit$estimate[2]
                        # p(y.tr_hat | y=minority)
                        beta.fit = fitdistrplus::fitdist(y.tr_hat[tr.minority_ind], "beta", keepdata = FALSE)
                        alpha_minority = beta.fit$estimate[1]
                        beta_minority  = beta.fit$estimate[2]
                        # p(y.tr_hat | y=majority)
                        beta.fit = fitdistrplus::fitdist(y.tr_hat[!tr.minority_ind], "beta", keepdata = FALSE)
                        alpha_majority = beta.fit$estimate[1]
                        beta_majority  = beta.fit$estimate[2]
                        
                        names(alpha) = names(beta) = names(alpha_minority) = names(beta_minority) = names(alpha_majority) = names(beta_majority) = NULL
                        list(alpha=alpha,                   beta=beta,
                             alpha_minority=alpha_minority, beta_minority=beta_minority,
                             alpha_majority=alpha_majority, beta_majority=beta_majority)
                        
                    }, error = function(cond){
                        return(list(alpha=0,          beta=0,
                                    alpha_minority=0, beta_minority=0,
                                    alpha_majority=0, beta_majority=0))
                    }# end error
                )# end tryCatch
            
            
            ## Calculate where is the (n_unlabeled_est-Q)-th order statistic
            if(length(prob_vec)>1){
                Quantile = quantile(prob_vec, probs=max(1-Q/nrow(unlabeled_est),0))
                names(Quantile) = NULL
            }
            else
                Quantile = 0
            ## Store
            probabilistic_entry = data.frame(
                tr.alpha=BETA_parms[["alpha"]],
                tr.beta=BETA_parms[["beta"]],
                tr.alpha_minority=BETA_parms[["alpha_minority"]],
                tr.beta_minority=BETA_parms[["beta_minority"]],
                tr.alpha_majority=BETA_parms[["alpha_majority"]],
                tr.beta_majority=BETA_parms[["beta_majority"]],
                Quantile=Quantile,
                # Estimated Number of Minorities within the Unlabeled-set
                Nu_minority.est=sum(unlabeled_est$Minority_Probability),
                # Estimated Number of Minorities within the next query batch
                Qt_minority.est=sum(head(unlabeled_est$Minority_Probability,n_unlabeled_est)))
            
            
            #############################
            # Intermediate Calculations #
            #############################
            # 1. General Statistics
            general_entry = data.frame(
                ## Simulation nuances
                Imb.R = ifelse(is.na(param[s,"imbalance_ratio"]), # If Imb.R wasn't defined then 
                               round(Imb.R,1),                    # assign the real ratio, else
                               param[s,"imbalance_ratio"]),       # assign the defined ratio
                Policy=Policy,
                Inducer=Inducer,
                Repetition=r,
                Iteration=i,
                ## Observations info
                ### Unlabeled set 
                Nu=nrow(DS_unlabeled),
                Nu_majority=table(DS_unlabeled$label)[["majority"]],
                Nu_minority=table(DS_unlabeled$label)[["minority"]],
                ### Labeled set
                Nl=nrow(DS_labeled),
                Nl_majority=table(DS_labeled$label)[["majority"]],
                Nl_minority=table(DS_labeled$label)[["minority"]],
                ## Evaluation criteria
                AUC=return_list_te$AUC,
                PRBEP=return_list_te$PRBEP,
                LIFT=return_list_te$LIFT,
                ## Support Vector info
                SV_total    = return_list_te$SV_total,
                SV_minority = return_list_te$SV_minority, 
                SV_majority = return_list_te$SV_majority,
                SV.diff     = ifelse(i==0,
                                     0,
                                     diff(c(repetition_data[i,"SV_total"],return_list_te$SV_total))),
                SV.R        = round(return_list_te$SV_majority/return_list_te$SV_minority,1)
            )# general_entry
            ## Run time summery statistics
            summery_statistics_entry = data.frame(
                Data_Efficiency = round(100*nrow(DS_labeled)/(N_unlabeled+N_train),2),
                Imb.R.Empirical = round(with(general_entry,Nl_majority/Nl_minority),1))
            
            # 2. Metadata
            if(!ECONOMY_MODE)
            {   
                return_list = fit_and_evaluate_model(train_set=DS_labeled,
                                                     test_set=DS,
                                                     inducer=mdl)
                est = return_list$Test_set_predictions
                ## Store the full data set estimated probabilities
                est_prob_matrix[est$Index,i+1] = est$Minority_Probability
                ## Subset only the estimated probabilities for the unlabeled set
                est_prob_matrix[setdiff(est$Index,rownames(DS_unlabeled)),i+1] = 0
            }
            
            
            new_data_entry  = cbind(general_entry, summery_statistics_entry, probabilistic_entry)
            repetition_data = rbind(repetition_data, new_data_entry)
            
            
            if(verbose) cat('\n','# AUC=', round(return_list_te$AUC,3), sep='')
            
            
            #####################################
            # Query the next data-points to add #
            #####################################
            if(iterations==i){
                if(verbose) cat('\n','# Done', sep='')
                next
            } # end if last iteration
            
            if(verbose) cat('\n','# Querying the next batch', sep='')
            
            ## Choose instances from the unlabeled pool 
            set.seed(20160322)
            if(any(tolower(param[s,"strategy"]) %in% c("max_tuv","eps_greedy","random_policy"))){
                query_list = query_svm(labeled_set=DS_labeled,
                                       unlabeled_set=DS_unlabeled,
                                       num_query=param[s,"num_query"])  
            } else if(any(tolower(param[s,"strategy"]) %in% c("random_instances","greedy"))){
                query_list = query_random(labeled_set=DS_labeled,
                                          unlabeled_set=DS_unlabeled,
                                          num_query=param[s,"num_query"])
            } else
                stop("unkown strategy")
            # if query method
            
            
            ################
            # Apply Policy #
            ################
            # Q instances with the highest informativeness
            unlabeled_top_Q_info_index = index_list[["index_unlabeled"]][query_list$index]
            # Q instances with the highest estimated probability of being in the minority class
            unlabeled_top_Q_prob_index = head(unlabeled_est$Index,Q)
            
            
            if(length(query_list$index)<Q){
                index_chosen = index_list[["index_unlabeled"]]
                
            } else if (Strategy=="random_instances"){
                index_chosen = index_list[["index_unlabeled"]][query_list$index] 
                
            } else if (Strategy=="max_tuv"){
                index_chosen = unlabeled_top_Q_info_index   
                
            } else if (Strategy=="greedy"){
                index_chosen = unlabeled_top_Q_prob_index
                
            } else if (Strategy =="eps_greedy"){
                # Choose epsilon
                epsilon = Quantile
                
                n1 = ceiling(epsilon*Q)
                n2 = Q-n1
                if(n1==0)       # Extreme case when epsilon = 0
                    index_chosen = unlabeled_top_Q_info_index
                else if (n2==0) # Extreme case when epsilon = 1
                    index_chosen = unlabeled_top_Q_prob_index
                else {          # When epsilon \in (0,1)
                    set_A = unlabeled_top_Q_prob_index[1:n1]
                    set_B = setdiff(unlabeled_top_Q_info_index,set_A)[1:n2]
                    index_chosen = union(set_A,set_B)
                }
            } else if (Strategy=="random_policy"){
                # set.seed(param[s,"seed_train"]+i)
                index_chosen = c()
                for(q in 1:Q){
                    # Sample one index
                    one_index_sample = sample(c(unlabeled_top_Q_info_index,unlabeled_top_Q_prob_index),1)
                    index_chosen     = c(index_chosen,one_index_sample)
                    # Update available indices
                    unlabeled_top_Q_info_index = setdiff(unlabeled_top_Q_info_index,index_chosen)
                    unlabeled_top_Q_prob_index = setdiff(unlabeled_top_Q_prob_index,index_chosen)
                }# weighted sample instance-wise
                
            } else
                stop("unkown policy")
            # end Chosing Policy
            
            
            ##################
            # Update Indices #
            ##################
            # Update index_list
            index_list[["index_labeled"]] = union(
                index_list[["index_labeled"]],
                index_chosen)
            index_list[["index_unlabeled"]] = setdiff(
                index_list[["index_unlabeled"]],
                index_chosen)
            # Sort index_list
            index_list[["index_labeled"]]   = sort(index_list[["index_labeled"]])
            index_list[["index_unlabeled"]] = sort(index_list[["index_unlabeled"]])
            
            
            if(verbose) cat('\n', '#', sep='')
        } # end iterations
        
        if(!ECONOMY_MODE)
            return(list(repetition_data=repetition_data,
                        est_prob_matrix=est_prob_matrix))
        else
            return(list(repetition_data=repetition_data))
    } # end foreach Simulation
stopCluster(cl) 
end.time = Sys.time()
cat("\n",rep("#",40),
    "\n# Completed in ", round(as.numeric(end.time-start.time, units = "mins"),0), " [mins]",
    "\n",rep("#",40), sep="")


###########################
# Post processing results #
###########################
# Extract the ground truth labels vector
ground_truth_labels_vector = DS[,p+1]

# Report data
## Convert lists to data.frames and join them to a single data.frame
report_data = data.frame()
for(l in 1:length(reports_list))
    report_data = rbind(report_data, reports_list[[l]]$repetition_data)
report_data = unique(report_data)
report_data = dplyr::arrange(report_data, Imb.R, Policy, Repetition, Iteration)
# Find the policy and the repetition number of the probability matrix
if(!ECONOMY_MODE)
{
    matrix_name = character(length(reports_list))
    for(k in 1:length(reports_list))
    {
        current_repetition_data = reports_list[[k]]$repetition_data
        current_est_prob_matrix = reports_list[[k]]$est_prob_matrix
        
        metadata = unique(current_repetition_data[,c("Policy","Repetition")])
        stopifnot(nrow(metadata)==1,ncol(metadata)==2)
        strsplit(as.character(metadata[,"Policy"]),"-")
        
        matrix_name[k] = paste0(as.character(metadata[,"Policy"]),".",metadata[,"Repetition"])
        
        assign(matrix_name[k], current_est_prob_matrix)  
    }# end extracting prob matrices
}

#################
# Store results #
#################
# Simulation metadata
Time.Diff = round(as.numeric(end.time-start.time, units = "mins"),0)
Imb.R     = paste(round(unique(param[,"imbalance_ratio"]),4), collapse = ",")
Rep.N     = length(unique(report_data$Repetition))
Epochs.N  = max(report_data$Iteration)
Policies  = paste(sort(unique(param[,"strategy"])),collapse=",")
Inducers  = paste(sort(unique(param[,"inducer"])),collapse=",")
file_name = paste0('(',toupper(dataset_name),')',
                   '(',"Imb.R.=",Imb.R,')',
                   '(',"Inducers=",Inducers,')',
                   '(',"Reps=",Rep.N,')',
                   '(',"Epochs=",Epochs.N,')',
                   '(',Sys.Date(),')',
                   '(',paste0(Time.Diff,' minutes'),')')

dir_path = file.path(getwd(),"results")
dir.create(dir_path, show=FALSE, recursive=TRUE)

# Report data
write.csv(report_data, 
          file=file.path(dir_path, paste0(file_name,".csv")), row.names=F)

# Estimated probabilities matrices
if(!ECONOMY_MODE)
    save(list=c(matrix_name,"ground_truth_labels_vector"), 
         file=file.path(dir_path, paste0(file_name,".RData")))


