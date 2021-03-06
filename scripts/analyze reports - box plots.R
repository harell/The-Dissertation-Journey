################################################################################
# Analyze Reports - Box Plots
# Note: Put all the different files at the report folder
################################################################################
## Initialization
cat("\014"); rm(list = ls())
source("scripts/load_libraries.R")
invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))
options(digits=3)
# 1. Choose x limits
Xlimits = c(0,48) # 48 = 4 years
# 2. Choose inducers
Chosen_inducers = c("SVM","GLM")
# 3. Choose policies
Chosen_policies = NA #c("(SVM) RANDOM-INSTANCES","(SVM) INFORMATIVENESS") # policies_metadata$names_new
# 4. Choose right boundary
x_max = 1200 #NA
# 5. Render plots?
PLOTS_FLAG = F

################
# Get the data #
################
reports_folder = file.path(getwd(),"reports")
reports = import.reports(reports_folder)
reports = dplyr::arrange(reports, DATABASE_NAME, Inducer, Policy, Repetition, Iteration)
# Subset the data
reports = subset(reports, select=c("DATABASE_NAME","Imb.R","Inducer","Policy","Repetition","Nl","Nl_minority","Nu_minority"))


##################
# Pre-processing #
##################
## Change policies names
for(p in 1:nrow(policies_metadata))
{
    original_name = policies_metadata[p,"names_original"]
    new_name      = policies_metadata[p,"acronym"] #policies_metadata[p,"names_new"]
    reports[reports$Policy %in% original_name,"Policy"] = new_name
}# end changing policies names
## Convert policies name to factor variable
reports$Policy = factor(reports$Policy, levels=unique(policies_metadata$acronym))
## Calculate AUC-TM
params = unique(subset(reports,select=c("DATABASE_NAME","Inducer","Policy","Repetition")))
params$AUCTM = NA
for(p in 1:nrow(params))
{
    cat("\n AUCTM",p,"out of",nrow(params))
    report = subset(reports,
                    (DATABASE_NAME %in% params[p,"DATABASE_NAME"]) &
                        (Inducer %in% params[p,"Inducer"]) &
                        (Policy %in% params[p,"Policy"]) &
                        (Repetition %in% params[p,"Repetition"]),
                    select=c("Nl","Nl_minority","Nu_minority"))
    params[p,"AUCTM"] = AUCTM(x=report[,"Nl"], y=report[,"Nl_minority"],
                              x_max=x_max, 
                              y_max=min(x_max,max(report$Nu_minority+report$Nl_minority)),
                              plot=PLOTS_FLAG)
}# end calculating AUCTM


#################
# Visualization #
#################
# Set the order of appearance for the policies
par(pty="s", cex=0.9, lwd=1, mar=c(4,4,1,1), mfrow=c(3,3))
boxplot(AUCTM~Policy, data=params, 
        ylim=c(0,1), ylab="AUC-TM",
        main=paste(unique(params$DATABASE_NAME),"dataset"),
        las=2, col=unique(policies_metadata$col))
# mtext(side=4, text="SVM")



###############
# Export plot #
###############
dir_path = file.path(getwd(),"plots")
plot_name = paste0('(',unique(reports$DATABASE_NAME),')',
                   '(',"Imb.R=",unique(reports$Imb.R),')',
                   '(',"Reps=",length(unique(reports$Repetition)),')',
                   '(',"Box Plot",')',
                   '(',"Inducers=",paste0(unique(reports$Inducer),collapse=","),')')
dir.create(dir_path, show=FALSE, recursive=TRUE)
dev.copy(png,filename=file.path(dir_path,paste0(plot_name,'.png')), 
         width=21, height=21, units="cm", res=300)
dev.off()