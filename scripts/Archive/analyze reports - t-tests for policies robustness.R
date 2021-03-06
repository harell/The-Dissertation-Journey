################################################################################
# Lustiger2016 - t-tests for Policies Robustness
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
# Chosen_policies = c("(SVM) Random Instances","(SVM) Informativeness")
# Chosen_policies = c("(SVM) Random Instances","(SVM) Informativeness","(SVM) Greedy")
# Chosen_policies = c("(SVM) Random Instances","(SVM) Informativeness","(SVM) Greedy","(SVM) eps-Greedy (Quantile)","(SVM) eps-Greedy (Random)")
x_max = 12 * 100
# 4. Render plots?
plots_flag = F


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
    reports[ind[reports[ind,"Nl"] %in% x_max],"AUCTM"] = AUCTM(x=x$Nl, y=x$Nl_minority, x_max=x_max, plot=plots_flag)       
}# calculate AUCTM

#######################
# AUCTM paired t-test #
#######################
X = subset(reports,Nl %in% x_max, select=c("Policy","Repetition","AUCTM"))
g = sort(unique(X$Policy))
H1 = matrix(NA,length(g),length(g))
H2 = matrix(NA,length(g),length(g))
K = data.frame(p.value=rep(NA,length(g)^2), mu1=rep(NA,length(g)^2), mu2=rep(NA,length(g)^2))
rownames(H1) = colnames(H1) = rownames(H2) = colnames(H2) = substr(g, star=7, stop=1e3)
# paired t-test
k=1

for(i in 1:length(g))
{
    
    for(j in 1:length(g))
    {
        x1 = unlist(subset(X, Policy %in% g[i], select="AUCTM"))
        x2 = unlist(subset(X, Policy %in% g[j], select="AUCTM"))
        ## H1: Is the policy better than ranodm (non-sequential design)?
        H1[i,j] = t.test(x2, x1, paired=TRUE, alternative="greater")$p.value # where y1 & y2 are numeric
        ## H2: Is policy x1 worst than policy x2 ?
        H2[i,j] = t.test(x1, x2, paired=TRUE, alternative="less")$p.value # where y1 & y2 are numeric
        K[k,1] = H2[i,j]
        K[k,2] = mean(x1)
        K[k,3] = mean(x2)
        rownames(K)[k] = paste0(g[i]," < ",g[j])
        k = k+1
        if(plots_flag)
            plot(density(x1-x2), main=paste0(g[i]," < ",g[j]))
    } # end for j
    
} # end paired t-test 

round(H2,4)
round(K,4)

write.csv(H1, file.path(getwd(),"paper",paste("H1",unique(reports$DATABASE_NAME),unique(reports$Inducer),"paired t-test.csv")))
write.csv(H2, file.path(getwd(),"paper",paste("H2",unique(reports$DATABASE_NAME),unique(reports$Inducer),"paired t-test.csv")))


