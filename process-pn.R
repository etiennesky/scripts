#! /usr/bin/env Rscript

#source("/data/docs/research/scripts/process-pn.R")
#v1=dopn(pnid="PNSCa",make_img=T)
#doit(pnid="PNSCa",vals=v1,make_img=F)
#v2=dopn(pnid="PNE",make_img=T)
#traceback()


# process_vals
#   compute_vals
#     process_files
#       myErrReport
#     spatial_average
#   compute_yearly_stats
#   write_vals{1,2}


source("/data/docs/research/scripts/myFunctions.R")
library("TeachingDemos")

g_res1 <<- 30
g_res2 <<- 462.5
g_res3 <<- 5000 # 5km
g_res4 <<- 0.5 # 05deg
g_res  <<- g_res2
g_nodata <<- 999

# creates burned area maps and calculates stats
process_files <- function (ifile1,ifile2,t1,t2,make_img=FALSE) {
print(paste("===== function process_files(",ifile1,ifile2,")"))
#print(ifile1)
#print(ifile2)
#make_imgs(ifile1,ifile2)

tmpi1=str_locate(ifile1,"\\.")
tmpi2=str_locate(ifile2,"\\.")
ofile_prefix=paste(substr(ifile1,1,tmpi1[1]-1),"-",substr(ifile2,1,tmpi2[1]-1),".",sub(".tif","",substring(ifile1,tmpi1[1]+1)),sep="")
print(ofile_prefix)
if(make_img==TRUE) make_imgs(ifile1,ifile2,ofile_prefix,t1,t2,save_png=TRUE)
#make_imgs(ifile1,ifile2,ofile_prefix)

if ( file.exists(ifile1) && file.exists(ifile2) )
#  e1=myErrReport(ifile2,ifile1)
  e1=myErrReport(ifile2,ifile1,levels=c(0,1))
else e1=NA


invisible(e1)
}


make_imgs <- function (ifile1,ifile2,ofile_prefix,t1,t2,save_png=TRUE,make_img_diff=TRUE,make_img_single=FALSE,col_black=TRUE,boundary=g_boundary) {
#make_imgs <- function (ifile1,ifile2,ofile_prefix,t1,t2,save_png=TRUE) {
#  print(paste("function make_imgs"))
#print(ifile1)
#print(ifile2)
#print(ofile_prefix)

  print(paste("function make_imgs(",ifile1,ifile2,ofile_prefix,")"))
#tmpi1=str_locate(ifile1,"\\.")
#tmpi2=str_locate(ifile2,"\\.")
#print(substring(ifile1,tmpi1[1]))
ofile1_png=paste(g_out_dir,sub(".tif",".png",basename(ifile1)),sep="")
ofile1_ps=paste(g_out_dir,sub(".tif",".ps",basename(ifile1)),sep="")
ofile2_png=paste(g_out_dir,sub(".tif",".png",basename(ifile2)),sep="")
ofile2_ps=paste(g_out_dir,sub(".tif",".ps",basename(ifile2)),sep="")
#ofile=paste(g_out_dir,substr(ifile1,1,tmpi1[1]-1),"-",substr(ifile2,1,tmpi2[1]-1),".",sub(".tif",".png",substring(ifile1,tmpi1[1]+1)),sep="")
ofile_png=paste(g_out_dir,ofile_prefix,".png",sep="")
ofile_ps=paste(g_out_dir,ofile_prefix,".ps",sep="")

  e_if1=(file.exists(ifile1)) 
  e_if2=(file.exists(ifile2)) 

#  png_w=1000
  png_w=2000
png_h <- compute_img_dim (g_boundary@bbox,base_w=png_w)[2]

  if(e_if1) {
    raster1=readGDAL(ifile1)
    if ( make_img_single ) {
      make_img_raster(raster1,ofile1_png,col_black,save_png=TRUE,png_w=png_w,png_h=png_h,t1=t1)
    }
  }
  
  if(e_if2) {
    raster2=readGDAL(ifile2)
    if ( make_img_single )
      make_img_raster(raster2,ofile2_png,col_black,save_png=TRUE,png_w=png_w,png_h=png_h,t1=t2)
  }
  if(make_img_diff && e_if1 && e_if2) {
    raster3=raster1
    raster3@data=raster1@data*raster2@data
    make_img_raster_diff(raster1,raster2,raster3,ofile_png,t1,t2,save_png=TRUE,png_w=png_w,png_h=png_h)
  }

}


compute_img_dim <- function (bbox,base_w=1000) {
tmp_w=round(bbox[1,2]-bbox[1,1])
tmp_h=round(bbox[2,2]-bbox[2,1])
#base_w=1000
#base_h=500
base_h=round(base_w*tmp_h/tmp_w)
invisible(c(base_w,base_h))
}

#make_img <- function (ifile,ofile,col=c("white","black"),save_png=TRUE) {
make_img_raster<- function (raster,ofile,col_black=TRUE,save_png=TRUE,png_w=1000,png_h=500,t1="") {

  print(paste("make_img_raster(",ofile))

  if ( col_black )
    col=c("white","black")
  else
    col=gray(9:0/10)

#png(filename=ofile,width=png_w, height=png_h,bg='white')
  if (save_png==TRUE)  png(filename=ofile,width=png_w, height=png_h,bg='white')
  else postscript(file=ofile)
  
  par(mai=c(0,0,0,0),lwd=2)

  #add some spacing for decorations
  tmp_xlim=c(raster@bbox[1,1],raster@bbox[1,2])
  tmp_ylim=c(raster@bbox[2,1],raster@bbox[2,2])
#  print(tmp_xlim)
#  print(tmp_ylim)
  tmp_xlim=c(raster@bbox[1,1],(raster@bbox[1,2])+0.15*(raster@bbox[1,2]-raster@bbox[1,1]))
  tmp_ylim=c(raster@bbox[2,1],raster@bbox[2,2]+0.05*(raster@bbox[2,1]-raster@bbox[2,2]))
#  print(tmp_xlim)
#  print(tmp_ylim)
  
  image(raster,col=col,xlim=tmp_xlim,ylim=tmp_ylim)
  plot(g_boundary,add=T)

#print("done plot")

#  base2_x=par()$usr[2]-2000
#  base2_y=par()$usr[4]-4000
##  base2_cex=3
#  base2_cex=6
#  text(base2_x,base2_y,paste(t1),cex=base2_cex,adj=c(1,0),font=2)
#  text(base2_x,base2_y-3000,g_year,cex=base2_cex,adj=c(1,0),font=2)

  tmp_w=par()$usr[2]-par()$usr[1]
  tmp_h=par()$usr[4]-par()$usr[3]
  base_cex=3
#  base2_x=par()$usr[2]-10000
#  base2_y=par()$usr[4]-15000
  base2_x=par()$usr[2]-tmp_w*0.05
  base2_y=par()$usr[4]-tmp_h*0.075
#  base2_cex=3
  base2_cex=6
  text(base2_x,base2_y-3000,paste(t1),cex=base2_cex,adj=c(1,0),font=2)
  text(base2_x,base2_y,paste(g_pnid,g_year,sep=" - "),cex=base2_cex,adj=c(1,0),font=2)

if ( ! col_black ) {
  labels=c('0 ','0.2 ','0.4 ','0.6 ','0.8 ','1.0 ')
  #text(par()$usr[2]-tmp_w*0.05,par()$usr[3]+tmp_h*0.02,paste("freq."),cex=4,adj=c(1,0),font=2)
  text(par()$usr[2]-tmp_w*0.05,par()$usr[3]+tmp_h*0.02,paste("freq."),cex=4,adj=c(1,0),font=2)
  #coords=c(par()$usr[1]+w*0.05,par()$usr[4]-h*0.50,par()$usr[1]+w*0.1,par()$usr[4]-h*0.10)
  #coords=c(par()$usr[2]-tmp_w*0.1,par()$usr[3]+tmp_h*0.05,par()$usr[2]-tmp_w*0.025,par()$usr[3]+tmp_h*0.25)
  coords=c(par()$usr[2]-tmp_w*0.075,par()$usr[3]+tmp_h*0.05,par()$usr[2]-tmp_w*0.025,par()$usr[3]+tmp_h*0.25)
  print(coords)
  color.legend(coords[1],coords[2],coords[3],coords[4],labels,col,cex=3,gradient='h')
  #color.bar(col,0,1)
}

if(tmp_w<100) {
  scale_scale=1.0
  scale_text=expression(~1.0 ~degree)#paste("1",expression(~degree))
}
else if (tmp_w > 200000) {
scale_scale=100000
scale_text="100 km"
}
else {
scale_scale=10000
scale_text="10 km"
}
scale_x=par()$usr[1]+tmp_w*0.05
scale_y=par()$usr[3]+tmp_h*0.025
scale_text_off=tmp_h*0.04

  print(paste(scale_scale,scale_text,scale_text_off,scale_x,scale_y))
SpatialPolygonsRescale(layout.scale.bar(), offset = c(scale_x,scale_y),
                       scale = scale_scale, fill = c("transparent", "black"), plot.grid = FALSE)
text(scale_x,scale_y+scale_text_off,"0",cex=base_cex)
text(scale_x+scale_scale,scale_y+scale_text_off,scale_text,cex=base_cex,adj=c(1,0.5))

dev.off()

}
make_img_raster1<- function (raster,ofile,col=c("white","black"),save_png=TRUE,png_w=1000,png_h=500,t1="") {
print(paste("make_img_raster(",ofile))


#print(paste("function make_img(",ifile,ofile,save_png))
print(paste("function make_img_raster(",ofile,save_png,")"))
#raster=readGDAL(ifile)

#png(filename=ofile,width=png_w, height=png_h,bg='white')
if (save_png==TRUE)  png(filename=ofile,width=png_w, height=png_h,bg='white')
else postscript(file=ofile)
par(mai=c(0,0,0,0),lwd=2)

#print("doing plot")
print(raster)
print(raster@data)

image(raster,col=col)
#print("adding bound.")
plot(g_boundary,add=T)

#print("done plot")

  base2_x=par()$usr[2]-2000
  base2_y=par()$usr[4]-4000
#  base2_cex=3
  base2_cex=6
  text(base2_x,base2_y-3000,paste(t1),cex=base2_cex,adj=c(1,0),font=2)
  text(base2_x,base2_y,paste(g_pnid,g_year,sep=" - "),cex=base2_cex,adj=c(1,0),font=2)

dev.off()
##system("convert tmp.png -trim -gravity center tmp2.png")
#system(paste("convert tmp.png -trim -gravity center +repage -bordercolor white -border 10x10 +repage ",ofile,sep=""))
#system(paste("convert tmp.png -trim -gravity center +repage ",ofile,sep=""))
##system(paste("convert tmp.png -trim -gravity center -bordercolor white -border 10x10 +repage ",ofile,sep=""))
##system(paste("convert tmp2.png -trim -gravity center -bordercolor white -border 10x10 ",ofile,sep=""))
#unlink("tmp.png")
#unlink("tmp2.png")

#print(paste("end make_img_raster"))

}

make_img_raster_diff <- function(raster1,raster2,raster3,ofile,t1,t2,save_png=TRUE,png_w=1000,png_h=500) {

  print(paste("function make_img_raster_diff",ofile,save_png,png_w,png_h))

if (save_png==TRUE) png(filename=ofile,width=png_w, height=png_h,bg='white')
else ps(file=ofile)

par(mai=c(0,0,0,0),lwd=2)

image(raster1,col=c("transparent","orange"))
image(raster2,col=c("transparent","blue"),add=T)
image(raster3,col=c("transparent","red"),add=T)
plot(g_boundary,add=T)

#legend(par()$usr[1]+3000,par()$usr[3]+12000,c(t1,t2,"intersect  "),fill=c("orange","blue","red"),inset=0.05,cex=1.5)
#SpatialPolygonsRescale(layout.scale.bar(), offset = c(par()$usr[1]+3000,par()$usr[3]+2000),
#                       scale = 10000, fill = c("transparent", "black"), plot.grid = FALSE)
#text(par()$usr[1]+3000,par()$usr[3]+3500,"0",cex=1.5)
#text(par()$usr[1]+13000,par()$usr[3]+3500,"10 km",cex=1.5,adj=c(0.5,0.5))

#  print(par()$usr)
  base_x=par()$usr[1]+3000
  base_y=par()$usr[3]+1500
  diff_y=10000
#  base_cex=1.5
  base_cex=3
  base_scale=10000

#  base2_x=par()$usr[2]-17000
#  base2_y=par()$usr[4]-4000
  base2_x=par()$usr[2]-2000
  base2_y=par()$usr[4]-4000
#  base2_cex=3
  base2_cex=6
  
  if(g_pnid=="PNE") {
    base_x=par()$usr[1]+2000
    base_y=par()$usr[4]-10000
#    base_y=par()$usr[3]+1500
    diff_y=8000
    base_cex=2
  }
legend(base_x,base_y+diff_y,c(t1,t2,"intersect  "),fill=c("orange","blue","red"),inset=0.05,cex=base_cex)
SpatialPolygonsRescale(layout.scale.bar(), offset = c(base_x,base_y),
                       scale = base_scale, fill = c("transparent", "black"), plot.grid = FALSE)
text(base_x,base_y+1500,"0",cex=base_cex)
text(base_x+base_scale,base_y+1500,"10 km",cex=base_cex,adj=c(1,0.5))

#  text(base2_x,base2_y,paste(t1,"-",t2),cex=base2_cex,adj=c(0,0),font=2)
#  text(base2_x,base2_y-3000,g_year,cex=base2_cex,adj=c(0,0),font=2)
#  text(base2_x,base2_y,paste(t1,"-",t2," / ",g_year),cex=base2_cex,adj=c(1,0),font=2)
  text(base2_x,base2_y-3000,paste(t1,"-",t2),cex=base2_cex,adj=c(1,0),font=2)
  text(base2_x,base2_y,paste(g_pnid,g_year,sep=" - "),cex=base2_cex,adj=c(1,0),font=2)

  
                                        #legend("center",c("TM","MCD45","intersect"),fill=c("orange","blue","red"))

dev.off()
#system(paste("convert tmp.png -trim -gravity center +repage -bordercolor white -border 10x10 +repage ",ofile,sep=""))
#unlink("tmp.png")


}

###### start
compute_yearly_stats <- function (ifiles,years) {
  print("function compute_yearly_stats()")
  print(ifiles)
  print(years)
  ny <- length(ifiles)

  ofileo_tif=paste(g_out_dir,sub(years[1],paste(years[1],"-",years[ny],".occur",sep=""),basename(ifiles[1])),sep="")
  ofilef_tif=paste(g_out_dir,sub(years[1],paste(years[1],"-",years[ny],".freq",sep=""),basename(ifiles[1])),sep="")

  #compute raster data
  if(!file.exists(ifiles[1])) invisible(c(NULL,NULL))
  r_occur <- readGDAL(ifiles[1])
  for (y in 2:ny) {
#    print(paste(y,ifiles[y]))
    if(!file.exists(ifiles[y])) {
      print(paste("EXIT from loop, ny=",ny,y-1))
      ny <- y-1
      break
    }
    r_tmp <- readGDAL(ifiles[y])
    r_occur@data <- r_occur@data + r_tmp@data
  }
  r_freq <- r_occur
  r_freq@data <- r_freq@data / ny

  #write raster data
#  writeGDAL(r_occur,ofileo_tif,type = "Int16")
  writeGDAL(r_occur,ofileo_tif,type = "Float32",mvFlag=-99,options=c("COMPRESS=DEFLATE"))
  writeGDAL(r_freq,ofilef_tif,type = "Float32",mvFlag=-99,options=c("COMPRESS=DEFLATE"))

  invisible(c(ofileo_tif,r_occur,ofilef_tif,r_freq))
}


make_img_yearly_stats_bak<- function (ifile1,raster1,ifile2,raster2,r_max=NULL) {
  if(is.null(raster1)) raster1 <- readGDAL(ifile1)
  if(is.null(raster2)) raster2 <- readGDAL(ifile2)
  if(is.null(r_max)) r_max <- max(raster1@data,na.rm=TRUE,raster1@data,na.rm=TRUE)
  ofile1 <- sub(".tif",".png",ifile1)
  make_img_yearly_stats1(ofile1,raster1,r_max=r_max,col2="black") 
  ofile1 <- sub(".tif","-red.png",ifile1)
  make_img_yearly_stats1(ofile1,raster1,r_max=r_max,col2="red") 
  ofile2 <- sub(".tif",".png",ifile2)
  make_img_yearly_stats2(ofile2,raster2,col2="black") 
  ofile2 <- sub(".tif","-red.png",ifile2)
  make_img_yearly_stats2(ofile2,raster2,col2="red") 
}

# make_img_yearly_stats<- function (ifile1,raster1,ifile2,raster2,r_max=NULL) {
make_img_yearly_stats <- function (file_ref_occur,file_ref_freq,tag_ref,
                        file_c_occur,file_c_freq,tag_c) {
  raster_ref_occur<- readGDAL(file_ref_occur)
  raster_ref_freq<- readGDAL(file_ref_freq)
  raster_c_occur<- readGDAL(file_c_occur)
  raster_c_freq<- readGDAL(file_c_freq)
  r_max<-max(raster_ref_occur@data,na.rm=TRUE,raster_c_occur@data,na.rm=TRUE)
  make_img_yearly_stats_occur(sub(".tif",".png",file_ref_occur),raster_ref_occur,r_max=r_max,col2="black",t1=tag_ref) 
  make_img_yearly_stats_occur(sub(".tif",".png",file_c_occur),raster_c_occur,r_max=r_max,col2="black",t1=tag_c) 
  make_img_yearly_stats_freq(sub(".tif",".png",file_ref_freq),raster_ref_freq,col2="black",t1=tag_ref) 
  make_img_yearly_stats_freq(sub(".tif",".png",file_c_freq),raster_c_freq,col2="black",t1=tag_c) 
}

#freq
make_img_yearly_stats_freq <- function (ofile,raster,col2="black",t1="") {
  print(paste("function make_img_yearly_stats_freq(",ofile,")"))

#  png_w=1000
  png_w=2000
  png_h <- 0.8 * compute_img_dim(g_boundary@bbox,base_w=png_w)[2]
  
#  base_cex=1.5
  base_cex=3
  if(g_pnid=="PNE") {
    base_cex=2
  }
  base2_x=par()$usr[2]-2000
  base2_y=par()$usr[4]-4000
#  base2_cex=3
  base2_cex=3

  png(filename=ofile,width=png_w,height=png_h,bg='white')
  par(mar = c(0.1,0.1,0.1,0.1))
  l1 <- layout(matrix(data=c(1,2), nrow=1, ncol=2), widths=c(8,2), heights=c(1,1))
  
  min <- 0
  max <- 1
  raster@data[[1]][1] <- min
  raster@data[[1]][2] <- max
  f1<-colorRampPalette(c("white",col2))
  ColorRamp=f1(100)
  ColorLevels <- paste(round(seq(min, max, length=5),2)," ")
  image(raster,col=ColorRamp)#,xlim=c(min,max))
  plot(g_boundary,add=T)
  plot(0:1, 0:1, type="n", axes=F, xlab="", ylab="")
  color.legend(.5,.1,.9,.9, ColorLevels, ColorRamp,
               align="lt", gradient="y", cex=base_cex)
  text(base2_x,base2_y,paste(g_pnid,t1,sep=" - "),cex=base2_cex,adj=c(1,0),font=2)

  dev.off()
}


make_img_yearly_stats_occur<- function (ofile,raster,r_max=NULL,col2="black",t1="") {

  print(paste("function make_img_yearly_stats_occur(",ofile,r_max,")"))
#  ofilef_tif=sub(".occur",".freq",ofileo_tif)
#  ofilef_png=sub(".tif",".png",ofilef_tif)
#  print(paste(ofileo_tif,ofilef_tif))

#  png_w=1000
  png_w=2000
  png_h <- compute_img_dim (g_boundary@bbox,base_w=png_w)[2]

#  base_cex=1.5
  base_cex=3
  if(g_pnid=="PNE") {
    base_cex=2
  }

  base2_x=par()$usr[2]-2000
  base2_y=par()$usr[4]-4000
#  base2_cex=3
  base2_cex=6

#  raster <- readGDAL(ifile)
  if(is.null(r_max)) r_max <- max(raster@data,na.rm=TRUE)
#  max_occur <- max(max(

                                        #  if (save_png==TRUE) png(filename=ofile,width=png_w, height=png_h,bg='white')
#  else ps(file=ofile)
  png(filename=ofile,width=png_w,height=png_h,bg='white')
  par(mai=c(0,0,0,0),lwd=2)
  nc=r_max+1
  f1<-colorRampPalette(c("white",col2))
  cols=f1(nc)
  image(raster,col=cols) #col=c("transparent","orange"))
  plot(g_boundary,add=T)
#  legend("bottomleft",legend=seq(from=0,to=nc-1),fill=cols,ncol=2)
#  legend("bottomleft",
#  legend(par()$usr[1]+2000,par()$usr[3]+5000, 
  legend(par()$usr[1]+1000,par()$usr[3]+1000, xjust=0,yjust=0,
         legend=paste(seq(from=0,to=nc-1)," ",sep=""),
#         title="Recorrência",fill=cols,ncol=2, cex=base_cex)
         title="Fire occurence \n (years)",fill=cols,ncol=2, cex=base_cex)
  text(base2_x,base2_y,paste(t1),cex=base2_cex,adj=c(1,0),font=2)
  dev.off()

#  png_w=1000
  png_w=2000
  png_h <- 0.9 * compute_img_dim (g_boundary@bbox,base_w=png_w)[2]
  par(mar = c(0.1,0.1,0.1,0.1))
  l1 <- layout(matrix(data=c(1,2), nrow=1, ncol=2), widths=c(5,1), heights=c(1,1))
    
#legend(par()$usr[1]+3000,par()$usr[3]+12000,c(t1,t2,"intersect  "),fill=c("orange","blue","red"),inset=0.05,cex=1.5)

#SpatialPolygonsRescale(layout.scale.bar(), offset = c(par()$usr[1]+3000,par()$usr[3]+2000),
#                       scale = 10000, fill = c("transparent", "black"), plot.grid = FALSE)
#text(par()$usr[1]+3000,par()$usr[3]+3500,"0",cex=1.5)
#text(par()$usr[1]+13000,par()$usr[3]+3500,"10 km",cex=1.5,adj=c(0.5,0.5))
                                        #legend("center",c("TM","MCD45","intersect"),fill=c("orange","blue","red"))

#dev.off()


}

# calls process_files for each input year and computes multi-year stats
compute_vals <- function(ifiles1,ifiles2,t1,t2,pnid,make_img=FALSE) {
  
print(paste("function compute_vals(",ifiles1,ifiles2,t1,t2,make_img,")"))
  
#boundary <<- readOGR("../../Limites_pol_srs.shp","Limites_pol_srs")
#boundary <<- readOGR("/data/research/work/pnsc/Limites_pol_srs.shp","Limites_pol_srs")

ifiles=c(ifiles1,ifiles2)
print(ifiles)

ny=length(ifiles1)
#nrefs=10
nrefs=15 #process_files + spatial_average
if(ny>1) {
  values=matrix(data=NA,nrow=ny+2,ncol=nrefs)
  labrows=c(rep(NA,(times=ny)),"avg","std")
}
else {
  values=matrix(data=NA,nrow=ny,ncol=nrefs)
  labrows=c(rep(NA,(times=ny)))
}
labcols=c(rep(NA,(times=nrefs)))
#labcols=c("TM BA","MCD45 BA","TM BF","MCD45 BF",
#  "Overall\n\rAccuracy","Comission\n\rError","Omission\n\rError","K","Kloc","Khisto")
#labcols=c("TM BA","MCD45 BA","TM BF","MCD45 BF",
#  "OA","CE","OE","K","Kloc","Khisto")
labcols=c(paste(t1,".BA",sep=""),paste(t2,".BA",sep=""),paste(t1,".BF",sep=""),paste(t2,".BF",sep=""),
  "OA","CE","OE","K","Kloc","Khisto")

for (i in 1:ny) {
  y <- strsplit(ifiles1[i],"\\.")[[1]][4]
  labrows[i] <- y
  g_year <<- y 
  g_pnid <<-pnid
#  labrows[i] <- strsplit(ifiles1[i],"\\.")[[1]][4]
#  values[i,] <- process_files(ifiles1[i],ifiles2[i],t1,t2,make_img)
  tmp_values <- process_files(ifiles1[i],ifiles2[i],t1,t2,make_img)
#  values[i,] <-myErrReport(ifiles2[i],ifiles1[i])

  #if(make_img==TRUE) {

    # create 5km averages
    bf1_5km <- paste(g_out_dir,sub(".tif","",ifiles1[i]),"_bf_5km.tif",sep="")
    bf2_5km <- paste(g_out_dir,sub(".tif","",ifiles2[i]),"_bf_5km.tif",sep="")

    command=paste("gdalwarp -overwrite -ot Float32 -dstnodata ",g_nodata," -cutline ",g_shp_file," -crop_to_cutline -co COMPRESS=DEFLATE -r average  -tr ",g_res3," ",g_res3," ",ifiles1[i]," ", bf1_5km, sep="")
    print(command)
    system(command)
    command=paste("gdalwarp -overwrite -ot Float32 -dstnodata ",g_nodata," -cutline ",g_shp_file," -crop_to_cutline -co COMPRESS=DEFLATE -r average  -tr ",g_res3," ",g_res3," ",ifiles2[i]," ", bf2_5km, sep="")
    print(command)
    system(command)

    ave_5km <- spatial_average(bf1_5km,bf2_5km,t1,t2,t2,t2,t1,t2,do_scatterplot=F)
    cat("\nspatial averages:\n\n")
    print(ave_5km)
#  m4 <- join_arrays(list(ave_5km_2,ave_5km_3,ave_05deg_2,ave_05deg_3),c("MCD45-5km","MCD64-5km","MCD45-0.5d","MCD64-0.5d"))
#  print(m4)
#  write.csv(m4,paste("out/",scene,"_average.csv",sep=""))
#  cat("\n")

  #}
    bf1_5km <- paste(g_out_dir,sub(".tif","",ifiles1[i]),"_bf_5km.tif",sep="")
    bf2_5km <- paste(g_out_dir,sub(".tif","",ifiles2[i]),"_bf_5km.tif",sep="")

  values[i,] <- c(unname(tmp_values),unname(ave_5km))
}

labcols <- c(labcols,names(ave_5km))

if(ny>1) {
values[ny+1,] <- round(apply(values[1:ny,],2,mean,na.rm=TRUE),1)
values[ny+2,] <- round(apply(values[1:ny,],2,sd,na.rm=TRUE),1)
}
else {
#    labrows[i] <- paste(pnid,"_",t2,sep="");
  labrows[] <- pnid
}

dimnames(values) <- list(labrows,labcols)
values <- round(values,2)


#### multi-year stats

#values2[,1] <- round(values[,1],1)
#values2[,2] <- round(values[,2],1)

#  print(values)
invisible(values)

}

spatial_average <- function( ifile1,ifile2,n1,n2,n3,title,t1,t2,do_scatterplot=TRUE,save_png=TRUE,do_spatial_plot=TRUE) {
  print(paste("function spatial_average",ifile1,ifile2,n1,n2,n3,title,t1,t2))
  r1 <- readGDAL(ifile1)#,silent=debug_silent)
  r2 <- readGDAL(ifile2)#,silent=debug_silent)
  i1 <- GDALinfo(ifile1)
  #i2 <- GDALinfo(ifile2)
  res <- i1["res.x"] # this assumes that both rasters have same res...
  if(res>10)
    res2=round(res)
  else
    res2=res
  
  # report means and correlation
  mean1 <- mean(r1@data[[1]],na.rm=TRUE)
  mean2 <- mean(r2@data[[1]],na.rm=TRUE)
  cor1 <- cor(r1@data[[1]],r2@data[[1]], use="complete.obs",  method = "pearson")
  #cat(paste("\nmean_",n1," : ",mean1," mean_",n2," : ",mean2,"\ntot_",n1,"  : ",mean1*res*res," tot_",n2,"  : ",mean2*res*res," \nspatial correlation: ",cor1,"\n\n"),sep="")

  #names=c(paste("mean_",n1,sep=""),paste("mean_",n3,sep=""),paste("tot_",n1,sep=""),paste("tot_",n3,sep=""),"sp. corr.")
  names=c(paste(n1,".mean_",res2,sep=""),paste(n3,".mean_",res2,sep=""),paste(n1,".tot_",res2,n1,sep=""),paste(n3,".tot_",res2,sep=""),paste("corr_",res2,sep=""))
  values=c(mean1,mean2,mean1*res*res,mean2*res*res,cor1)
  #values=c(mean1,mean2,mean1*i1["res.x"]*i1["res.y"],mean2*i2["res.x"]*i2["res.y"],cor1)
  names(values) <- names
  
  # make scatter plot
  if (do_scatterplot) {
    base_cex=1
    if (save_png==TRUE) {
      base_cex=3
      #png_w=2000
      #png_h=2000
      png_w=1000
      png_h=1000
      tmpi1=str_locate(ifile1,"\\.")
      tmpi2=str_locate(ifile2,"\\.")
      #ofile_prefix=paste(substr(ifile1,1,tmpi1[1]-1),"-",substr(ifile2,1,tmpi2[1]-1),sep="")
      ofile_prefix=paste(sub(".tif","",basename(ifile1)),"-",sub(".tif","",basename(ifile2)),sep="")
      ofile=paste(ofile_prefix,"_scatter.png",sep="")
      print(ifile1)
      print(ifile2)
      print(ofile)
      png(filename=ofile,width=png_w, height=png_h,bg='white')
    }

    s <- scatterplot(r1@data[[1]],r2@data[[1]],xlab=n1,ylab=n2,main=title,cex=base_cex)

    dev.off()
    
    lm1 <- lm(r1@data[[1]] ~ r2@data[[1]])
    #print(summary(lm1))
    #readline(prompt = "scatterplot drawn. Press <Enter> to continue...")
  }

  if (do_spatial_plot) {
    #make_imgs(ifile1,ifile2,"",t1,t2,save_png=TRUE,make_img_diff=FALSE,make_img_single=TRUE,col_black=FALSE,boundary=boundary)
    # if need g_boundary and col_black, adapt code from process-ba.R
    make_imgs(ifile1,ifile2,"",t1,t2,save_png=TRUE,make_img_diff=FALSE,make_img_single=T,col_black=F)
}  
  #print("")
  #print(values)
  invisible(values)
}

recompute_table_stats1 <- function(values1,years) {

  print(paste("function recompute_table_stats1"))

  ny=length(years)
  values2 <- matrix(data=NA,nrow=ny+2,ncol=dim(values1)[2])
  labrows1=dimnames(values1)[[1]]
  labrows2=c(years,"avg","std")
  labcols=dimnames(values1)[[2]]
  dimnames(values2) <- list(labrows2,labcols)

  for(y in years[1]:years[ny]) {
    i1 <- which(labrows1==y)
    i2 <- which(labrows2==y)
    values2[i2,] <- values1[i1,]
  }
  
  values2[ny+1,] <- round(apply(values2[1:ny,],2,mean,na.rm=TRUE),1)
  values2[ny+2,] <- round(apply(values2[1:ny,],2,sd,na.rm=TRUE),1)

#  print(values2)
  invisible(values2)
}

recompute_table_stats2 <- function(values1,pnids,tag_c) {

  print("function recompute_table_stats2")
  npnids=length(pnids)
  nc=length(tag_c)

  retval <- list()

  for(i in 1:nc) {
    tmp1 <- values1[[1]][[i]]
    values2 <- matrix(data=NA,nrow=npnids+2,ncol=dim(tmp1)[[2]])
    labrows1=dimnames(tmp1)[[1]]
    labrows2=c(pnids,"avg","std")
    labcols=dimnames(tmp1)[[2]]
    print(tmp1)
    print(labrows1)
    print(labrows2)
    print(labcols)
#    print(values2)
    print(list(labrows2,labcols))
    dimnames(values2) <- list(labrows2,labcols)
    for(j in 1:npnids) {
      #i1 <- which(labrows1==j)
      #i2 <- which(labrows2==j)
      values2[j,] <- values1[[j]][[i]]
    }

    values2[npnids+1,] <- round(apply(values2[1:npnids,],2,mean,na.rm=TRUE),1)
    values2[npnids+2,] <- round(apply(values2[1:npnids,],2,sd,na.rm=TRUE),1)

    retval[[i]] <- values2
  }

  print(paste("done function recompute_table_stats2",pnids))

  invisible(retval)
}

# for a given pnid and years, calls all inportant functions
process_vals <- function(pnid,tag_ref,tag_c1,values1=NULL,tag_c2=NULL,values2=NULL,
                         years=NULL,write_vals=FALSE,
                         save_png=TRUE,make_img=FALSE) {
#process_vals <- function(ref,classif,values=NULL,save_png=TRUE) {

  print("process_vals")
#  print(tag_ref)
#  print(tag_c1)
#  print(years)
  print(paste("function process_vals(",tag_ref,tag_c1,years,")"))
#  t1=ref #TM
#  t2=classif #MCD45
#ifiles1=dir(".","MCD45.burnpix.pnsc.*.tif$")
#ifiles1=dir(".","MCD45.burnpix.pnsc.*.tif$")
#ifiles2=dir(".","TM.burnpix.pnsc.*.tif$")
##ifiles2=c("TM.burnpix.pnsc.jun2009-may2010.tif","TM.burnpix.pnsc.jun2010-dec2010.tif")
##ifiles1=c("MCD45.burnpix.pnsc.jun2009-may2010.tif","MCD45.burnpix.pnsc.jun2010-dec2010.tif")
#ifiles2=dir(".","TM.burnpix.pnsc.jun2010-dec2010.tif$")
#ifiles1=dir(".","MCD45.burnpix.pnsc.jun2010-dec2010.tif$")
#ifiles=dir(".","TM.burnpix.pnsc.*.tif$")

#  g_boundary <<- readOGR(paste(pnid,"_pol.shp",sep=""),paste(pnid,"_pol",sep=""))
  
  ny <- length(years)
  
#  ifiles_ref=dir(".",paste(ref,".burnpix.pnsc.*.tif$",sep=""))
  ifiles_ref=paste(tag_ref,".burnpix.",pnid,".",years,".tif",sep="")
  ifiles_c1=paste( tag_c1 ,".burnpix.",pnid,".",years,".tif",sep="")
#  ofileo_tif=paste(g_out_dir,sub(".tif",".occur.tif",basename(ifiles_ref[1])),sep="")
#  ofileo_tif=paste(g_out_dir,sub(years[1],paste(years[1],"-",years[ny],".occur",sep=""),basename(ifiles_ref[1])),sep="")
#  ofileo_png=sub(".tif",".png",ofileo_tif)
#  ofileo2_png=sub(".occur",".occur-bw",ofileo_png)

  if(!is.null(tag_c2)) ifiles_c2=paste(tag_c2,".burnpix.",pnid,".",years,".tif",sep="")
  else ifiles_c2=NULL
  
  print(ifiles_ref)
  print(ifiles_c1)
  print(ifiles_c2)

#  print(paste( ofileo_tif,  ofileo_png , ofileo2_png))

#  stop()

  if(is.null(values1)) {

    if(length(ifiles_c1)==0) stop("ERROR, missing files!")

    values1 <- compute_vals(ifiles_ref,ifiles_c1,tag_ref,tag_c1,pnid,make_img=make_img)

    
    if(length(years)>1) {
      tmpf1 <- compute_yearly_stats(ifiles_ref, years)
      tmpf2 <- compute_yearly_stats(ifiles_c1, years)
      max3 <- 0
    }    
#    if(!is.null(tag_c2) && is.null(values2)) {
    if(!is.null(tag_c2)) {
      if(length(ifiles_c2)==0) stop("ERROR, missing files!")
      values2 <- compute_vals(ifiles_ref,ifiles_c2,tag_ref,tag_c2,pnid,make_img=make_img)
      if(length(years)>1) {
        tmpf3 <- compute_yearly_stats(ifiles_c2, years)
        max3 <- max(tmpf3[[2]]@data,na.rm=TRUE)
      }
    }

    if(length(years)>1) {
      
#    print(max(tmpf1[[2]]@data,na.rm=TRUE))
    tmp_max <- max(max(tmpf1[[2]]@data,na.rm=TRUE),
                   max(tmpf2[[2]]@data,na.rm=TRUE),
                   max3)
    print(max3)
    print(tmp_max)
#  ofileo_png=sub(".tif",".png",ifile)
#  ofileo2_png=sub(".occur",".occur-bw",ofileo_png)

#    make_img_yearly_stats(tmpf1[[1]],tmpf1[[2]],tmpf1[[3]],tmpf1[[4]],r_max=tmp_max)
#    make_img_yearly_stats(tmpf2[[1]],tmpf2[[2]],tmpf2[[3]],tmpf2[[4]],r_max=tmp_max)
#    if(!is.null(tag_c2)) 
#      make_img_yearly_stats(tmpf3[[1]],tmpf3[[2]],tmpf3[[3]],tmpf3[[4]],r_max=tmp_max)

  }
    
  }

  if(length(years)>1) {
  if(write_vals==TRUE) {
    write_vals1(tag_ref,tag_c1,values1,years,save_png)
    if(!is.null(tag_c2)) {
      write_vals1(tag_ref,tag_c2,values2,years,save_png)
      write_ts(tag_ref,tag_c1,values1,tag_c2,values2,years,save_png)
    }
  }
  invisible(list(values1,values2))
}
  else{

  }

#  invisible(c(values1,values2))
#  invisible(values1)
  invisible(list(values1,values2))
    
}

# creates ts plots
write_ts <- function(pnid,tag_ref,tag_c1,values1,tag_c2,values2,years,save_png=TRUE) {

  print(paste("function write_ts",tag_ref,tag_c1,"values1",tag_c2,"values2",save_png,")"))

  ny=length(years)
  y1=years[1]
  y2=years[ny]
  ps_w=8.5
  ps_h=8.5

  file_ts_png=paste(g_out_dir,tag_ref,"-",tag_c1,"-",tag_c2,".burnpix.",pnid,".",y1,"-",y2,".ts.png",sep="")
  file_ts_ps=paste(g_out_dir,tag_ref,"-",tag_c1,"-",tag_c2,".burnpix.",pnid,".",y1,"-",y2,".ts.ps",sep="")

  print(paste("==========saving timeseries",file_ts_png))

  values1 <- recompute_table_stats1(values1,years)
  values2 <- recompute_table_stats1(values2,years)

  tmp_values <- values1[1:ny,1:3]
  tmp_values[,3]<-values2[1:ny,2]

  xlabs <- years
  if (save_png==TRUE)  png(filename=file_ts_png,bg='white')
#  else postscript(file=file_ts_ps)
  else postscript(file=file_ts_ps,paper="special",width=ps_w,height=ps_h,horizontal=F)

  mar <- par("mar")
  mar[2] <- mar[2]+1.5
  mar[4] <- mar[4]-1
  par(mar=mar)

  ylim=get_ylim(tmp_values[,1:3],scale=0.05)
  ylim[1] <- 0

#  title <- paste("Burned Area ",tag_ref," - ",tag_c1," - ",tag_c2," timeseries",sep="")
#  mtitle <- "Burned Area timeseries"
  mtitle <- paste(g_pnid,"Burned Area timeseries",sep=" - ")
  tTicks <- barplot( main=mtitle,
                    xlab="Years",ylab="",
                    las=1,font.main=2,font.lab=2,legend.text=c(tag_ref,tag_c1,tag_c2),args.legend = list(x = "top"),
                    t(tmp_values[,1:3]),names.arg=xlabs,beside=TRUE,xaxt='n',ylim=ylim,cex.axis=1,cex.lab=1.5,cex.main=2) 
  tTicks <- tapply(tTicks, rep(1:length(xlabs), each=3), mean)
  axis(1, tTicks, xlabs)
  mtext(2, text = "Burned Area   (km)", line=3.5, font=2, cex=1.5)
  box()
  dev.off()
#  suppressWarnings(par(oldpar))

}

# creates ts plots
write_ts2 <- function(pnids,tag_ref,tag_c1,values1,tag_c2,values2,year,save_png=TRUE) {

  print(paste("function write_ts2",tag_ref,tag_c1,"values1",tag_c2,"values2",save_png,")"))

  ps_w=8.5
  ps_h=8.5
  ny=length(pnids)
  file_ts_png=paste(g_out_dir,tag_ref,"-",tag_c1,"-",tag_c2,".burnpix_ts.png",sep="")
  file_ts_ps=paste(g_out_dir,tag_ref,"-",tag_c1,"-",tag_c2,".burnpix_ts.ps",sep="")

  print(paste("==========saving timeseries",file_ts_png))

#  values1 <- recompute_table_stats1(values1,years)
#  values2 <- recompute_table_stats1(values2,years)

#  print(values1)
#  print(values2)

  tmp_values <- values1[1:ny,1:3]
  tmp_values[,3]<-values2[1:ny,2]

  xlabs <- pnids
  if (save_png==TRUE)  png(filename=file_ts_png,bg='white')
#  else postscript(file=file_ts_ps)
  else postscript(file=file_ts_ps,paper="special",width=ps_w,height=ps_h,horizontal=F)

  mar <- par("mar")
  mar[2] <- mar[2]+1.5
  mar[4] <- mar[4]-1
  par(mar=mar)

  ylim=get_ylim(tmp_values[,1:3],scale=0.05)
  ylim[1] <- 0

#  title <- paste("Burned Area ",tag_ref," - ",tag_c1," - ",tag_c2," timeseries",sep="")
  mtitle <- "Burned Area by region"
  tTicks <- barplot( main=mtitle,
                    xlab="region",ylab="",
                    las=1,font.main=2,font.lab=2,legend.text=c(tag_ref,tag_c1,tag_c2),args.legend = list(x = "top"),
                    t(tmp_values[,1:3]),names.arg=xlabs,beside=TRUE,xaxt='n',ylim=ylim,cex.axis=1,cex.lab=1.5,cex.main=2) 
  tTicks <- tapply(tTicks, rep(1:length(xlabs), each=3), mean)
  axis(1, tTicks, xlabs)
  mtext(2, text = "Burned Area   (km)", line=3.5, font=2, cex=1.5)
  box()
  dev.off()
#  suppressWarnings(par(oldpar))

}

# joins comp results and writes csv tables and created sp and ts plots
write_vals1 <- function(pnid,tag_ref,tag_c,values,years,save_png=TRUE) {
  
  print(paste("function write_vals1(",tag_ref,tag_c,save_png,")"))

  y1=years[1]
  y2=years[length(years)]

  file_csv=paste(g_out_dir,tag_ref,"-",tag_c,".burnpix.",pnid,".",y1,"-",y2,"_csv.csv",sep="")
  file_xls=paste(g_out_dir,tag_ref,"-",tag_c,".",pnid,".",y1,"-",y2,".xls",sep="")
  file_sp_png=paste(g_out_dir,tag_ref,"-",tag_c,".burnpix.",pnid,".",y1,"-",y2,"_sp.png",sep="")
  file_ts_png=paste(g_out_dir,tag_ref,"-",tag_c,".burnpix.",pnid,".",y1,"-",y2,"_ts.png",sep="")
  file_sp_ps=paste(g_out_dir,tag_ref,"-",tag_c,".burnpix.",pnid,".",y1,"-",y2,"_sp.ps",sep="")
  file_ts_ps=paste(g_out_dir,tag_ref,"-",tag_c,".burnpix.",pnid,".",y1,"-",y2,"_ts.ps",sep="")

  png_w=1000
  png_h=1000
  ps_w=8.5
  ps_h=8.5
  
  print(paste(y1,y2,file_sp_png,file_csv))

  values <- recompute_table_stats1(values,years)

  print(paste("==========writing to csv file",file_csv))
  write.csv(values,file_csv)
##  print(paste("==========writing to csv file",file_xls))
##  system(paste("csv2xls",file_csv,file_xls))
#write.table(values2,csv_file,quote=TRUE,sep=",",eol="\r\n",dec=".",qmethod="double")

#  ny=nrow(values)-2
  ny=length(years)
  mean_values <- values[ny+1,] 
  sd_values <- values[ny+2,]
  val_values <- values[1:ny,]
  print(paste("==========saving scatterplot",file_sp_png))
  
  fit <- lsfit(val_values[,1],val_values[,2])
  r2 <- round(as.numeric(ls.print(fit,print.it=FALSE)$summary[2]), 2)
  corr <- round(cor(val_values[,1],val_values[,2],use="complete.obs"), 2)
  
#  if (save_png==TRUE)  png(filename=file_sp_png,bg='white')
  if (save_png==TRUE)  png(filename=file_sp_png,bg='white')
  else postscript(file=file_sp_ps,paper="special",width=ps_w,height=ps_h,horizontal=F)

#  par(mai=c(0.5,0.5,0.5,0.5))
#  plot(val_values[,1],val_values[,2],
#       main="Burned Area TM x MCD45",xlab="TM     (km)",       ylab="MCD45     (km)",
#       las=0,font.main=2,font.lab=2)#mai=c(0.5,3.5,0.5,0.5))
  mar <- par("mar")
  mar[2] <- mar[2]+1.5
  mar[4] <- mar[4]-1
  par(mar=mar)
  tmp_max=1.1*max(max(val_values[,1],na.rm=T),max(val_values[,2],na.rm=T))
  print(paste("tmp_max:",tmp_max))
#  title <- paste("Burned Area ",tag_ref," x ",tag_c,sep="")
  mtitle <- "Burned Area values"
  plot(val_values[,1],val_values[,2],
       xlim=c(0,tmp_max),ylim=c(0,tmp_max),
       main=mtitle,xlab=paste(tag_ref,"     (km)",sep=""), ylab="",
       las=1,font.main=2,font.lab=2,mar=mar,cex.axis=1,cex.lab=1.5,cex.main=2)#mai=c(0.5,3.5,0.5,0.5))
  mtext(2, text=paste(tag_c,"     (km)",sep=""), line=3.5, font=2, cex=1.5)
  abline(fit, lwd=2)
  abline(0,1, col = "lightgray", lwd=1)
  usr <- par('usr')
#  base_x=usr[1]+50
#  base_y=usr[4]-50
  base_x=usr[1]+100
  base_y=usr[4]
  diff_x=100*6.666667/par("din")[1]
  diff_y=85
#  print(paste(diff_x,diff_y))
#  text(base_x, base_y-10, bquote(R^2 == .(r2)), adj=c(0,1))
#  text(base_x, base_y-50, bquote(r == .(corr)), adj=c(0,1))
  tmp_m=round(fit$coefficients[2],2)
  tmp_b=round(fit$coefficients[1],0)
  if(tmp_b>=0) { tmp_eq=bquote(y == .(tmp_m) * x + .(tmp_b) )}
  else { tmp_b=-tmp_b; tmp_eq=bquote(y == .(tmp_m) * x - .(tmp_b) )}

#  text(base_x, base_y-10, bquote(y == .((tmp_m)).((tmp_p)).((tmp_b))), adj=c(0,1))
#  text(base_x, base_y-20, tmp_eq, adj=c(0,1))
#  text(base_x, base_y-50, bquote(R^2 == .(r2)), adj=c(0,1))
#  text(base_x, base_y-100, bquote(r == .(corr)), adj=c(0,1))
  tmp_pos=cnvrt.coords(0.1,0.9,input = c("plt"))$usr
  text(tmp_pos$x, tmp_pos$y, tmp_eq, adj=c(0,0))
  tmp_pos=cnvrt.coords(0.1,0.85,input = c("plt"))$usr
  text(tmp_pos$x, tmp_pos$y, bquote(R^2 == .(r2)), adj=c(0,0))
  tmp_pos=cnvrt.coords(0.1,0.8,input = c("plt"))$usr
  text(tmp_pos$x, tmp_pos$y, bquote(r == .(corr)), adj=c(0,0))

                                        #  print(par("din"))
##  rect(base_x-10, base_y-80,base_x-10+diff_x,base_y-80+diff_y)
#  print(paste(base_x-10, base_y-75,base_x-10+diff_x,base_y-75+diff_y))
  dev.off()
#  suppressWarnings(par(oldpar))
  
    if(F) {
  print(paste("==========saving timeseries",file_ts_png))

  #ET must adjust this to the data used...  ugly hack!!!
  xlabs <- years
#  xlabs <- xlabs[1:ny+1]
  if (save_png==TRUE)  png(filename=file_ts_png,bg='white')
  else postscript(file=file_ts_ps,paper="special",width=ps_w,height=ps_h,horizontal=F)
#  else postscript(file=file_ts_ps,horizontal=F)

  mar <- par("mar")
  mar[2] <- mar[2]+1.5
  mar[4] <- mar[4]-1
  par(mar=mar)

  ylim <- get_ylim(val_values[,1:2],scale=0.05)
  ylim[1] <- 0

#  mtitle <- paste("Burned Area ",tag_ref," - ",tag_c," timeseries",sep="")
#  mtitle <- "Burned Area timeseries"
  mtitle <- paste(g_year,"Burned Area timeseries",sep=" - ")
  tTicks <- barplot( main=mtitle, xlab="Years",ylab="",
                    las=1,font.main=2,font.lab=2,legend.text=c(tag_ref,tag_c),args.legend = list(x = "top"),
                    t(val_values[,1:2]),names.arg=xlabs,beside=TRUE,xaxt='n',ylim=ylim,cex.axis=1,cex.lab=1.5,cex.main=2) #space=c(0,2))
  tTicks <- tapply(tTicks, rep(1:length(xlabs), each=2), mean)
  axis(1, tTicks, xlabs)
  mtext(2, text = "Burned Area     (km)", line=3.5, font=2, cex=1.5)
  box()
  dev.off()
#  suppressWarnings(par(oldpar))

}

  
#  ofileo_tif=paste(g_out_dir,sub(years[1],paste(years[1],"-",years[ny],".occur",sep=""),basename(ifiles[1])),sep="")
#  ofilef_tif=paste(g_out_dir,sub(years[1],paste(years[1],"-",years[ny],".freq",sep=""),basename(ifiles[1])),sep="")
  file_ref_occur=paste(g_out_dir,tag_ref,".burnpix.",pnid,".",y1,"-",y2,".occur.tif",sep="")
  file_ref_freq=paste(g_out_dir,tag_ref,".burnpix.",pnid,".",y1,"-",y2,".freq.tif",sep="")
  file_c_occur=paste(g_out_dir,tag_c,".burnpix.",pnid,".",y1,"-",y2,".occur.tif",sep="")
  file_c_freq=paste(g_out_dir,tag_c,".burnpix.",pnid,".",y1,"-",y2,".freq.tif",sep="")
  file_csv_occur=paste(g_out_dir,tag_ref,"-",tag_c,".burnpix.",pnid,".",y1,"-",y2,".occur.csv",sep="")
  file_csv_freq=paste(g_out_dir,tag_ref,"-",tag_c,".burnpix.",pnid,".",y1,"-",y2,".freq.csv",sep="")
#  file_ref_occur=paste(g_out_dir,tag_ref,".burnpix.",pnid,".",y1,"-",y2,".occur.png",sep="")
#  file_ref_freq=paste(g_out_dir,tag_ref,".burnpix.",pnid,".",y1,"-",y2,".freq.png",sep="")
#  file_c_occur=paste(g_out_dir,tag_c,".burnpix.",pnid,".",y1,"-",y2,".occur.png",sep="")
#  file_c_freq=paste(g_out_dir,tag_c,".burnpix.",pnid,".",y1,"-",y2,".freq.png",sep="")
  
#  make_img_yearly_stats(file_ref_occur,NULL,file_ref_freq,NULL,r_max=NULL)
#  make_img_yearly_stats(file_c_occur,NULL,file_c_freq,NULL,r_max=NULL)
  make_img_yearly_stats(file_ref_occur,file_ref_freq,tag_ref,
                        file_c_occur,file_c_freq,tag_c)

  ave_freq <- spatial_average(file_ref_freq,file_c_freq,tag_ref,tag_c,tag_c,tag_c,tag_ref,tag_c,do_scatterplot=F,do_spatial_plot=F)
  print("ave_freq:")
  print(ave_freq)
  write.csv(t(ave_freq),file_csv_freq)

  ave_occur <- spatial_average(file_ref_occur,file_c_occur,tag_ref,tag_c,tag_c,tag_c,tag_ref,tag_c,do_scatterplot=F,do_spatial_plot=F)
  print("ave_occur:")
  print(ave_occur)
  write.csv(t(ave_occur),file_csv_occur)

  
  invisible(values)
}


# joins comp results and writes csv tables and created sp and ts plots
write_vals2 <- function(pnids,tag_ref,tags_c,values,year,save_png=TRUE) {
  
  print(paste("function write_vals2(",tag_ref,paste(tags_c),save_png,")"))

#  y1=years[1]
#  y2=years[length(years)]

  png_w=1000
  png_h=1000
  ps_w=8.5
  ps_h=8.5
  
  values <- recompute_table_stats2(values,pnids,tags_c)
  
  for(i in 1:length(tags_c)) {
    tag_c=tags_c[[i]]
    file_csv=paste(g_out_dir,tag_ref,"-",tag_c,".burnpix_csv.csv",sep="")
    file_xls=paste(g_out_dir,tag_ref,"-",tag_c,".burnpix_csv.xls",sep="")
    file_sp_png=paste(g_out_dir,tag_ref,"-",tag_c,".burnpix_sp.png",sep="")
    file_sp_ps=paste(g_out_dir,tag_ref,"-",tag_c,".burnpix_sp.ps",sep="")
    file_ts_png=paste(g_out_dir,tag_ref,"-",tag_c,".burnpix_ts.png",sep="")
    file_ts_ps=paste(g_out_dir,tag_ref,"-",tag_c,".burnpix_ts.ps",sep="")
  #print(paste(y1,y2,file_sp_png,file_csv))


  print(paste("==========writing to csv file",file_csv))
  write.csv(values[[i]],file_csv)
##  print(paste("==========writing to csv file",file_xls))
##  system(paste("csv2xls",file_csv,file_xls))
#write.table(values2,csv_file,quote=TRUE,sep=",",eol="\r\n",dec=".",qmethod="double")

#  ny=nrow(values)-2
  ny=length(pnids)
  mean_values <- values[[i]][ny+1,] 
  sd_values <- values[[i]][ny+2,]
  val_values <- values[[i]][1:ny,]

    print(paste("==========saving scatterplot",file_sp_ps))
  
  fit <- lsfit(val_values[,1],val_values[,2])
  r2 <- round(as.numeric(ls.print(fit,print.it=FALSE)$summary[2]), 3) #was rounded at 2 decimals, but use 3 to show 0.99x
  corr <- round(cor(val_values[,1],val_values[,2],use="complete.obs"), 3)

#  if (save_png==TRUE)  png(filename=file_sp_png,bg='white')
  if (save_png==TRUE)  png(filename=file_sp_png,bg='white')
  else postscript(file=file_sp_ps,paper="special",width=ps_w,height=ps_h,horizontal=F)

#  par(mai=c(0.5,0.5,0.5,0.5))
#  plot(val_values[,1],val_values[,2],
#       main="Burned Area TM x MCD45",xlab="TM     (km)",       ylab="MCD45     (km)",
#       las=0,font.main=2,font.lab=2)#mai=c(0.5,3.5,0.5,0.5))
  mar <- par("mar")
  mar[2] <- mar[2]+1.5
  mar[4] <- mar[4]-1
  par(mar=mar)
  tmp_max=1.1*max(max(val_values[,1],na.rm=T),max(val_values[,2],na.rm=T))
  print(paste("tmp_max:",tmp_max))
#  title <- paste("Burned Area ",tag_ref," x ",tag_c,sep="")
#  mtitle <- "Burned Area values"
  mtitle <- paste(g_year,"Burned Area values",sep=" - ")
  plot(val_values[,1],val_values[,2],
       xlim=c(0,tmp_max),ylim=c(0,tmp_max),
       main=mtitle,xlab=paste(tag_ref,"     (km)",sep=""), ylab="",
       las=1,font.main=2,font.lab=2,mar=mar,cex.axis=1,cex.lab=1.5,cex.main=2)#mai=c(0.5,3.5,0.5,0.5))
  mtext(2, text=paste(tag_c,"     (km)",sep=""), line=3.5, font=2, cex=1.5)
  abline(fit, lwd=2)
  abline(0,1, col = "lightgray", lwd=1)
  usr <- par('usr')
#  base_x=usr[1]+50
#  base_y=usr[4]-50
  base_x=usr[1]+100
  base_y=usr[4]
  diff_x=100*6.666667/par("din")[1]
  diff_y=85
#  print(paste(diff_x,diff_y))
#  text(base_x, base_y-10, bquote(R^2 == .(r2)), adj=c(0,1))
#  text(base_x, base_y-50, bquote(r == .(corr)), adj=c(0,1))
  tmp_m=round(fit$coefficients[2],2)
  tmp_b=round(fit$coefficients[1],0)
  if(tmp_b>=0) { tmp_eq=bquote(y == .(tmp_m) * x + .(tmp_b) )}
  else { tmp_b=-tmp_b; tmp_eq=bquote(y == .(tmp_m) * x - .(tmp_b) )}

#  text(base_x, base_y-10, bquote(y == .((tmp_m)).((tmp_p)).((tmp_b))), adj=c(0,1))
#  text(base_x, base_y-20, tmp_eq, adj=c(0,1))
#  text(base_x, base_y-50, bquote(R^2 == .(r2)), adj=c(0,1))
#  text(base_x, base_y-100, bquote(r == .(corr)), adj=c(0,1))
  tmp_pos=cnvrt.coords(0.1,0.9,input = c("plt"))$usr
  text(tmp_pos$x, tmp_pos$y, tmp_eq, adj=c(0,0))
  tmp_pos=cnvrt.coords(0.1,0.85,input = c("plt"))$usr
  text(tmp_pos$x, tmp_pos$y, bquote(R^2 == .(r2)), adj=c(0,0))
  tmp_pos=cnvrt.coords(0.1,0.8,input = c("plt"))$usr
  text(tmp_pos$x, tmp_pos$y, bquote(r == .(corr)), adj=c(0,0))

                                        #  print(par("din"))
##  rect(base_x-10, base_y-80,base_x-10+diff_x,base_y-80+diff_y)
#  print(paste(base_x-10, base_y-75,base_x-10+diff_x,base_y-75+diff_y))
  dev.off()
#  suppressWarnings(par(oldpar))


    if(F) {
  print(paste("==========saving timeseries",file_ts_ps))

  #ET must adjust this to the data used...  ugly hack!!!
  xlabs <- pnids
#  xlabs <- xlabs[1:ny+1]
  if (save_png==TRUE)  png(filename=file_ts_png,bg='white')
  else postscript(file=file_ts_ps,paper="special",width=ps_w,height=ps_h,horizontal=F)
#  else postscript(file=file_ts_ps,horizontal=F)

  mar <- par("mar")
  mar[2] <- mar[2]+1.5
  mar[4] <- mar[4]-1
  par(mar=mar)

  ylim <- get_ylim(val_values[,1:2],scale=0.05)
  ylim[1] <- 0

    # ET TODO HERE!!!xs
#  mtitle <- paste("Burned Area ",tag_ref," - ",tag_c," timeseries",sep="")
  mtitle <- "Burned Area timeseries"
    tTicks <- barplot( main=mtitle, xlab="protected areas",ylab="",
                    las=1,font.main=2,font.lab=2,legend.text=c(tag_ref,tag_c),args.legend = list(x = "top"),
                    t(val_values[,1:2]),names.arg=xlabs,beside=TRUE,xaxt='n',ylim=ylim,cex.axis=1,cex.lab=1.5,cex.main=2) #space=c(0,2))
  tTicks <- tapply(tTicks, rep(1:length(xlabs), each=2), mean)
  axis(1, tTicks, xlabs)
  mtext(2, text = "Burned Area     (km)", line=3.5, font=2, cex=1.5)
  box()
  dev.off()
#  suppressWarnings(par(oldpar))

}
    
  } # for length(tag_c
  

  invisible(values)
}

write_histos <- function(tags,values,locations,pnids){

  tags2 <- tags[2:length(tags)]
  print("function write_histos")


  histo_ba <- matrix(NA,nrow=3,ncol=length(locations))
dimnames(histo_ba) <- list(tags,locations)
histo_bf <- matrix(NA,nrow=3,ncol=length(locations))
dimnames(histo_bf) <- list(tags,locations)
histo_k <- matrix(NA,nrow=2,ncol=length(locations))
dimnames(histo_k) <- list(tags2,locations)
histo_oa <- matrix(NA,nrow=2,ncol=length(locations))
dimnames(histo_oa) <- list(tags2,locations)
histo_ce <- matrix(NA,nrow=2,ncol=length(locations))
dimnames(histo_ce) <- list(tags2,locations)
histo_oe <- matrix(NA,nrow=2,ncol=length(locations))
dimnames(histo_oe) <- list(tags2,locations)
histo_sp5km <- matrix(NA,nrow=2,ncol=length(locations))
dimnames(histo_sp5km) <- list(tags2,locations)

for (i in 1:length(locations)) {

    histo_ba[1,i] <- values[[1]][i,1]
    histo_ba[2,i] <- values[[1]][i,2]
    histo_ba[3,i] <- values[[2]][i,2]
    histo_bf[1,i] <- values[[1]][i,3]
    histo_bf[2,i] <- values[[1]][i,4]
    histo_bf[3,i] <- values[[2]][i,4]

    histo_k[1,i] <- values[[1]][i,8]
    histo_k[2,i] <- values[[2]][i,8]
    histo_oa[1,i] <- values[[1]][i,5]
    histo_oa[2,i] <- values[[2]][i,5]
    histo_ce[1,i] <- values[[1]][i,6]
    histo_ce[2,i] <- values[[2]][i,6]
    histo_oe[1,i] <- values[[1]][i,7]
    histo_oe[2,i] <- values[[2]][i,7]
    histo_sp5km[1,i] <- values[[1]][i,15]
    histo_sp5km[2,i] <- values[[2]][i,15]

  }

  scene=locations[i]

  if(pnids){
  write_histo(tags,histo_ba,locations,"histo_burnarea",paste("Burned Area by scene (",g_year,")",sep=""),"Burned Area (km^2)",save_png=T)
  write_histo(tags,histo_bf,locations,"histo_burnfrac",paste("Burned Fraction by scene(",g_year,")",sep=""),"Burned Fraction (%)",save_png=T)
  write_histo(tags2,histo_k,locations,"histo_kappa",paste("Kappa score by scene (",g_year,")",sep=""),"Kappa score",save_png=T)
  write_histo(tags2,histo_oa,locations,"histo_oa",paste("Overall Accuracy by scene (",g_year,")",sep=""),"Overall Accuracy (%)",save_png=T)
  write_histo(tags2,histo_ce,locations,"histo_ce",paste("Commision Error by scene (",g_year,")",sep=""),"Commision Error (%)",save_png=T)
  write_histo(tags2,histo_oe,locations,"histo_oe",paste("Ommision Error by scene (",g_year,")",sep=""),"Omision Error (%)",save_png=T)
  write_histo(tags2,histo_sp5km,locations,"histo_sp5km",paste("Spatial correlation at 5km (",g_year,")",sep=""),"Spatial correlation",save_png=T)
}
  else {
  write_histo(tags,histo_ba,locations,"histo_burnarea",paste("Burned Area by year (",g_pnid,")",sep=""),"Burned Area (km^2)",save_png=T)
  write_histo(tags,histo_bf,locations,"histo_burnfrac",paste("Burned Fraction by year(",g_pnid,")",sep=""),"Burned Fraction (%)",save_png=T)
  write_histo(tags2,histo_k,locations,"histo_kappa",paste("Kappa score by year (",g_pnid,")",sep=""),"Kappa score",save_png=T)
  write_histo(tags2,histo_oa,locations,"histo_oa",paste("Overall Accuracy by year (",g_pnid,")",sep=""),"Overall Accuracy (%)",save_png=T)
  write_histo(tags2,histo_ce,locations,"histo_ce",paste("Commision Error by year (",g_pnid,")",sep=""),"Commision Error (%)",save_png=T)
  write_histo(tags2,histo_oe,locations,"histo_oe",paste("Ommision Error by year (",g_pnid,")",sep=""),"Omision Error (%)",save_png=T)
  write_histo(tags2,histo_sp5km,locations,"histo_sp5km",paste("Spatial correlation at 5km (",g_pnid,")",sep=""),"Spatial correlation",save_png=T)
  }
}


write_histo <- function(tags,values,locations,filen,mtitle,axis,save_png=TRUE) { #,ymin=0) {

  nloc=length(locations)
  ps_w=8.5
  ps_h=8.5

  file_png=paste(g_out_dir,filen,".png",sep="")
  file_ps=paste(g_out_dir,filen,".ps",sep="")

  print(paste("function write_histo",file_png))

  tmp_values <- values
  xlabs <- locations
  
  if (save_png==TRUE)  png(filename=file_png,bg='white')
#  else postscript(file=file_ps)
  else postscript(file=file_ps,paper="special",width=ps_w,height=ps_h,horizontal=F)

  mar <- par("mar")
  mar[2] <- mar[2]+1.5
  mar[4] <- mar[4]-1
  par(mar=mar)

  par(mgp=c(4,1,0))
  
  ylim=get_ylim(tmp_values[,],scale=0.05)
  #if(ylim[1]>0)
  #  ylim[1] <- ymin
#  ylim <- NULL
  tTicks <- barplot( main=mtitle,
                    xlab="scenes",ylab="",
                    las=1,font.main=2,font.lab=2,legend.text=tags,args.legend = list(x = "top"),
                    tmp_values,names.arg=xlabs,beside=TRUE,xaxt='n',ylim=ylim,cex.axis=1,cex.lab=1.5,cex.main=2)
  if(ylim[1]<0)
    abline(h=0)#,col = "lightgray", lwd=1)
  tTicks <- tapply(tTicks, rep(1:length(xlabs), each=length(tags)), mean)
  #axis(1, tTicks, xlabs)
  #text(tTicks, par("usr")[3] - 1.5, labels=xlabs, srt=45, xpd=TRUE,pos=1, offset=2, adj=1)
  text(tTicks, par("usr")[3], labels=xlabs, srt=45, xpd=TRUE,adj=c(1,2))
  mtext(2, text = axis, line=3.5, font=2, cex=1.5)
  box()
  dev.off()
#  suppressWarnings(par(oldpar))

}

#########################################################################################

#source("/data/docs/research/scripts/process-pn.R") ;dopns();
dopns <- function(){
dopn(pnid="PNSCa");dopn(pnid="PNE");
}

#source("/data/docs/research/scripts/process-pn.R") ;dopn(pnid="PNSCa");dopn(pnid="PNE");
#v2=dopn(vals=NULL,write_vals=FALSE); doit(vals=v2)
dopn <- function(pnid="PNSCa",vals=NULL,write_vals=TRUE,make_img=TRUE) {
  tag_ref <- "TM"
#  tags_c<- list("MCD45","L3JRC")
#  years <- list(seq(from=2000,to=2010),seq(from=2000,to=2006))
  tags_c<- list("MCD45","MCD64")
#  years <- list(seq(from=2000,to=2010),seq(from=2000,to=2010))
  years <- seq(from=2000,to=2010)
#  years <- seq(from=2009,to=2010)

  file_shp_dir <- "/data/research/work/allpn/Dados_UC/shapes/PN-Etienne"
  g_shp_file <<- paste(file_shp_dir,"/",pnid,"_pol.shp",sep="")
  g_shp_lyr <<- paste(pnid,"_pol",sep="")
  g_boundary <<- readOGR(g_shp_file,g_shp_lyr)
  g_out_dir <<- paste("out/",pnid,"/",sep="")
  system(paste("mkdir -p",g_out_dir))
  g_pnid <<- pnid

#  if(pnid=="PNSCa" | pnid=="PNE")
    vals = doit1(pnid,tag_ref,tags_c,years,vals=vals,write_vals=write_vals,make_img=make_img)

  invisible(vals)
}

# source("/data/docs/research/scripts/process-pn.R") ; doallpn()
doallpn <- function(){#pnid="PNSCa",vals=NULL,write_vals=TRUE,make_img=TRUE) {
  pnids <- list("PNCG","PNB","PNCV","PNE","PNSCa");# PNSCi
#  pnids <- list("PNE","PNB");# PNSCi
  tag_ref <- "TM"
#  tags_c<- list("MCD45","L3JRC")
  tags_c<- list("MCD45","MCD64")
  years <- list(2010)


  vals = doit2(pnids,tag_ref,tags_c,years,vals=NULL,write_vals=T,make_img=F)#vals=vals,write_vals=write_vals,make_img=make_img)
#  vals = doit2(pnids,tag_ref,tags_c,years,vals=NULL,write_vals=T,make_img=F)#vals=vals,write_vals=write_vals,make_img=make_img)

  invisible(vals)
}


#v2=doit(vals=NULL,write_vals=FALSE); doit(vals=v2)
# processes a given PN for a number of years
doit1 <- function(pnid,tag_ref,tags_c,years,vals=NULL,write_vals=TRUE,make_img=TRUE) {

  print("function doit1()")
  print(tag_ref)
  print(tags_c)
  print(years)

  if(is.null(vals)) {
    print("======================================================================")
    print("processing vals")
print(tags_c)
#    vals=process_vals(pnid,tag_ref,tags_c[[1]],tag_c2=tags_c[[2]],years=years[[1]],write_vals=FALSE,save_png=TRUE,make_img=make_img)
#      vals2=process_vals(pnid,tag_ref,tags_c[[1]],tag_c2=tags_c[[2]],years=years[[2]],write_vals=FALSE,save_png=TRUE,make_img=FALSE)
    vals=process_vals(pnid,tag_ref,tags_c[[1]],tag_c2=tags_c[[2]],years=years,write_vals=FALSE,save_png=TRUE,make_img=make_img)
#    vals2=NULL
    print(paste(pnid,tag_ref,tags_c[[1]],tag_c2=tags_c[[2]]))
    print("======================================================================")
    print("done processing vals")
#    print(vals)
   }
  values <- list()
 if(write_vals) {
      print("======================================================================")
      print(paste("writing vals"))
      for(j in 1:length(tags_c)) {
        values[[j]] = write_vals1(pnid,tag_ref,tags_c[[j]],vals[[j]],years=years,save_png=T)
      }
      write_ts(pnid,tag_ref,tags_c[[1]],vals[[1]],tags_c[[2]],vals[[2]],years=years,save_png=T)
#      write_ts(pnid,tag_ref,tags_c[[1]],vals[[1]],tags_c[[2]],vals[[2]],years=years[[i]],save_png=T)


      write_histos(c(tag_ref,tags_c),values,years,pnids=F)
    
  }

  # TODO fix csv/xls output
#  #merge xls files
#  y1=years[[1]][1]
#  y2=years[[1]][length(years[[1]])]
#  cwd <- setwd(g_out_dir)
  
#  ofile_xls=paste(tag_ref,"-",tags_c[[1]],"-",tags_c[[2]],".",pnid,".",y1,"-",y2,".xls",sep="")
#  unlink(ofile_xls)
#  ifiles_xls=dir(".","*.xls")
#  ifiles_xls=paste(ifiles_xls,collapse=" ")
#  cmd=paste("xlsmerge -o",ofile_xls,ifiles_xls)
#  print(paste("==========writing to file",ofile_xls))
#  system(cmd)
#  setwd(cwd)
  
  invisible(vals)
}


# processes a list of PN for a number of years
doit2 <- function(pnids,tag_ref,tags_c,year,vals=NULL,write_vals=TRUE,make_img=TRUE) {

  print("function doit2()")
  print(pnids)
  print(tag_ref)
  print(tags_c)
  print(year)

  #indexes: i->pnids j->tags_c
  if(is.null(vals)) {
    vals=list()
    print("======================================================================")
    for(i in 1:length(pnids)) {
      print("======================================================================")
      pnid <- pnids[[i]]
      g_pnid <<- "ALL"
      print(pnids[[i]])

      
      file_shp_dir <- "/data/research/work/allpn/Dados_UC/shapes/PN-Etienne"
      g_shp_file <<- paste(file_shp_dir,"/",pnid,"_pol.shp",sep="")
      g_shp_lyr <<- paste(pnid,"_pol",sep="")
      g_boundary <<- readOGR(g_shp_file,g_shp_lyr)
      g_out_dir <<- paste("out/",year,"/",sep="")
      system(paste("mkdir -p",g_out_dir))
      
      vals[[i]]=process_vals(pnids[[i]],tag_ref,tags_c[[1]],tag_c2=tags_c[[2]],years=c(year),write_vals=FALSE,save_png=TRUE,make_img=make_img)
#    vals2=NULL
      print("======================================================================")
      print("done processing vals")
    }
      #print(vals)
   }
  
 if(write_vals) {
      print("======================================================================")
#      for(j in 1:length(tags_c)) {
        print(paste("writing vals"))
#        print(vals)
#        write_vals2(pnids,tag_ref,tags_c[[j]],vals,year=year,save_png=FALSE)
        vals = write_vals2(pnids,tag_ref,tags_c,vals,year=year,save_png=T)
#      }
      write_ts2(pnids,tag_ref,tags_c[[1]],vals[[1]],tags_c[[2]],vals[[2]],year=year,save_png=T)
#      write_ts(pnid,tag_ref,tags_c[[1]],vals[[1]],tags_c[[2]],vals[[2]],years=years[[i]],save_png=T)

      write_histos(c(tag_ref,tags_c),vals,pnids,pnids=T)
    }

  
  # TODO fix csv/xls output
#  #merge xls files
#  y1=years[[1]][1]
#  y2=years[[1]][length(years[[1]])]
#  cwd <- setwd(g_out_dir)
  
#  ofile_xls=paste(tag_ref,"-",tags_c[[1]],"-",tags_c[[2]],".",pnid,".",y1,"-",y2,".xls",sep="")
#  unlink(ofile_xls)
#  ifiles_xls=dir(".","*.xls")
#  ifiles_xls=paste(ifiles_xls,collapse=" ")
#  cmd=paste("xlsmerge -o",ofile_xls,ifiles_xls)
#  print(paste("==========writing to file",ofile_xls))
#  system(cmd)
#  setwd(cwd)
  
  invisible(vals)
}

load_tables <- function (ifile1,ifile2=NULL) {
  if(file.exists(ifile1))
    values1 <- read.csv(ifile1,row.names=1)
  if(!is.null(ifile2) && file.exists(ifile2))
    values2 <- read.csv(ifile2,row.names=1)
  else values2 <- NA

  invisible(list(values1,values2))
}



