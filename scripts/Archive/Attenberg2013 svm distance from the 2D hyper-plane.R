################################################################################
# Attenberg2013 - 3.1. Support Vector Machines: Distance from the 2D hyper-plane
################################################################################
#' References
#' [1] Support vector machine From Joao Neto
#' <http://www.di.fc.ul.pt/~jpn/r/svm/svm.html>
#' [2] Some technical notes about the svm() in package e1071
#' <https://cran.r-project.org/web/packages/e1071/vignettes/svminternals.pdf>

##################
# Initialization #
##################
rm(list = ls()); cat("\014")
library(e1071) # for svm() 
library(ggplot2) # for visualisation
library(plotly)  # for interactive visualisation


################
# Toy data set #
################
n = 500
r = 10
n_minority = round(n/(r+1))
n_majority = n - n_minority
n_tr = 100
cat("\n Imbalanced ratio =",round(n_majority/n_minority,1))
q = 30 # number of query points
set.seed(1301)
X_majority = MASS::mvrnorm(n=n, mu=c(-2,0), Sigma=diag(1,2))
X_minority = MASS::mvrnorm(n=n, mu=c(+2,0), Sigma=diag(1,2))
X = rbind(X_majority[1:n_majority,],X_minority[1:n_minority,])
y = factor(c(rep("majority",n_majority),rep("minority",n_minority)))
dataset = data.frame(X=X,y=y)
# Plots attributes
dataset$shape = factor(ifelse(dataset$y=="majority","-","+")) # in ggplot2 45="-",43="+"
dataset$col   = factor(ifelse(dataset$y=="majority","springgreen4","red"))


############################################
# Train SVM with randomly chosen instances #
############################################
set.seed(1044)
labeled_index = sample(1:nrow(X),n_tr)
dataset$type = factor(ifelse(1:nrow(dataset) %in% labeled_index, "labeled", "unlabeled"))
dataset[labeled_index,"type"] = "labeled"
table(dataset[labeled_index,"y"])
table(dataset[-labeled_index,"y"])
# Fit SVM model
mdl.SVM = e1071::svm(y ~ ., data=dataset[labeled_index,c("X.1","X.2","y")],
                     kernel="linear", type="C-classification",
                     cost=1e0, scale=F, probability=TRUE)
# Store information about the support vectors
## Flag the support vectors
dataset$SV = factor(ifelse((1:nrow(dataset)) %in% labeled_index[mdl.SVM$index],"Yes","No"))


##################################
# Reconstructing the hyper-plane #
##################################
# See more information at:
# <https://cran.r-project.org/web/packages/e1071/vignettes/svminternals.pdf>
## Get the parameters of hiperplane
w  = t(mdl.SVM$coefs) %*% mdl.SVM$SV
w0 = mdl.SVM$rho
w1 = w[1,1]
w2 = w[1,2]
a  = w0/w2
b  = -w1/w2


#########################
# Choose the next batch #
#########################
# Check the distance from the x-axis
est_tr = predict(mdl.SVM, dataset[,c("X.1","X.2")], probability=TRUE)
est_tr = attr(est_tr, "probabilities")
dataset$dist  = abs((b*dataset[,"X.1"] - dataset[,"X.2"] + a) / sqrt(b^2+1))
dataset$p_hat = unlist(est_tr[,"minority"])
dataset$TUV   = 1 - 2*abs(0.5-dataset$p_hat)



#################
# Visualisation #
#################
# Plot (a) - A toy data set of 500 instances, evenly sampled from two class
# Gaussians.
# fig_a <- ggplot(dataset, aes(x=X.1, y=X.2, shape=y, col=y, label=TUV)) + #, 
#     # Data Points
#     geom_point(size=5) +
#     scale_shape_manual(values=c(45,43,0)) +
#     scale_color_manual(values=c("springgreen4", "red")) +
#     # Misc
#     coord_fixed(ratio=1, xlim=c(-4,4), ylim=c(-4,4), expand=TRUE) + 
#     ggtitle("(a)") + 
#     theme_bw()
# plot(fig_a)
# ggplotly(fig_a)

# Plot (b) - The training set with SVM fitted on it
fig_b <- ggplot(dataset[labeled_index,], 
                aes(x=X.1, y=X.2, shape=y, col=y, label=TUV, p_hat=p_hat, dist=dist)) + #, 
    # Data Points
    geom_point(size=5) +
    scale_shape_manual(values=c(45,43,0)) +
    scale_color_manual(values=c("springgreen4", "red")) +
    # Support Vectors (black circles)
    geom_point(data=dataset[dataset$SV %in% "Yes",], colour="black", shape=1, size=5) +
    # Hyper-plane
    geom_abline(intercept=w0/w2,      slope=-w1/w2, col="blue") +
    geom_abline(intercept=(1+w0)/w2,  slope=-w1/w2, col="blue", linetype=2) +
    geom_abline(intercept=(-1+w0)/w2, slope=-w1/w2, col="blue", linetype=2) +
    # Misc
    coord_fixed(ratio=1, xlim=c(-4,4), ylim=c(-4,4), expand=TRUE) + 
    ggtitle("(a)") + 
    theme_bw()
plot(fig_b)
ggplotly(fig_b, tooltip=c("dist","p_hat","TUV"))









# fig_a <- ggplot(dataset[-labeled_index,], aes(x=X.1, y=X.2, shape=y, col=y, label=TUV)) + #, 
#     # Data Points
#     geom_point(size=5) +
#     scale_shape_manual(values=c(45,43,0)) +
#     scale_color_manual(values=c("springgreen4", "red")) +
#     # Hyper-plane
#     geom_abline(intercept=-w0,        slope=-w1/w2, col="blue") + 
#     geom_abline(intercept=(1+w0)/w2,  slope=-w1/w2, col="blue", linetype=2) + 
#     geom_abline(intercept=(-1+w0)/w2, slope=-w1/w2, col="blue", linetype=2) + 
#     # Misc
#     coord_fixed(ratio=1, xlim=c(-4,4), ylim=c(-4,4), expand=TRUE) + 
#     theme_bw()

#' #################
#' # Visualisation #
#' #################
#' # ---------------------------------------------------------------------------- #
#' # Full-dataset
#' plot(svm_model,A[,c("X1","X2","label")])
#' xlim = range(A$X1)
#' ylim = range(A$X2)
#' # ---------------------------------------------------------------------------- #
#' # Training-set
#' ## Density Plot
#' # fig_train_density <- ggplot(A_tr, aes(x=minority_probability)) + 
#' #     geom_density() + xlim(0,1)
#' # ggplotly(fig_train_density)
#' ## Scatter Plot
#' fig_train_scatter <- ggplot(A_tr, aes(X1, X2, label=uncertainty_rank, shape=label)) + 
#'     ggtitle("Visualisation of the training-set") + 
#'     # Training set points
#'     geom_point(aes(colour=minority_probability), size=2) + 
#'     scale_shape_manual(values = c(45,43,0)) +
#'     scale_colour_gradient(low="red", high="forestgreen") + 
#'     # Test set points
#'     #geom_point(data=A_te, aes(X1, X2, shape=label), size=2) + 
#'     # Rank (display only ranks with a value below a certain threshold)
#'     geom_text(aes(label=ifelse(uncertainty_rank<=10, as.character(uncertainty_rank), ''))) +
#'     # Hyper=plane
#'     geom_abline(intercept=-b, slope=-w1/w2) +
#'     # Plot attributes
#'     xlim(xlim) + ylim(ylim)
#' ggplotly(fig_train_scatter)
#' # ---------------------------------------------------------------------------- #
#' # Test-set
#' ## Density Plot
#' # fig_test_density <- ggplot(A_te, aes(x=minority_probability)) + 
#' #     geom_density(trim = TRUE) + xlim(0,1)
#' # ggplotly(fig_test_density)
#' ## Scatter Plot
#' fig_test_scatter <- ggplot(A_te, aes(X1, X2, label=uncertainty_rank, shape=label)) + 
#'     ggtitle("Visualisation of the test-set") + 
#'     geom_point(aes(colour=minority_probability), size=2) + 
#'     scale_shape_manual(values = c(45,43,0)) +
#'     scale_colour_gradient(low="red", high="forestgreen") + 
#'     # Rank (display only ranks with a value below a certain threshold)
#'     geom_text(aes(label=ifelse(uncertainty_rank<=10, as.character(uncertainty_rank), ''))) +
#'     # Hyper=plane
#'     geom_abline(intercept=-b, slope=-w1/w2) + 
#'     # Plot attributes
#'     xlim(xlim) + ylim(ylim)
#' ggplotly(fig_test_scatter)
#' 
#' 
#' #######################
#' # Choosing the cutoff #
#' #######################
#' prob_quantile = round(quantile(A_te$minority_probability,c(0.99)),3)
#' cat("\n",rep("#",40),
#'     "\n", "# Test-set probability statistics:",
#'     "\n", "# mean = ", round(mean(A_te$minority_probability),3),
#'     "\n", "# median = ", round(median(A_te$minority_probability),3),
#'     "\n", "# 99% quantile = ", prob_quantile,
#'     sep="")






