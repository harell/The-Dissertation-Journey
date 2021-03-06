################################################################################
# Analyze Reports - Produce Tables
################################################################################
## Initialization
cat("\014"); rm(list = ls())
source("scripts/load_libraries.R")
invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))
options(digits=3)
# 1. Choose x limits
Xlimits = c(0,48) # 48 = 4 years
# 2. Choose inducers
Chosen_inducers = c("SVM","GLM","Ensemble")
# 3. Choose policies
Chosen_policies = NA #c("(SVM) Random Instances","(SVM) Informativeness") # policies_metadata$names_new
# 3. Choose right boundary
x_max = 1200 #NA


################
# Get the data #
################
reports_folder = file.path(getwd(),"reports")
reports = import.reports(reports_folder)
reports = dplyr::arrange(reports, Policy, Repetition)


##################
# Pre-processing #
##################
## Change policies names
for(p in 1:nrow(policies_metadata))
{
    original_name = policies_metadata[p,"names_original"]
    new_name      = policies_metadata[p,"names_new"]
    reports[reports$Policy %in% original_name,"Policy"] = new_name
}# end changing policies names


################
# Create table #
################
params = unique(subset(reports,select=c("DATABASE_NAME","Policy","Repetition")))
params$AUCTM = NA
## Calculate AUC-TM
for(p in 1:nrow(params))
{
    cat("\n AUCTM",p,"out ot",nrow(params))
    report = subset(reports, 
                    (DATABASE_NAME %in% params[p,"DATABASE_NAME"]) &
                        (Policy %in% params[p,"Policy"])  &
                        (Repetition %in% params[p,"Repetition"]),
                    select=c("Nl","Nl_minority","Nu_minority"))
    params[p,"AUCTM"] = AUCTM(x=report[,"Nl"], y=report[,"Nl_minority"],
                              x_max=x_max, y_max=max(report$Nu_minority+report$Nl_minority))
}# end calculating AUCTM
## Calculate AUC-ROC
AUCROC_table = aggregate(AUC ~ DATABASE_NAME + Policy + Repetition, 
                         subset(reports, Nl %in% x_max), 
                         mean)
colnames(AUCROC_table) = c(colnames(AUCROC_table)[-ncol(AUCROC_table)],"AUCROC")
params = merge(params,AUCROC_table)
params = dplyr::arrange(params, DATABASE_NAME, Policy, Repetition)
# > head(params,3)
#   DATABASE_NAME   Policy                  Repetition  AUCTM   AUCROC
# 1 SATIMAGE        (SVM) Informativeness   1           0.900   0.918
# 2 SATIMAGE        (SVM) Informativeness   2           0.898   0.936
# 3 SATIMAGE        (SVM) Informativeness   3           0.890   0.927


################
# Shrink table #
################
AUCTM = aggregate(AUCTM ~ DATABASE_NAME + Policy, params, 
                  # function(x) c(quantile(x,0.025),mean=mean(x),quantile(x,0.975)))
                  function(x) c(quantile(x,probs=c(0.025,0.5,0.975))))
#   DATABASE_NAME   Policy                  AUCTM.2.5%  AUCTM.50%   AUCTM.97.5%
# 1 SATIMAGE        (SVM) Informativeness   0.887       0.901       0.912
# 2 SATIMAGE        (SVM) Random Instances  0.506       0.530       0.553
AUCROC = aggregate(AUCROC ~ DATABASE_NAME + Policy, params, 
                  # function(x) c(quantile(x,0.025),mean=mean(x),quantile(x,0.975)))
                  function(x) c(quantile(x,probs=c(0.025,0.5,0.975))))


#####################
# Differences table #
#####################
# AUCTM_diff = reshape2::dcast(params[,c("DATABASE_NAME","Policy","Repetition","AUCTM")], 
#                              Repetition ~ Policy)
# AUCTM_diff$diff = AUCTM_diff[,2]-AUCTM_diff[,3]
# plot(density(AUCTM_diff$diff), main="AUCTM diff")


#################
# Visualisation #
#################
# Box plot
par(mar=c(4,4,1,1), mfrow=c(1,2))
boxplot(AUCTM  ~ Policy, data=params, main="AUC-TM Box plot")
boxplot(AUCROC ~ Policy, data=params, main="AUC-ROC Box plot")
par(mar=c(4,4,1,1), mfrow=c(1,1))

# Parallel coordinate plot
fig_title = paste(unique(params$DATABASE_NAME),"dataset")
fig <- ggplot(aes(x=Policy, y=AUCTM, group=Repetition, color=Policy), data=params) +
    geom_path(show.legend=F, size=1) + 
    geom_point(show.legend=F, size=2) +
    # Y axis
    # scale_y_continuous(breaks = seq(0,1,0.1), limits = c(0,1)) + 
    # Plot attributes
    ggtitle(fig_title) +
    theme_bw()
    # theme(axis.text.x=element_text(angle = -90, hjust = 0))

plot(fig)










