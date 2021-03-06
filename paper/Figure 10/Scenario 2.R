################################################################################
# Example of uncertainty sampling with SVM 
################################################################################


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
r = 10
n_minority = round(n/(r+1))
n_majority = n - n_minority
n_tr = 100
cat("\n Imbalanced ratio =",round(n_majority/n_minority,1))
q = 30 # number of query points
set.seed(1302)
X_majority = MASS::mvrnorm(n=n, mu=c(-5,0), Sigma=diag(1,2))
X_minority = MASS::mvrnorm(n=n, mu=c(+5,0), Sigma=diag(1,2))
X = rbind(X_majority[1:n_majority,],X_minority[1:n_minority,])
y = factor(c(rep("majority",n_majority),rep("minority",n_minority)))
xlim = c(-2-5,+2+5)
ylim = c(-2-5,+2+5)
dataset = data.frame(X=X,y=y)
# Plots attributes
dataset$pch = ifelse(dataset$y=="majority",45,43) # in ggplot2 45="-",43="+"
dataset$col = ifelse(dataset$y=="majority","springgreen4","red")


############################################
# Train SVM with randomly chosen instances #
############################################
set.seed(1044)
labeled_index   = sample(1:nrow(X),n_tr)
unlabeled_index = (1:nrow(X))[-labeled_index]
dataset$type = factor(ifelse(1:nrow(dataset) %in% labeled_index, "labeled", "unlabeled"))
dataset[labeled_index,"type"] = "labeled"
table(dataset[labeled_index,"y"])
table(dataset[unlabeled_index,"y"])
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
# Query by uncertainty sampling
est_tr = predict(mdl.SVM, dataset[,c("X.1","X.2")], probability=TRUE)
est_tr = attr(est_tr, "probabilities")
dataset$dist  = abs((b*dataset[,"X.1"] - dataset[,"X.2"] + a) / sqrt(b^2+1))
dataset$rank  = rank(dataset[,"dist"])
dataset$p_hat = unlist(est_tr[,"minority"])
dataset$TUV   = 1 - 2*abs(0.5-dataset$p_hat)
us_policy = dataset$rank %in% unlist(head(arrange(subset(dataset, type %in% "unlabeled", select="rank"), rank),q))
dataset$us_policy = (1:nrow(dataset)) %in% us_policy


# dataset$us_policy 
# Query by Random
set.seed(1803)
rs_policy = sample((1:nrow(dataset))[unlabeled_index],q)
dataset$rs_policy = (1:nrow(dataset)) %in% rs_policy


##################
# Visualisations #
##################
par(mfrow=c(2,2), pty="s", cex=0.9, lwd=2)


# Plot (a) - A toy data set of 500 instances, evenly sampled from two class
# Gaussians.
plot(dataset[,1], dataset[,2],
     col=dataset$col,pch=dataset$pch, cex=2,
     xlim=xlim, ylim=ylim,
     sub="(a)", xlab="", ylab="")


# Plot (b) - The training set with SVM fitted on it
## 1. Plot the training set 
with(dataset[labeled_index,],
     plot(X.1, X.2,
          col=col, pch=pch, cex=2,
          xlim=xlim, ylim=ylim,
          sub="(b)", xlab="", ylab=""))
## 2. Plot the support vectors
points(dataset[dataset$SV %in% "Yes",c("X.1","X.2")], pch="o", cex=2)
## 3. Plot the training set hyperplane 
abline(a=w0/w2,      b=-w1/w2, col="blue", lwd=2)
abline(a=(1+w0)/w2,  b=-w1/w2, col="blue", lwd=2, lty=2)
abline(a=(-1+w0)/w2, b=-w1/w2, col="blue", lwd=2, lty=2)


# Plot (c) - SVM model trained with 100 labeled instances randomly drawn from
# the problem domain with then next batch chosen according to random policy.
plot(dataset[unlabeled_index,1], dataset[unlabeled_index,2],
     col="snow3", pch=".", cex=3,
     xlim=xlim, ylim=ylim,
     sub="(c)", xlab="", ylab="")
points(x=dataset[rs_policy,1],
       y=dataset[rs_policy,2],
       col=dataset[rs_policy,"col"], pch=dataset[rs_policy,"pch"], cex=2)
# points(dataset[dataset$SV %in% "Yes",c("X.1","X.2")], pch="o", cex=2) # SV
abline(a=w0/w2,      b=-w1/w2, col="blue", lwd=2)
abline(a=(1+w0)/w2,  b=-w1/w2, col="blue", lwd=2, lty=2)
abline(a=(-1+w0)/w2, b=-w1/w2, col="blue", lwd=2, lty=2)
s1 = sum(dataset[rs_policy,"y"] %in% "minority")
text(xlim[1], ylim[1], paste(s1,"out of",q,"are minority cases"), pos=4)

# Plot (d) - SVM model trained with 100 labeled instances randomly drawn from
# the problem domain with then next batch chosen according to uncertainty sampling.
plot(dataset[unlabeled_index,1], dataset[unlabeled_index,2],
     col="snow3", pch=".", cex=3,
     xlim=xlim, ylim=ylim,
     sub="(d)", xlab="", ylab="")
points(x=dataset[us_policy,1],
       y=dataset[us_policy,2],
       col=dataset[us_policy,"col"], pch=dataset[us_policy,"pch"], cex=2)
# points(dataset[dataset$SV %in% "Yes",c("X.1","X.2")], pch="o", cex=2) # SV
abline(a=w0/w2,      b=-w1/w2, col="blue", lwd=2)
abline(a=(1+w0)/w2,  b=-w1/w2, col="blue", lwd=2, lty=2)
abline(a=(-1+w0)/w2, b=-w1/w2, col="blue", lwd=2, lty=2)
s2 = sum(dataset[us_policy,"y"] %in% "minority")
text(xlim[1], ylim[1], paste(s2,"out of",q,"are minority cases"),pos=4)


################
# Export Image #
################
MAIN_TITLE = "Example of uncertainty sampling with SVM (Scenario 2)"
file_name = paste0(MAIN_TITLE, ".png")
file_path = file.path(getwd(), "paper", "Figure 10", file_name)
dev.copy(png,filename=file_path, 
         width=21, height=21, units="cm", res=300)
dev.off()