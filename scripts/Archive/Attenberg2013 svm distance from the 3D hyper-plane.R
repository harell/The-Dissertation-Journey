################################################################################
# Attenberg2013 - 3.1. Support Vector Machines: Distance from the 3D hyper-plane
################################################################################
#'
#' 1. SVM calculate distance to separating hyperplane
#' <https://stat.ethz.ch/pipermail/r-help/2005-December/085501.html>
#' 2. Plotting data from an SVM fit - hyperplane 
#' <http://stackoverflow.com/questions/8017427/plotting-data-from-an-svm-fit-hyperplane>
#' 3. Support vector machine From Joao Neto
#' <http://www.di.fc.ul.pt/~jpn/r/svm/svm.html>
#' 
##################
# Initialization #
##################
rm(list = ls()); cat("\014")
library(e1071) # for svm() 
library(rgl)   # for 3d graphics
library(ggplot2) # for visualisation
library(plotly)  # for interactive visualisation


#####################
# Generate the data #
#####################
set.seed(2016)                                                                                                                                                                     
t    <- data.frame(x=runif(100), y=runif(100), z=runif(100), cl=NA)
t$cl <- 2 * t$x + 3 * t$y - 5 * t$z                                                                                                                                                 
t$cl <- as.factor(ifelse(t$cl>0,1,-1))
head(t)


#############################################
# Evaluating the equation of boundary plane #
#############################################
svm_model <- e1071::svm(cl~x+y+z, data=t, 
                        type='C-classification', kernel='linear',scale=FALSE)

#' Unfortunately, svm_model doesn't store the equation of boundary plane (or 
#' just, normal vector of it), so we must evaluate it.
#' we can evaluate such weights with following formula:
w <- t(svm_model$coefs) %*% svm_model$SV
w1 = w[1,1]; w2 = w[1,2]; w3 = w[1,3]
#' The negative intercept is stored in svm_model, and accessed via 
b = svm_model$rho


#################
# Drawing plane #
#################
#' We just take grid of pairs (x,y) and evaluate the appropriate value of z of 
#' the boundary plane.
detalization <- 100                                                                                                                                                                 
grid <- expand.grid(seq(from=min(t$x),to=max(t$x),length.out=detalization),                                                                                                         
                    seq(from=min(t$y),to=max(t$y),length.out=detalization))                                                                                                         
z <- (b- w1*grid[,1] - w2*grid[,2]) / w3

rgl::plot3d(grid[,1],grid[,2],z)  # this will draw plane.
# adding of points to the graphics.
rgl::points3d(t$x[which(t$cl==-1)], t$y[which(t$cl==-1)], t$z[which(t$cl==-1)], col='red')
rgl::points3d(t$x[which(t$cl==1)], t$y[which(t$cl==1)], t$z[which(t$cl==1)], col='blue')




