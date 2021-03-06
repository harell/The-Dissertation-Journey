################################################################################
# SVM under class imbalance
################################################################################
# options(error=recover) # debugging mode


##################
# Initialization #
##################
rm(list = ls()); cat("\014")
source("scripts/load_libraries.R")
invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))
options(digits=3)


################
# Toy data set #
################
n = 500
r = 2^3
n_majority = n
n_minority = round(n_majority/r)
# n_minority = round(n/(r+1))
# n_majority = n - n_minority
n_tr = 100
cat("\n Imbalanced ratio =",round(n_majority/n_minority,1))
q = 30 # number of query points
set.seed(1157)
X_majority = MASS::mvrnorm(n=n, mu=c(-2,0), Sigma=diag(1,2))
X_minority = MASS::mvrnorm(n=n, mu=c(+2,0), Sigma=diag(1,2))
X = rbind(X_majority,X_minority)
y = gl(2, n, labels=c("majority","minority"))
dataset = data.frame(X=X,y=y)
# Randomize the sample
dataset = dataset[sample(nrow(dataset)),]
# Select instances
ind_majority = (1:(2*n))[dataset$y %in% "majority"]
ind_minority = (1:(2*n))[dataset$y %in% "minority"]
dataset = dataset[c(ind_majority[1:n_majority],ind_minority[1:n_minority]),]
rm(X,y,X_majority,X_minority,ind_majority,ind_minority,n)
# Add Plots attributes
dataset$pch = ifelse(dataset$y=="majority",45,43) # in ggplot2 45="-",43="+"
dataset$col = ifelse(dataset$y=="majority","springgreen4","red")


############################################
# Train SVM with randomly chosen instances #
############################################
# Select q labeled instances randomly for training set
set.seed(1044)
random_index = sample(1:nrow(dataset),n_tr)
dataset$type = factor(ifelse(1:nrow(dataset) %in% random_index, "labeled", "unlabeled"))
dataset[random_index,"type"] = "labeled"
rownames(dataset) = NULL
table(dataset[random_index,"y"])
table(dataset[-random_index,"y"])
# Fit SVM model
mdl.SVM = e1071::svm(y ~ ., data=dataset[random_index,c("X.1","X.2","y")],
                     kernel="linear", type="C-classification",
                     cost=1e0, scale=F, probability=TRUE)
# Store information about the support vectors
## Flag the support vectors
dataset$SV = factor(ifelse((1:nrow(dataset)) %in% random_index[mdl.SVM$index],"Yes","No"))
table(dataset$SV,dataset$type)


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


##################
# Visualisations #
##################
par(mfrow=c(1,1))
# 1. Plot the training instances
with(dataset[random_index,],
     plot(x=X.1, y=X.2, col=col, pch=pch, cex=2,
     xlim=c(-5,+5), ylim=c(-3,+3),
     sub=paste("Imbalanced ratio =",r), xlab="", ylab=""))
# 2. Plot contours of the full dataset
ind_majority = (1:nrow(dataset))[dataset$y %in% "majority"]
ind_minority = (1:nrow(dataset))[dataset$y %in% "minority"]
kde_majority = MASS::kde2d(dataset[ind_majority,1], dataset[ind_majority,2], n=25)
kde_minority = MASS::kde2d(dataset[ind_minority,1], dataset[ind_minority,2], n=25)
contour(kde_majority, add = TRUE)
contour(kde_minority, add = TRUE)
# 3. Plot the training set hyperplane 
abline(a=w0/w2,      b=-w1/w2, col="blue", lwd=2)
abline(a=(1+w0)/w2,  b=-w1/w2, col="blue", lwd=2, lty=2)
abline(a=(-1+w0)/w2, b=-w1/w2, col="blue", lwd=2, lty=2)
# 4. Plot the support vectors
points(dataset[dataset$SV %in% "Yes",c("X.1","X.2")], pch="o", cex=2) # SV
# 5. Plot the distributions modes
points(x=c(-2,2), y=c(0,0), pch=3, cex=3, col="black")# dist. mode
