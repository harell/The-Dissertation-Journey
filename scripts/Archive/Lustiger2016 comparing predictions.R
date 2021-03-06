################################################################################
# Lustiger2016 - Comparing Predictions
################################################################################
#' Here we sample one of our the datasets into train and test sets. 
#' Then in a gradual procedure we augment the trains set, while holding the test 
#' set fix.
#' 
#' Models:
#' 1. SVM
#' 2. GLM
#' 3. Ensemble of SVM+GLM
#' 
#' Values:
#' 1. \hat{p}(y=minority) estimated probabilities of belonging into the minority 
#'    class.
#' 2. rank(\hat{p}(y=minority)) sample relative ranks of the estimated 
#'    probabilities. That is, arrange the values to have uniform dist. U(0,1).
#'    
#' Measurements:
#' 1. Distributions of the aforementioned values (conditioned on the class).
#' 2. Correlation between the aforementioned values.
#' 
#' Visualizations
#' 1. Box plot (with/without time dimension).
#' 2. Scatter Plot Matrix (with/without time dimension).
#' 
#' Statistics:
#' 1. Correlation between the aforementioned values (with/without conditioning 
#' on the class).
#'


##################
# Initialization #
##################
cat("\014"); rm(list = ls())
source("scripts/load_libraries.R")
invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))
options(digits=2)


################
# Load dataset #
################
load_dataset(NA) # display data sets attributes
dataset_name = c("Letter",           # 1
                 "Satimage",         # 2
                 "Abalone",          # 3
                 "Adult")[+2]        # 4
DS = load_dataset(dataset_name)
p = ncol(DS)-1
n = nrow(DS)


#####################
# Split the dataset #
#####################
index_list = split_dataset(X=DS[,1:p], y=DS[,p+1],
                           train_pct=1e3, 
                           seed_train=2305,
                           test_pct=1e3, 
                           seed_test=2305,
                           imbalance_ratio=NA)
table(DS[index_list[["index_train"]],p+1])
table(DS[index_list[["index_test"]],p+1])


#######################################
# Assign data-points into their group #
#######################################
DS_train     = DS[index_list[["index_train"]],]
DS_test      = DS[index_list[["index_test"]],]
DS_unlabeled = DS[index_list[["index_unlabeled"]],]
DS_labeled   = DS[index_list[["index_labeled"]],]


###############################
# Fit model on the train set  #
#             &               #
#    Predict the test set     #
###############################
# ---------------------------------------------------------------------------- #
# Fit models
# ---------------------------------------------------------------------------- #
## 1. SVM model
set.seed(20160323)
model_svm = e1071::svm(label ~ ., data=DS_train,
                       kernel="radial", cost=1e0,
                       scale=T, probability=TRUE)
## 2. Logistic Regression model
model_lr = glm(label ~ ., data=DS_train, 
               family = "binomial")
# ---------------------------------------------------------------------------- #
# Predict the test-set
# ---------------------------------------------------------------------------- #
## 1. SVM model
est_te = predict(model_svm, DS_test, probability=TRUE)
est_te = attr(est_te, "probabilities")
y1 = as.vector(est_te[,"minority"])
## 2. Logistic Regression model
y2 = predict(model_lr, DS_test, type="response")
## 3. Mixture
y3 = rowMeans(cbind(y1,y2))
# ---------------------------------------------------------------------------- #
# Store predictions
# ---------------------------------------------------------------------------- #
Y = data.frame(Class=DS_test[,p+1],
               SVM=y1,
               LR=y2,
               Mixture=y3)
Y.long = reshape2::melt(Y, id.vars='Class', variable.name="Model")


#################
# Preprocessing #
#################
# Add relative ranks
Y.rank = data.frame(Class=factor(Y[,1]), apply(Y[,-1], 2, rank)/nrow(Y))
Y.long$rel.rank = NA
for(mdl in unique(Y.long$Model)){
    ind = Y.long$Model %in% mdl
    Y.long[ind,"rel.rank"] = rank(Y.long[ind,"value"])/max(rank(Y.long[ind,"value"]))
}# end relative rank


###############
# Correlation #
###############
cor_matrix = data.frame(total=NA,majority=NA,minority=NA)
## Real values
v1_tot = subset(Y, select="SVM")
v2_tot = subset(Y, select="LR")
v1_maj = subset(Y, Class=="majority", select="SVM")
v2_maj = subset(Y, Class=="majority", select="LR")
v1_min = subset(Y, Class=="minority", select="SVM")
v2_min = subset(Y, Class=="minority", select="LR")

cor_matrix[1,"total"]    = cor(v1_tot,v2_tot)
cor_matrix[1,"majority"] = cor(v1_maj,v2_maj)
cor_matrix[1,"minority"] = cor(v1_min,v2_min)
## Rank
v1_tot = subset(Y.rank, select="SVM")
v2_tot = subset(Y.rank, select="LR")
v1_maj = subset(Y.rank, Class=="majority", select="SVM")
v2_maj = subset(Y.rank, Class=="majority", select="LR")
v1_min = subset(Y.rank, Class=="minority", select="SVM")
v2_min = subset(Y.rank, Class=="minority", select="LR")

cor_matrix[2,"total"]    = cor(v1_tot,v2_tot)
cor_matrix[2,"majority"] = cor(v1_maj,v2_maj)
cor_matrix[2,"minority"] = cor(v1_min,v2_min)

rownames(cor_matrix) = c("Real","Relative")
cor_matrix


##################
# Visualisations #
##################
# Box plot
lattice::bwplot(value~Class|Model,
                data=Y.long,
                between=list(y=1),
                main=paste0(dataset_name,": 2 Models Estimated Probabilities: Box Plot"))
lattice::bwplot(rel.rank~Class|Model,
                data=Y.long,
                between=list(y=1),
                main=paste0(dataset_name,": 2 Models Estimated Probabilities: Box Plot"))

# Scatter plot matrix
car::scatterplotMatrix(~ SVM + LR + Mixture | Class, data=Y,
                       main=paste0(dataset_name,": 2 Models Estimated Probabilities: Scatter Plot Matrix"),
                       smoother=FALSE,
                       by.group=TRUE)
car::scatterplotMatrix(~ SVM + LR + Mixture | Class, data=Y.rank,
                       main=paste0(dataset_name,": 2 Models Estimated Probabilities: Scatter Plot Matrix"),
                       smoother=FALSE,
                       by.group=TRUE)



#############
# Animation #
#############
library(animation)
N_train = length(index_list[["index_train"]])
Q = seq(100, N_train, by=100)
Y = data.frame()

for(n_tr in Q)
{
    cat("\n# Fitting models on",n_tr,"observations")
    # ---------------------------------------------------------------------------- #
    # Fit models
    # ---------------------------------------------------------------------------- #
    ## 1. SVM model
    set.seed(20160323)
    model_svm = e1071::svm(label ~ ., data=DS_train[1:n_tr,],
                           kernel="radial", cost=1e0,
                           scale=T, probability=TRUE)
    ## 2. Logistic Regression model
    model_lr = glm(label ~ ., data=DS_train[1:n_tr,],
                   family = "binomial")
    # ---------------------------------------------------------------------------- #
    # Predict the test-set
    # ---------------------------------------------------------------------------- #
    ## 1. SVM model
    est_te = predict(model_svm, DS_test, probability=TRUE)
    est_te = attr(est_te, "probabilities")
    y1 = as.vector(est_te[,"minority"])
    ## 2. Logistic Regression model
    y2 = predict(model_lr, DS_test, type="response")
    ## 3. Mixture
    y3 = rowMeans(cbind(y1,y2))
    # ---------------------------------------------------------------------------- #
    # Store predictions
    # ---------------------------------------------------------------------------- #
    new_entry = data.frame(Q=n_tr,
                           Class=DS_test[,p+1],
                           SVM=y1,
                           LR=y2,
                           Mixture=y3)
    Y = rbind(Y,new_entry)
}
Y.long = reshape2::melt(Y, id.vars=c("Q",'Class'), variable.name="Model")



# saveHTML
# saveLatex
dir_path = file.path(getwd(),"plots","animation")
dir.create(dir_path, show=FALSE, recursive=TRUE)
xlim = range(Y.long$value)
saveHTML(
    {
        for(q in unique(Y.long$Q))
        {
            #################
            # Preprocessing #
            #################
            # Subset the data
            Y_t = subset(Y, Q %in% q)
            Y.long_t = subset(Y.long, Q %in% q)
            # Add relative ranks
            Y_t.rank = data.frame(Y_t[,1:2], apply(Y_t[,-2:-1], 2, rank)/nrow(Y_t))
            Y.long_t$rel.rank = NA
            for(mdl in unique(Y.long_t$Model)){
                ind = Y.long_t$Model %in% mdl
                Y.long_t[ind,"rel.rank"] = rank(Y.long_t[ind,"value"])/max(rank(Y.long_t[ind,"value"]))
            }# end relative rank
            
            
            ############
            # Box plot #
            ############
            # my.plot <- lattice::bwplot(value~Class|Model,
            #                 data=Y.long_t,
            #                 between=list(y=1),
            #                            main=paste0(dataset_name,": 2 Models Estimated Probabilities: Box Plot ",q))
            my.plot <- lattice::bwplot(rel.rank~Class|Model,
                                       data=Y.long_t,
                                       between=list(y=1),
                                       main=paste0(dataset_name,": 2 Models Estimated Probabilities: Box Plot ",q))
            print(my.plot)
            
            
            #######################
            # Scatter Plot Matrix #
            #######################
            # car::scatterplotMatrix(~ SVM + LR + Mixture | Class, data=Y_t,
            #                        main=paste0(dataset_name,": 2 Models Estimated Probabilities - Scatter Plot Matrix ",q),
            #                        smoother=FALSE,
            #                        by.group=TRUE,
            #                        xlim=xlim,
            #                        ylim=xlim)
            # car::scatterplotMatrix(~ SVM + LR + Mixture | Class, data=Y_t.rank,
            #                        main=paste0(dataset_name,": 2 Models Estimated Probabilities - Scatter Plot Matrix ",q),
            #                        smoother=FALSE,
            #                        by.group=TRUE,
            #                        xlim=c(0,1), ylim=c(0,1))
            ani.pause()
        }#end for
    },
    interval=0.2, ani.width=800, ani.height=600)




#######################################################
# Estimating the number of minorities in the test-set #
#######################################################
N_minorities = table(DS[index_list[["index_test"]],p+1])[["minority"]]
Y.long_agg = aggregate(value ~ Model + Q, Y.long, sum)
fig1 <- ggplot(Y.long_agg, aes(x=Q, y=value, color=Model)) +
    geom_line() + geom_point() + stat_smooth() +
    geom_hline(aes(yintercept=N_minorities)) +
    xlab("# of training instances") + ylab("# Estimated minorities instances") +
    ggtitle(paste0(dataset_name,": Estimating the number of minorities in the test-set")) +
    theme_bw()
plot(fig1)
# Export plot
dir_path = file.path(getwd(),"plots","animation")
plot_prefix = paste0('(',dataset_name,')',
                     # '(',"Imb.R=",Imb.R,')',
                     '(Estimating the number of minorities in the test-set)',
                     '.png')
ggsave(filename=file.path(dir_path,plot_prefix), plot=fig1,
       width=11.7, height=8.3) # A4^T size