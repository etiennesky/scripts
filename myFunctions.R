# to install in ubuntu:
# install r-cran-spatial
# run chooseCRANmirror()
# run install.packages() : car stringr packages rgdal raster

library("rgdal")
library("raster")


#=========================
#taken and adapted from vcd package
myKappa <- function (x, weights = c("Equal-Spacing", "Fleiss-Cohen"))
{
  if (is.character(weights))
      weights <- match.arg(weights)

  d  <- diag(x)
  n  <- sum(x)
  nc <- ncol(x)
  colFreqs <- colSums(x)/n
  rowFreqs <- rowSums(x)/n

#  print(x)
  
#print(dim(colFreqs))
#print(dim(rowFreqs))
  
#print(colFreqs)
#print(rowFreqs)

  ## Kappa
  kappa <- function (po, pc)
    (po - pc) / (1 - pc)
  std  <- function (po, pc, W = 1)
    sqrt(sum(W * W * po * (1 - po)) / crossprod(1 - pc) / n)
    
  ## unweighted
  po <- sum(d) / n
  pc <- crossprod(colFreqs, rowFreqs)
  k <- kappa(po, pc)
  s <- std(po, pc)
  
  ## weighted 
  W <- if (is.matrix(weights))
    weights
  else if (weights == "Equal-Spacing")
    1 - abs(outer(1:nc, 1:nc, "-")) / (nc - 1)
  else
    1 - (abs(outer(1:nc, 1:nc, "-")) / (nc - 1))^2
  pow <- sum(W * x) / n
  pcw <- sum(W * colFreqs %o% rowFreqs)
  kw <- kappa(pow, pcw)
  sw <- std(x / n, 1 - pcw, W)

  ## others, from
  ## Hagen(2002): Multi-method assessment of map similarity
  ## Foddy(2002)
  pm <- sum(pmin(colFreqs, rowFreqs))
  Kloc <- (po - pc) / (pm - pc)
  if(is.na(Kloc)) Kloc <- 0
  Khisto <- (pm - pc) / (1 - pc)
  if(is.na(Khisto)) Khisto <- 0
  k2 <- Kloc * Khisto

  structure(
            list(Unweighted = c(
                   value = k,
                   ASE   = s
                   ),
                 Weighted = c(
                   value = kw,
                   ASE   = sw
                   ),
                 Weights = W,
                 basic = c( d=d, n=n, nc=nc, po=po,pc=pc,pm=pm,k=k, s=s,cf=colFreqs,rf=rowFreqs ),
 #                others = c(po=po,pacc=pacc,K=k,Kloc=Kloc,Khisto=Khisto,k2=k2,pce=pce,poe=poe)
                 others = c(po=po,K=k,Kloc=Kloc,Khisto=Khisto,k2=k2)
                 ),
            class = "Kappa"
       )
}

myConfMatrix <- function (classif, ref, levels=NULL) {
  if(!is.null(levels)) {
    classif <- factor(classif,levels=levels)
    ref <- factor(ref,levels=levels)
  }
  x <- table(classif,ref)
#print(x)
#  x <- x + 1
  x2 <- addmargins(x)
  k <- myKappa(x)

  d  <- diag(x)
  n  <- sum(x)
  nc <- ncol(x)
  cs <- colSums(x)
  rs <- rowSums(x)

  #from Boschetti et al (2005), Congalton & Green(20??)
  #overall accuracy
  accuracy <- sum(d) / n
  #producer's accuracy / classif accuracy
  prod_acc <- d / cs 
  # users's accuracy / ref accuracy
  user_acc <- d / rs     
  error_com <- 1 - user_acc
  error_omi <- 1 - prod_acc
  error_com[is.na(error_com)] = 0
  error_omi[is.na(error_omi)] = 0
  
  structure(
            list(cm=x2,accuracy=accuracy,
                 error_com=error_com,error_omi=error_omi,
                 K=k$others["K"], Kloc=k$others["Kloc"],Khisto=k$others["Khisto"]
                 )
            )
  
}

#myErrReport <- function (r_cla, r_ref) {
myErrReport <- function (f_cla, f_ref, levels=NULL) {

  r_cla <- readGDAL(f_cla)
  r_ref <- readGDAL(f_ref)

#print(r_cla@data[,1])
#print(r_ref@data[,1])
#  cm <- myConfMatrix(classif,ref,levels)
#  cm <- myConfMatrix(r_cla@data[,1],r_ref@data[,1],levels=0:1)
  cm <- myConfMatrix(r_cla@data[,1],r_ref@data[,1])
#  k <- myKappa(cm$cm)
  
#  str(cm)
#  print(rbind(cm))
#  print(cm)
#  str(k)
#  print(k)
  factor <- r_cla@grid@cellsize[1]*r_cla@grid@cellsize[2]/1000/1000
  burned_area <- c(cm$cm[2,3]*factor, cm$cm[3,2]*factor)
  total_area <- cm$cm[3,3]*factor
  burned_fraction <- burned_area / total_area
#  print(sprintf("burned area: %.1f",burned_area))
#  print(sprintf("burned fraction: %.2f",burned_fraction))
#  print(sprintf("total area: %.1f",total_area))

  values=c(
    burned_area[2],burned_area[1],100*burned_fraction[2],100*burned_fraction[1],
    100*cm$accuracy,100*cm$error_com[2],100*cm$error_omi[2],cm$K,cm$Kloc,cm$Khisto
    )
#  values <- as.matrix(values,byrow=TRUE)
#  values2 =t(values)
#  print(values)
#  print(values2)
  invisible(values)
}

myErrReport2 <- function (r_cla, r_ref, t_cla, t_ref, levels=NULL) {

#  r_cla <- readGDAL(f_cla)
#  r_ref <- readGDAL(f_ref)

#  cm <- myConfMatrix(classif,ref,levels)
#  cm <- myConfMatrix(r_cla@data[,1],r_ref@data[,1],levels=0:1)
  cm <- myConfMatrix(r_cla@data[,1],r_ref@data[,1])
#  print(cm)
#  k <- myKappa(cm$cm)
  
  factor <- r_cla@grid@cellsize[1]*r_cla@grid@cellsize[2]/1000/1000
  burned_area <- c(cm$cm[2,3], cm$cm[3,2],cm$cm[2,1],cm$cm[1,2],cm$cm[2,2]) * factor
  total_area <- cm$cm[3,3]*factor
  burned_fraction <- burned_area / total_area

  values=c(
    burned_area[1],burned_area[2],burned_area[3],burned_area[4],burned_area[5],burned_fraction[1],burned_fraction[2],burned_fraction[3],burned_fraction[4],burned_fraction[5],
    100*cm$accuracy,100*cm$error_com[2],100*cm$error_omi[2],cm$K,cm$Kloc,cm$Khisto
    )

  #labcols=c(paste(t_cla,".BA",sep=""),paste(t_ref,".BA",sep=""),paste(t_cla,".BF",sep=""),paste(t_ref,".BF",sep=""),
  #"OA","CE","OE","K","Kloc","Khisto")
  labcols=c(paste(t_cla,".BA",sep=""),paste(t_ref,".BA",sep=""),paste(t_cla,"_only.BA",sep=""),paste(t_ref,"_only.BA",sep=""),"join.BA",paste(t_cla,".BF",sep=""),paste(t_ref,".BF",sep=""),
  paste(t_cla,"_only.BF",sep=""),paste(t_ref,"_only.BF",sep=""),"join.BF","OA","CE","OE","K","Kloc","Khisto")
  names(values) <- labcols
  
#  values <- as.matrix(values,byrow=TRUE)
#  values2 =t(values)
  invisible(values)
}

print.Kappa <- function (x, ...) {
  tab <- rbind(x$Unweighted, x$Weighted)
  rownames(tab) <- names(x)[1:2]
  print(tab, ...)
  print(rbind(x$basic))
  print(rbind(x$others))
  invisible(x)
}

summary.Kappa <- function (object, ...)
  structure(object, class = "summary.Kappa")

print.summary.Kappa <- function (x, ...) {
  print.Kappa(x, ...)
  cat("\nWeights:\n")
  print(x$Weights, ...)
  invisible(x)
}

confint.Kappa <- function(object, parm, level = 0.95, ...) {
  q <- qnorm((1 + level) / 2)
  matrix(c(object[[1]][1] - object[[1]][2] * q,
           object[[1]][1] + object[[1]][2] * q,
           object[[2]][1] - object[[2]][2] * q,
           object[[2]][1] + object[[2]][2] * q),
         nc = 2, byrow = T, 
         dimnames = list(Kappa = c("Unweighted","Weighted"), c("lwr","upr"))
         )
}

#=========================
myErrorReport <- function (x) {

}


get_ylim <- function(data,min=NULL,max=NULL,scale=0.10) {
  if (is.null(min)) min <- min(data,na.rm=TRUE)
  if (is.null(max)) max <- max(data,na.rm=TRUE)
  if (max<0) max <- 0
  if (min!=0) min <- min - abs(min*scale)
  if (max!=0) max <- max + abs(max*scale)
  invisible(c(min,max))
}


#http://stackoverflow.com/questions/9314658/colorbar-from-custom-colorramppalette
color.bar <- function(lut, min, max=-min, nticks=11, ticks=seq(min, max, len=nticks), title='') {
scale = (length(lut)-1)/(max-min)
 
#dev.new(width=1.75, height=5)
plot(c(0,10), c(min,max), type='n', bty='n', xaxt='n', xlab='', yaxt='n', ylab='', main=title)
axis(2, ticks, las=1)
for (i in 1:(length(lut)-1)) {
y = (i-1)/scale + min
rect(0,y,10,y+1/scale, col=lut[i], border=NA)
}	
}
