################################################################################
# Analyse Reports - Probabilistic Plots Non-Stationary
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
Chosen_inducers = c("SVM","GLM","Ensemble")[c(1)]
# 4. Choose plot
Chosen_plot = c("Density Plot","Box Plot")[2]
# 5. Relative or Real values
Chosen_fashion = c("Relative","Real")[2]


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
names_original       = policies_names_original
names_new            = policies_names_new
est_prob_long$Policy = plyr::mapvalues(est_prob_long$Policy, from=names_original, to=names_new)
# Subset the data if it's to long
est_prob_long = subset(est_prob_long, Epoch >= Xlimits[1] & Epoch <= Xlimits[2])


#################
# Visualization #
#################
library(ggplot2)
DATABASE_NAME = as.character(unique(est_prob_long$DATABASE_NAME))
Epochs = unique(est_prob_long$Epoch)


# Non stationary conditional distribution plot / box plot
library(animation)
fig2_long_format = subset(est_prob_long, 
                          Repetition==chosen_Repetition &
                              Inducer %in% Chosen_inducers)
# ---------------------------------------------------------------------------- #
#                                Density plot                                  #
# ---------------------------------------------------------------------------- #
saveHTML(
    {
        for(epoch in sort(unique(fig2_long_format$Epoch))){
            cat("\n Crunching epoch",epoch,"/",max(unique(fig2_long_format$Epoch)))
            # Subset the data
            fig2_sub = subset(fig2_long_format, Epoch==epoch)
            # Find the IDs of the observations we are going to purchase
            if(epoch != max(unique(fig2_long_format$Epoch))){ # Not the last epoch
                fig2_sub$flag = FALSE
                Policy.Epoch1.ID = subset(fig2_long_format, Epoch %in% epoch, select=c("Policy","ID"))
                Policy.Epoch2.ID = subset(fig2_long_format, Epoch %in% (epoch+1), select=c("Policy","ID"))
                for(policy in unique(Policy.Epoch1.ID$Policy))
                {
                    ind.epoch1.policy = Policy.Epoch1.ID[,"Policy"] %in% policy
                    ind.epoch2.policy = Policy.Epoch2.ID[,"Policy"] %in% policy
                    ID = setdiff(Policy.Epoch1.ID[ind.epoch1.policy,"ID"], Policy.Epoch2.ID[ind.epoch2.policy,"ID"])
                    fig2_sub[(fig2_sub$ID %in% ID) & ind.epoch1.policy,"flag"] = TRUE
                }# end for policy
            } else # The last epoch
                fig2_sub$flag = TRUE
            
            # Find observations relative rank
            fig2_sub$rel.rank = NA
            for(policy in unique(fig2_sub$Policy)){
                ind = fig2_sub$Policy %in% policy
                fig2_sub[ind,"rel.rank"] = rank(fig2_sub[ind,"Est"])/max(rank(fig2_sub[ind,"Est"]))
            }# end relative rank
            
            
            if(tolower(Chosen_plot[1])=="density plot"){
                ##################################
                # Conditional distributions plot #
                ##################################
                if(Chosen_fashion[1]=="Relative")
                    fig2 <- ggplot(fig2_sub, aes(x=rel.rank, colour=Class, fill=Class))
                if(Chosen_fashion[1]=="Real")
                    fig2 <- ggplot(fig2_sub, aes(x=Est, colour=Class, fill=Class))
                
                fig2 <- fig2 +
                    geom_density(alpha=0.1) + xlim(0,1) +
                    geom_rug() +
                    theme_bw() +
                    facet_wrap(~Policy, ncol=1, scales="free_y") +
                    ggtitle(paste0(DATABASE_NAME,"-",
                                   paste0(unique(fig2_long_format$Inducer),collapse=","),
                                   "; Epoch ",epoch))
            } else if (tolower(Chosen_plot[1])=="box plot"){
                ############
                # Box plot #
                ############
                set.seed(2016)
                
                if(Chosen_fashion[1]=="Relative")
                    fig2 <- ggplot(fig2_sub, aes(x=Class,y=rel.rank))
                if(Chosen_fashion[1]=="Real")
                    fig2 <- ggplot(fig2_sub, aes(x=Class,y=Est))
                
                fig2 <- fig2 +
                    geom_boxplot() + #geom_boxplot(size=2) +
                    geom_jitter(aes(color=flag),alpha=0.5) +
                    coord_cartesian(ylim=c(0,1)) +
                    facet_wrap(~Policy, nrow=1) +
                    theme_bw() + guides(color=FALSE) +
                    ggtitle(paste0(DATABASE_NAME,"-",
                                   paste0(unique(fig2_long_format$Inducer),collapse=","),
                                   "; Epoch ",epoch))
            }# plot type
            
            plot(fig2)
            ani.pause()
        }# adding time dimension
    }, interval=0.5, ani.width=800, ani.height=600)