#' AUCTM
#'
#' 
#' 
AUCTM <- function(x,    # number of instances within the labeled set
                  y,    # number of minorities cases within the unlabeled set
                  x_max=max(x), # optional: the right boundary
                  y_max=max(y), # maximum number of possible minority cases
                  plot=F) # Plot the shape being evaluated 
{
    x_max = min(x_max, max(x), na.rm=T)
    ###########################
    # Find trapezoid vertices #
    ###########################
    org_m  = 1 # because the batch size B is constant
    org_n  = min(y) - org_m * min(x)
    ## Original vertices
    org_x  = x[x<=x_max]
    org_y  = y[x<=x_max]
    org_br = c(x_max,  min(y))
    org_bl = c(min(x), min(y))
    org_tr = c(x_max,  y_max)
    org_tl1 = c((org_tr[2]-org_n)/org_m, y_max)
    org_tl2 = c(x_max, org_m * x_max + org_n)
    if(org_tl1[1]<x_max) 
        ### trapezoid
        org_tl = org_tl1
    else 
        ### triangle
        org_tl = org_tr = org_tl2
    ## Offset vertices
    off_x  = x[x<=x_max] - x[1]
    off_y  = y[x<=x_max] - y[1]
    off_br = org_br - c(x[1],y[1])
    off_bl = org_bl - c(x[1],y[1])
    off_tr = org_tr - c(x[1],y[1])
    off_tl = org_tl - c(x[1],y[1])
    
    
    #################
    # Visualisation #
    #################
    if(plot){
        # Plot curve
        plot(x, y, type="o", col="green4", xaxt="n",
             xlab="# of labeled instances",
             ylab="# minorities within the labeled set",
             ylim=c(0,y_max))
        axis(1, at=seq(0, max(x), 200), las=2)
        abline(h=0); abline(v=0)
        
        
        # Plot points
        points(x=org_bl[1], y=org_bl[2], cex=1, pch=16, col="red")
        points(x=org_br[1], y=org_br[2], cex=1, pch=16, col="red")
        points(x=org_tl[1], y=org_tl[2], cex=1, pch=16, col="red")
        points(x=org_tr[1], y=org_tr[2], cex=1, pch=16, col="red")
        
        # Plot boundaries
        ## Bottom boundary
        abline(h=org_y[1], lty=2)
        ## Left boundary
        abline(a=org_n, b=org_m, lty=2)
        ## Right boundary
        abline(v=x_max, lty=2)
        ## Upper boundary
        abline(h=org_tl[2], lty=2)
        
        
        # Plot random sampling benchmark
        Imb.R = max(x)/max(y)
        abline(a=0, b=Imb.R^(-1), lty=4, col="purple") 
    }# end plot
    
    
    ####################
    # Area Calculation #
    ####################
    #          a
    #     ___________
    #    /           \
    #   /          h \ S_max = (a+b)*h/2
    #  /      b      \
    #  ---------------
    #
    # a = ymax + xmin
    # b = xmax - xmin
    # h = ymax - ymin
    # S_max = (a+b)*h/2
    #
    a = off_tr[1] - off_tl[1]
    b = off_br[1] - off_bl[1]
    h = off_tl[2] - off_bl[2]
    S_max = (a+b)*h/2
    
    S = 0
    for(i in 2:length(off_x))
    {
        ## Points
        bl = c(off_x[i-1], min(off_y)) # bottom left
        br = c(off_x[i],   min(off_y)) # bottom right
        tl = c(off_x[i-1], off_y[i-1]) # top left
        tr = c(off_x[i],   off_y[i])   # top right 
        ## Area Calculation
        a = tl[2] - bl[2]
        b = tr[2] - br[2]
        h = br[1] - bl[1]
        S = S + (a+b)*h/2
    }# end for
    
    if(plot)
    {
        text(x=org_bl[1], y=2*org_tr[2]/3, paste("AUCTM=",round(S/S_max,3)),        pos=4, col="green4")
        text(x=org_tr[1], y=org_tr[2],     paste0("(",org_tr[1],",",org_tr[2],")"), pos=1, col="green4")
    }
    return(S/S_max)
}# AUCTM