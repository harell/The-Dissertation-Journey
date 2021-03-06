################################################################################
# Lustiger2016 - Wilcoxon Signed-Rank Test for Policies Robustness
################################################################################
## Initialization
cat("\014"); rm(list = ls())
source("scripts/load_libraries.R")
invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))
options(digits=3)
# 1. Choose x limits
Xlimits = c(0,48) # 48 = 4 years # NA
# 2. Choose inducers
Chosen_inducers = c("SVM","GLM","Ensemble")
# 3. Choose policies
Chosen_policies = NA  # policies_metadata$names_new
# Chosen_policies = c("Random Instances","Informativeness")
# Chosen_policies = c("Random Instances","Informativeness","Greedy")
# Chosen_policies = c("Random Instances","Informativeness","Greedy","eps-Greedy (Quantile)","eps-Greedy (Random)")
x_max = 12 * 100
# 4. Render plots?
PLOTS_FLAG = F



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
## Keep only the desierd policies
if(!is.na(Chosen_policies[1]))
    reports = subset(reports,Policy %in% Chosen_policies)


###################
# Calculate AUCTM #
###################
params = unique(reports[,c("Policy","Repetition")])
for(p in 1:nrow(params))
{
    ind = with(reports,
               which(Policy %in% params[p,"Policy"] &
                         Repetition %in% params[p,"Repetition"]))
    x = reports[ind,c("Nl","Nl_minority","Nu_minority")]
    reports[ind[reports[ind,"Nl"] %in% x_max],"AUCTM"] = AUCTM(x=x$Nl,
                                                               y=x$Nl_minority,
                                                               x_max=x_max,
                                                               y_max=max(x$Nu_minority+x$Nl_minority),
                                                               plot=PLOTS_FLAG)       
}# calculate AUCTM


##############################
# AUCTM Wilcox paired t-test #
##############################
# Initialization
X = subset(reports,Nl %in% x_max, select=c("Policy","Repetition","AUCTM"))
g1 = unique(policies_metadata$names_new)
g2 = unique(X$Policy)
g  = g1[g1 %in% g2]
H1_p.values = H1_diff = matrix(NA,length(g),length(g))
H2_p.values = H2_diff = matrix(NA,length(g),length(g))
K = data.frame(p.value=rep(NA,length(g)^2), mu1=rep(NA,length(g)^2), mu2=rep(NA,length(g)^2))
rownames(H1_p.values) = colnames(H1_p.values) = rownames(H1_diff) = colnames(H1_diff) = g #substr(g, star=7, stop=1e3)
rownames(H2_p.values) = colnames(H2_p.values) = rownames(H2_diff) = colnames(H2_diff) = g #substr(g, star=7, stop=1e3)
# AUCTM values matrix
## Rows = Policies
## Cols = Repetitions
M = matrix(NA, nrow=length(g), ncol=max(X$Repetition))
rownames(M) = g
for(r in 1:dim(M)[1])
    for(c in 1:dim(M)[2])
        M[r,c] = unlist(subset(X, (Policy %in% g[r]) & (Repetition %in% c), select=AUCTM))
# Paired Wilcox t-test
k=1
for(i in 1:length(g))
{
    for(j in 1:length(g))
    {
        x1 = M[g[i],]
        x2 = M[g[j],]
        ## H1: Is the policy better than ranodm sampling?
        H1_p.values[i,j] = wilcox.test(x2, x1, paired=TRUE, alternative="greater")$p.value # where y1 & y2 are numeric
        ## H2: Is policy x1 worst than policy x2 ?
        H2_p.values[i,j] = wilcox.test(x1, x2, paired=TRUE, alternative="less")$p.value # where y1 & y2 are numeric
        H2_diff[i,j]     = round(mean(100 * x1 / x2),1) 
        
        K[k,1] = H2_p.values[i,j]
        K[k,2] = mean(x1)
        K[k,3] = mean(x2)
        rownames(K)[k] = paste0(g[i]," < ",g[j])
        # if(PLOTS_FLAG)
        #     plot(density(x1-x2), main=paste0(g[i]," < ",g[j]))
        k = k+1
    }# end for j
}# end paired Wilcox t-test 

round(H2_p.values,4)
round(K,4)


#################
# Store results #
#################
# write.csv(H1_diff,     file.path(getwd(),"paper",paste("H1",unique(reports$DATABASE_NAME),unique(reports$Inducer),"paired Wilcox test (diff).csv")))
write.csv(H1_p.values, file.path(getwd(),"paper",paste("H1",unique(reports$DATABASE_NAME),unique(reports$Inducer),"paired Wilcox test (p-values).csv")))
write.csv(H2_diff,     file.path(getwd(),"paper",paste("H2",unique(reports$DATABASE_NAME),unique(reports$Inducer),"paired Wilcox test (diff).csv")))
write.csv(H2_p.values, file.path(getwd(),"paper",paste("H2",unique(reports$DATABASE_NAME),unique(reports$Inducer),"paired Wilcox test (p-values).csv")))