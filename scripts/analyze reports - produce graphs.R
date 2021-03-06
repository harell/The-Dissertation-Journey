################################################################################
# Analyze Reports - Produce Graphs
################################################################################
## Initialization
cat("\014"); rm(list = ls())
source("scripts/load_libraries.R")
invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))
options(digits=3)
# 1. Choose x limits
Xlimits = c(0,48) # 48 = 4 years # NA
# 2. Choose inducers
Chosen_inducers = c("SVM","GLM")
# 3. Choose policies
Chosen_policies = NA  # policies_metadata$names_new
# Chosen_policies = c("RANDOM-INSTANCES","INFORMATIVENESS")
# Chosen_policies = c("RANDOM-INSTANCES","INFORMATIVENESS","GREEDY")
# Chosen_policies = c("RANDOM-INSTANCES","INFORMATIVENESS","GREEDY","eps-GREEDY","SEMI-UNIFORM")
# 4. Choose right boundary
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
original_names = unique(policies_metadata[policies_metadata$names_original %in% unique(reports$Policy),"names_original"])
new_names      = unique(policies_metadata[policies_metadata$names_original %in% unique(reports$Policy),"names_new"])
for(p in 1:length(original_names))
{
    original_name = original_names[p]
    new_name      = new_names[p]
    reports[reports$Policy %in% original_name,"Policy"] = new_name
}# end changing policies names
## Convert policies name to factor variable
reports$Policy = factor(reports$Policy, levels=new_names)
reports = arrange(reports,Policy)
## Keep only the desierd policies
if(!is.na(Chosen_policies[1]))
    reports = subset(reports,Policy %in% Chosen_policies)
## Subset the data if it's to long
if(is.na(Xlimits[2]))
    Xlimits[2] = max(reports$Nl)
reports = subset(reports, Iteration >= Xlimits[1] & 
                     Iteration <= Xlimits[2] &
                     Inducer %in% Chosen_inducers)
## Summary Statistics of Data Subsets
reports_agg = aggregate(
    cbind(Nu_minority, Nu_majority, Nl_minority, Nu_minority.est,
          AUC, # PRBEP, LIFT, 
          # SV_total, SV_minority, SV_majority, SV.diff, SV.R,
          Imb.R.Empirical, Quantile, Qt_minority.est, 
          tr.alpha,          tr.beta, 
          tr.alpha_minority, tr.beta_minority, 
          tr.alpha_majority, tr.beta_majority) ~ 
        Policy + Inducer + Iteration + Nl + DATABASE_NAME,
    reports, 
    function(x) mean(x,trim=0.0,na.rm=TRUE))
## Nl_minority.diff
reports_agg$Nl_minority.diff = 0
for(m in unique(reports_agg$Policy)){
    Policy_indicator = reports_agg$Policy %in% m
    
    reports_agg[Policy_indicator,"Nl_minority.diff"] = 
        c(diff(reports_agg[Policy_indicator,"Nl_minority"]),0)
} # end for Nl_minority.diff
colnames(reports_agg)
reports_agg = dplyr::arrange(reports_agg,Policy,Inducer,Iteration)


#################
# Visualization #
#################
criteria = c("Nu_majority",      #  1
             "Nu_minority",      #  2
             "Nu_minority.est",  #  3   
             "Nl_minority",      #  4
             "Nl_minority.diff", #  5
             "AUC",              #  6 
             "PRBEP",            #  7
             "LIFT",             #  8
             "Imb.R.Empirical",  #  9
             "Quantile",         # 10
             "Qt_minority.est",  # 11
             # Beta distribution
             "tr.alpha",         # 12
             "tr.beta",          # 13
             "tr.alpha_minority",# 14
             "tr.beta_minority", # 15
             "tr.alpha_majority",# 16
             "tr.beta_majority", # 17
             # Available only for SVM inducers:
             "SV_total",         # 18 
             "SV.diff",          # 19 
             "SV_minority",      # 20 
             "SV_majority",      # 21
             "SV.R"              # 22
)[c(4)]      # Nl_minority
# )[c(10)]     # Quantile
# )[c(4,6)]    # Nl_minority + AUC
# )[c(4,10)]   # Nl_minority + Quantile
# )[c(9)]      # Prevalence Estimation


################
# Render plots #
################
par(pty="s")
if(length(criteria)>1){ # 1-in-a-row 
    par(mar=c(4,4,1,1), mfrow=c(length(criteria),1))
    # A4 size
    width = 21
    height = 29.7
} else {                # 3-in-a-row
    if(Xlimits[2]<=48)
        par(mar=c(4,4,1,1), mfrow=c(3,3))
    else
        par(mar=c(4,4,1,1), mfrow=c(3,1))
    # Square size
    width  = 21
    height = 21
}

# Plot the aggregated data    
for(criterion in criteria)
{
    xlim = c(0,range(subset(reports_agg, select=Nl))[2])
    if(criterion=="Quantile")
        ylim = c(0,1)
    else if (criterion=="AUC")
        ylim = range(reports_agg[,criterion])
    else
        ylim = c(0,range(reports_agg[reports_agg[,"Nl"] <= xlim[2] ,criterion])[2])
    
    plot(0, 0, type="n", 
         main=paste(unique(reports_agg$DATABASE_NAME),"dataset"), 
         sub=paste0("Imb.R=",reports[1,"Imb.R"]),
         xlim=xlim, xlab="# of labeled instances", xaxt="n",
         ylim=ylim, ylab=ifelse(criterion=="Nl_minority","# minorities within the labeled set",criterion))
    params = unique(reports_agg[,c("Policy","Inducer")])
    params = merge(params,
                   subset(policies_metadata, select=c("names_new","col","lty","pch")),
                   by.x="Policy", by.y="names_new", all.y=F)
    params = unique(params)
    params = arrange(params, Policy)
    for(p in 1:nrow(params)){
        Policy  = params[p,"Policy"]
        x = reports_agg[reports_agg$Policy %in% Policy,"Nl"]
        y = reports_agg[reports_agg$Policy %in% Policy,criterion]
        ## Plot curve
        lines(x, y, type="o",
              col=params[p,"col"], pch=params[p,"pch"], lty=params[p,"lty"])
        ## Special add ons
        if(criterion=="Nl_minority")
        { 
            ### Put legend on the bottom right
            # legend(x=380, y=ylim[2],#round(ylim[2]*0.3),
            #        legend=unique(params[["Policy"]]),
            #        lty=unique(params[["lty"]]), col=unique(params[,"col"]), bty="n",
            #        pch=unique(params[["pch"]]), text.col=unique(params[,"col"]), cex=0.85,
            #        inset=c(-0.2,0))
            ### Nl_minority: Calculate curve's AUC
            xmin = min(reports_agg[,"Nl"])-min(reports_agg[,"Nl_minority"])
            ymax = min(1 * x_max + (y[1]- 1 * x[1]), max(with(reports_agg,Nu_minority + Nl_minority)))
            ymin = min(reports_agg[,"Nl_minority"])
            abline(-xmin,1,lty=2)  # left boundary
            abline(h=ymax,lty=2)   # upper boundary
            abline(h=ymin,lty=2)   # lower boundary
            abline(v=x_max, lty=2) # right boundary
            curve_AUC = AUC_by_curve_integration(x, y, xmin=min(x), ymin=0, ymax=ymax)
            curve_AUC = round(curve_AUC,2)
            if(length(criteria)>1)
                text(round(0.74*xlim[2]), 0.1*max(ylim)*p, paste0(Policy," AUC: ",curve_AUC), col=params[p,"col"])
        } else if(criterion=="Imb.R.Empirical"){ 
            ### Imb.R.Empirical: Horizontal line for the true prevalence
            abline(h=unique(reports$Imb.R), lty=2)
            text(0,unique(reports$Imb.R)+0.5,"True prevalence",pos=4)
        } else if(criterion=="Quantile"){
            # No legend
            abline(v=x_max, lty=2)
        } else {
            legend(xlim[2]*0.5, mean(ylim), 
                   legend=unique(params[["Policy"]]), 
                   lty=unique(params[["lty"]]), col=unique(params[,"col"]), bty="n", 
                   pch=unique(params[["pch"]]), text.col=unique(params[,"col"]), cex=0.65)
            abline(v=x_max, lty=2)
        }
    }# end policies plots
    
    axis(1, at=seq(xlim[1],xlim[2],500), las=2)
    abline(v=0); abline(h=0)
}# end for plot criterion


###############
# Export plot #
###############
dir_path = file.path(getwd(),"plots")
plot_name = paste0('(',unique(reports$DATABASE_NAME),')',
                   '(',"Imb.R=",unique(reports$Imb.R),')',
                   '(',"Reps=",length(unique(reports$Repetition)),')',
                   '(',paste(criteria, collapse=","),')',
                   '(',"Inducers=",paste0(unique(reports$Inducer),collapse=","),')')
dir.create(dir_path, show=FALSE, recursive=TRUE)
dev.copy(png,filename=file.path(dir_path,paste0(plot_name,'.png')), 
         width=width, height=height, units="cm", res=300)
dev.off()