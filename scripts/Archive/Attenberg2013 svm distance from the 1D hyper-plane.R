################################################################################
# Attenberg2013 - 3.1. Support Vector Machines: Distance from the 1D hyper-plane
################################################################################


##################
# Initialization #
##################
rm(list = ls()); cat("\014")
library(e1071)   # for svm() 
library(ggplot2) # for visualisation
library(plotly)  # for interactive visualisation


###########################
# Generating the data-set #
###########################
n = 1000
Imb.R = 1/10
n_majority = round(n/(1+Imb.R))
n_minority = n-n_majority
set.seed(2016)
x_majority = rnorm(n_majority, mean=-1)
x_minority = rnorm(n_minority, mean=+1)

x     = c(x_minority,x_majority)
label = factor(c(rep("minority",n_minority),rep("majority",n_majority)))
A     = data.frame(x,label)

fig_total     <- ggplot(A, aes(x)) + geom_density()
fig_separated <- ggplot(A, aes(x, col=label)) + geom_density(aes(group=label))


##########################
# Splitting the data-set #
##########################
#' 70%/30% split
index_train = sample(n,round(0.7*n))
A_tr = A[+index_train,]
A_te = A[-index_train,]


#########################################
# Fitting SVM model on the training-set #
#########################################
svm_model <- e1071::svm(label~x, data=A_tr, 
                        type='C-classification', kernel='linear',
                        scale=FALSE, probability=TRUE)


###########################
# Predicting the test-set #
###########################
y_hat = predict(svm_model, A_te, probability=TRUE)
y_hat = attr(y_hat, "probabilities")
A_te$class = ifelse(as.numeric(A_te$label)==1,-1,1)
A_te$minority_probability = as.vector(y_hat[,"minority"]) 
#A_te$hyperplane_distance = 


####################
# Evaluating model #
####################
pred    = ROCR::prediction(A_te$minority_probability, A_te$label)
AUC_obj = ROCR::performance(pred,"auc")
AUC_obj@y.values[[1]]


#################
# Visualisation #
#################
hist(A_te$minority_probability, 30)

set.seed(2016)
fig1 <- ggplot(A_te, aes(y=label, x=x)) + 
    geom_point(aes(colour = minority_probability)) + 
    #geom_jitter() +
    scale_colour_gradient(low = "red", high = "green") + 
    geom_vline(xintercept=c(-1,1)) + 
    stat_density(aes(x=x, y=(-2+(..scaled..))), position="identity", geom="line")
plot(fig1)
ggplotly(fig1)


#######################
# Choosing the cutoff #
#######################
prob_quantile = round(quantile(A_te$minority_probability,c(0.99)),3)
cat("\n",rep("#",40),
    "\n", "# Test-set probability statistics:",
    "\n", "# mean = ", round(mean(A_te$minority_probability),3),
    "\n", "# median = ", round(median(A_te$minority_probability),3),
    "\n", "# 99% quantile = ",prob_quantile,
    sep="")
 

##################################
# Reconstructing the hyper-plane #
##################################
# Get parameters of hiperplane
w <- t(svm_model$coefs) %*% svm_model$SV
b <- svm_model$rho
w;b
b/sqrt(sum(w^2))


# Get the support vectors
SV = A_tr[svm_model$index,]
prop.table(table(SV$label))





