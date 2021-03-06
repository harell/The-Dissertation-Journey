################################################################################
# Analyse Reports - Probabilistic Plots Stationary
################################################################################


##################
# Initialization #
##################
cat("\014"); rm(list = ls())
source("scripts/load_libraries.R")
invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))
options(digits=2)
# 1. Choose repetition
chosen_Repetition = 5
# 2. Choose x limits
Xlimits = c(0,48) # 48 = 4 years
# 3. Choose inducers
Chosen_inducers = c("SVM","GLM","Ensemble")[1]
# 4. Choose policies
Chosen_policies = c("(SVM) Informativeness") #NA #c("(SVM) Informativeness") # policies_metadata$names_new


################
# Get the data #
################
est_prob_long = SparseMatrix_2_LongDataFrame(reports_folder="./reports",
                                             Policy=NA, 
                                             Repetition=chosen_Repetition)


##################
# Pre-processing #
##################
# Change policies names
for(p in 1:nrow(policies_metadata))
{
    original_name = policies_metadata[p,"names_original"]
    new_name      = policies_metadata[p,"names_new"]
    est_prob_long$Policy = plyr::mapvalues(est_prob_long$Policy, from=original_name, to=new_name)
}# end changing policies names
# Subset the data if it's too long
if(!any(is.na(Xlimits)))
    est_prob_long = subset(est_prob_long, Epoch >= Xlimits[1] & Epoch <= Xlimits[2])
if(!is.na(Chosen_policies))
    est_prob_long = subset(est_prob_long, Policy %in% Chosen_policies)



#################
# Visualization #
#################
library(ggplot2)
DATABASE_NAME = as.character(unique(est_prob_long$DATABASE_NAME))
Epochs = unique(est_prob_long$Epoch)

# Parallel coordinate plot
fig_long_format = subset(est_prob_long,
                         Repetition==chosen_Repetition & 
                             Inducer %in% Chosen_inducers &
                             Class=="minority")
fig_title = paste0(DATABASE_NAME,"; ","Parallel Coordinate Plot")

fig <- ggplot(aes(x=Epoch, y=Est, group=ID, color=Policy), data=fig_long_format) +
    geom_path() + 
    geom_point() +
    # X axis
    scale_x_continuous(breaks=range(Epochs)[1]:range(Epochs)[2], limits=range(Epochs)) + 
    xlab("Epoch #") + 
    # Y axis
    scale_y_continuous(breaks = seq(0,1,0.1), limits = c(0,1)) + 
    ylab(expression(hat(Pr)(y==minority~"|"~Y==minority))) +
    # Plot attributes
    ggtitle(fig_title) +
    theme_bw() + facet_wrap(~Policy, ncol=2) +
    theme(axis.text.x=element_text(angle = -90, hjust = 0)) +
    guides(colour=FALSE)
plot(fig)


################
# Export plots #
################
# Simulation metdata
Inducers = paste0(sort(unique(fig_long_format$Inducer)),collapse=",")

# Plot metdata
dir_path = file.path(getwd(),"plots")
plot_prefix = paste0('(',DATABASE_NAME,')',
                     '(',"Imb.R=",setdiff(unique(est_prob_long$Imb.R),"GT"),')',
                     '(',"Parallel Coordinate Plot",')',
                     '(',"Inducers=",Inducers,')',
                     '(',"Chosen Rep=",chosen_Repetition,')')
# '(',"Epochs=",max(fig_long_format$Epoch)+1,')')
# Figure 1
ggsave(filename=file.path(dir_path,paste0(plot_prefix,".png")), 
       plot=fig, width=11.7, height=8.3) # A4 size ^T