################################################################################
# Figure 1 - Minority space with examples of minority curves
################################################################################
##################
# Initialization #
##################
rm(list = ls()); cat("\014")
source("scripts/load_libraries.R")
invisible(sapply(list.files(pattern="[.]R$", path="./functions/", full.names=TRUE), source))
options(digits=3)
# Should the plot be scaled into [0,1]?
SCALE_FLAG = TRUE


################
# Load dataset #
################
file_path = file.path(getwd(),"paper","Figure 1","data.csv")
dataset   = read.csv(file_path) 


######################
# Data Preprocessing #
######################
# Take only one repetition from specific policies
dataset = subset(dataset,
                 Policy %in% c("random_instances_GLM","max_tuv_GLM","greedy_GLM") & (Repetition %in% 1),
                 select = c("Policy","Iteration","Nu","Nl","Nl_minority","Nl_majority"))
# Scaling
if(SCALE_FLAG){
    N   = max(dataset$Nu + dataset$Nl)
    N_p = max(dataset$Nl_minority)   
} else {
    N   = 1#max(dataset$Nu + dataset$Nl)
    N_p = 1#max(dataset$Nl_minority)
}

dataset = transform(dataset, 
                    Nl = Nl/N, 
                    Nl_minority = Nl_minority/N_p)
# Isolate the policies
perf_strong = subset(dataset, Policy %in% "max_tuv_GLM")
perf_weak   = subset(dataset, Policy %in% "greedy_GLM")
perf_random = subset(dataset, Policy %in% "random_instances_GLM")


#################
# Visualisation #
#################
par(ps=12, cex=1.5, lwd=2, pty="s")
MAIN_TITLE = ifelse(SCALE_FLAG,
                    "Scaled minority space with examples of minority curves",
                    "Minority space with examples of minority curves")
XLAB = ifelse(SCALE_FLAG,
              "Fraction of instances that have been labeled",
              "# of labeled instances")
YLAB = ifelse(SCALE_FLAG,
               "Fraction of minorities who have been labeled",
               "# minorities within the labeled set")
    plot(0,0,type="n", ylim=c(0,max(dataset$Nl_minority)), xlim=c(0,max(dataset$Nl)), 
         xaxs='i', yaxs='i', xaxt="n", yaxt="n",
         xlab=XLAB,
         ylab=YLAB,
         main=MAIN_TITLE)
if(SCALE_FLAG){
    axis(1, at = seq(0, 1, by=0.1), las=2)
    axis(2, at = seq(0, 1, by=0.1), las=2)  
} else {
    axis(1, at = seq(0, max(dataset$Nl), by=200), las=2)
    axis(2, at = seq(0, max(dataset$Nl_minority), by=50), las=2)
}
# Add policies curves
lines(perf_strong[,c("Nl","Nl_minority")], col=2, lty=1, lwd=2, type="l")
lines(perf_weak[,c("Nl","Nl_minority")],   col="darkgreen", lty=1, lwd=2, type="l")
lines(perf_random[,c("Nl","Nl_minority")], col=4, lty=1, lwd=2, type="l")
# Add boundaries
abline(h=c(0,1)); abline(v=c(0,1));
## Problem constraints
b = 100
p = 12
bp = b*p
c1 = max(max(dataset$Nl)/N,1)
c2 = max(max(dataset$Nl_minority)/N_p,1)
## Left
y_offset = -perf_random[1,"Nl"]*N + perf_random[1,"Nl_minority"]*N_p
y_offset = y_offset/N_p
# y = mx+n
x = perf_random$Nl
y = perf_random$Nl*N/N_p+y_offset
m = (diff(y)/diff(x))[1]
n = y[1]-m*x[1]
abline(a=n, b=m, lty=2)
## Right
abline(v=bp/N, lty=2)
## Top
abline(h=c2, lty=2)
## Bottom
abline(h=min(dataset$Nl_minority), lty=2)
# Points
bl = c(x[1],min(dataset$Nl_minority))
br = c(bp/N,min(dataset$Nl_minority))
tl = c((c2-n)/m, c2)
tr = c(bp/N, c2)
points(x=bl[1], y=bl[2], cex=1, pch=16, col=1)#"darkmagenta")
points(x=br[1], y=br[2], cex=1, pch=16, col=1)#"darkmagenta")
points(x=tl[1], y=tl[2], cex=1, pch=16, col=1)#"darkmagenta")
points(x=tr[1], y=tr[2], cex=1, pch=16, col=1)#"darkmagenta")
# Text
text(0.22*c1, 0.18*c2, "Random Performance",  srt=45, col=4)
text(0.20*c1, 0.31*c2, "Weak Performance",    srt=60, col="darkgreen")
text(0.14*c1, 0.40*c2, "Strong Performance",  srt=75, col=2)
text(0.12*c1, 0.75*c2, "Optimal Performance", srt=85, col=1) 



################
# Export Image #
################
file_name = paste0("Figure X02 (",MAIN_TITLE,").png")
file_path = file.path(getwd(),"paper","Figure 1 (Minority space with examples of minority curves)",file_name)
dev.copy(png,filename=file_path, 
         width=21, height=21, units="cm", res=300)
dev.off()