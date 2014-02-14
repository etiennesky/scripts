source("/data/docs/research/scripts/myFunctions.R")

#library(car)
#library(stringr)
#library(plotrix)
library("grDevices")

# install.packages("rgdal","raster","car","stringr","plotrix")
# install gdal-bin netcdf-bin python-gdal
# build cdo
# source("/data/docs/research/scripts/process-ba.R")

# f in ???_???_{tm,mcd??}_500m.tif ; do echo $f ; gdal_translate -of aaigrid $f fuzzy/`basename $f .tif`.asc ; done

# ==============================================================================
# functions

spatial_average <- function( ifile1,ifile2,n1,n2,n3,res,title,t1,t2,burn_ratio=0,do_scatterplot=TRUE,save_png=TRUE,do_spatial_plot=TRUE) {
  print(paste("spatial_average",ifile1,ifile2))
  r1 <- readGDAL(ifile1,silent=debug_silent)
  r2 <- readGDAL(ifile2,silent=debug_silent)

  # report means and correlation
  mean1 <- mean(r1@data[[1]],na.rm=TRUE)
  mean2 <- mean(r2@data[[1]],na.rm=TRUE)
  cor1 <- cor(r1@data[[1]],r2@data[[1]], use="complete.obs",  method = "pearson")
  #cat(paste("\nmean_",n1," : ",mean1," mean_",n2," : ",mean2,"\ntot_",n1,"  : ",mean1*res*res," tot_",n2,"  : ",mean2*res*res," \nspatial correlation: ",cor1,"\n\n"),sep="")

  names=c(paste("mean_",n1,sep=""),paste("mean_",n3,sep=""),"sp. corr.",paste("tot_",n1,sep=""),paste("tot_",n3,sep=""),"bratio")
  values=c(mean1,mean2,cor1,mean1*res*res,mean2*res*res,burn_ratio)
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
      ofile_prefix=paste(substr(ifile1,1,tmpi1[1]-1),"-",substr(ifile2,1,tmpi2[1]-1),sep="")
      ofile=paste(g_out_dir,ofile_prefix,"_scatter.png",sep="")
      png(filename=ofile,width=png_w, height=png_h,bg='white')
    }

    s <- scatterplot(r1@data[[1]],r2@data[[1]],xlab=n1,ylab=n2,main=title,cex=base_cex)

    dev.off()
    
    lm1 <- lm(r1@data[[1]] ~ r2@data[[1]])
    #print(summary(lm1))
    #readline(prompt = "scatterplot drawn. Press <Enter> to continue...")
  }

  if (do_spatial_plot) {
    # change boundary if resolution is in degrees, this does not seem to work though with TM maps...
    if ( res <= 1 )
      boundary=g_boundary2
    else
      boundary=g_boundary
    #print(res)
    #print(boundary)
    make_imgs(ifile1,ifile2,"","ta",t1,t2,save_png=TRUE,make_img_diff=FALSE,make_img_single=TRUE,col_black=FALSE,boundary=boundary)
}  
  #print("")
  #print(values)
  invisible(values)
}

# =================================
# begin copied from process-pn.R

process_files <- function (ifile1,ifile2,t1,t2,make_img=FALSE) {
print(paste("===== function process_files(",ifile1,ifile2,")"))

tmpi1=str_locate(ifile1,"\\.")
tmpi2=str_locate(ifile2,"\\.")
ofile_prefix=paste(substr(ifile1,1,tmpi1[1]-1),"-",substr(ifile2,1,tmpi2[1]-1),".",sub(".tif","",substring(ifile1,tmpi1[1]+1)),sep="")

if ( file.exists(ifile1) && file.exists(ifile2) )
  e1=myErrReport(ifile2,ifile1)
else e1=NA

invisible(e1)
}

process_rasters <- function (ifile1,ifile2,ta,t1,t2,t3,make_img=FALSE) {
print(paste("===== function process_rasters(",ifile1,ifile2,")"))

  r1 <- readGDAL(ifile1,silent=debug_silent)
  r2 <- readGDAL(ifile2,silent=debug_silent)

tmpi1=str_locate(ifile1,"\\.")
tmpi2=str_locate(ifile2,"\\.")
ofile_prefix=paste(substr(ifile1,1,tmpi1[1]-1),"-",substr(ifile2,1,tmpi2[1]-1),".",sub(".tif","",substring(ifile1,tmpi1[1]+1)),sep="")
print(ofile_prefix)
if(make_img==TRUE) make_imgs(ifile1,ifile2,ofile_prefix,ta,t1,t2,save_png=TRUE,make_img_diff=TRUE,make_img_single=FALSE)

cat("\nreport",t1,"vs.",t2,":\n")
e1=myErrReport2(r2,r1,t3,t1)
#print(e1)

print("===== function process_rasters done")

invisible(e1)
}

make_imgs <- function (ifile1,ifile2,ofile_prefix,ta,t1,t2,save_png=TRUE,make_img_diff=TRUE,make_img_single=FALSE,col_black=TRUE,boundary=g_boundary) {

  print(paste("function make_imgs(",ifile1,ifile2,ofile_prefix,save_png,make_img_diff,make_img_single,")"))
ofile1_png=paste(g_out_dir,sub(".tif",".png",basename(ifile1)),sep="")
#ofile1_ps=paste(g_out_dir,sub(".tif",".ps",basename(ifile1)),sep="")
ofile2_png=paste(g_out_dir,sub(".tif",".png",basename(ifile2)),sep="")
#ofile_png=paste(g_out_dir,ofile_prefix,".png",sep="")
ofile_png=paste(g_out_dir,sub(".tif",".png",basename(ofile_prefix)),sep="")
#print(paste(ofile_png))
  e_if1=(file.exists(ifile1)) 
  e_if2=(file.exists(ifile2)) 

#  png_w=1000
  png_w=2000
  png_h <- compute_img_dim (boundary@bbox,base_w=png_w)[2]

  if(e_if1) {
    raster1=readGDAL(ifile1,silent=debug_silent)
    if ( make_img_single )
      make_img_raster(raster1,ofile1_png,col_black,save_png=TRUE,png_w=png_w,png_h=png_h,ta=ta,t1=t1,boundary=boundary)
  }
  
  if(e_if2) {
    raster2=readGDAL(ifile2,silent=debug_silent)
    if ( make_img_single )
      make_img_raster(raster2,ofile2_png,col_black,save_png=TRUE,png_w=png_w,png_h=png_h,ta=ta,t1=t2,boundary=boundary)
  }
  if(make_img_diff && e_if1 && e_if2) {
    raster3=raster1
    raster3@data=raster1@data*raster2@data
    make_img_raster_diff(raster1,raster2,raster3,ofile_png,ta,t1,t2,save_png=TRUE,png_w=png_w,png_h=png_h,boundary=boundary)
  }

  print(paste("function make_imgs done"))

}


compute_img_dim <- function (bbox,base_w=1000) {
tmp_w=round(bbox[1,2]-bbox[1,1])
tmp_h=round(bbox[2,2]-bbox[2,1])
base_h=round(base_w*tmp_h/tmp_w)
invisible(c(base_w,base_h))
}

make_img_raster<- function (raster,ofile,col_black=TRUE,save_png=TRUE,png_w=1000,png_h=500,ta="",t1="",boundary=g_boundary) {
print(paste("make_img_raster(",ofile))
if ( col_black )
  col=c("white","black")
else
  col=gray(9:0/10)

if (save_png==TRUE)  png(filename=ofile,width=png_w, height=png_h,bg='white')
else postscript(file=ofile)

par(mai=c(0,0,0,0),lwd=2)


#print("doing plot")
image(raster,col=col)

#print("adding bound.")
plot(boundary,add=T)

#print("done plot")

tmp_w=par()$usr[2]-par()$usr[1]
tmp_h=par()$usr[4]-par()$usr[3]

  base_cex=3
#  base2_x=par()$usr[2]-10000
#  base2_y=par()$usr[4]-15000
  base2_x=par()$usr[2]-tmp_w*0.05
  base2_y=par()$usr[4]-tmp_h*0.075
#  base2_cex=3
  base2_cex=6
  text(base2_x,base2_y,paste(t1),cex=base2_cex,adj=c(1,0),font=2)
  ##text(base2_x,base2_y-3000,g_year,cex=base2_cex,adj=c(1,0),font=2)

if ( ! col_black ) {
  labels=c('0 ','0.2 ','0.4 ','0.6 ','0.8 ','1.0 ')
  text(par()$usr[2]-tmp_w*0.025,par()$usr[3]+tmp_h*0.02,paste("fraction"),cex=4,adj=c(1,0),font=2)
  #coords=c(par()$usr[1]+w*0.05,par()$usr[4]-h*0.50,par()$usr[1]+w*0.1,par()$usr[4]-h*0.10)
  coords=c(par()$usr[2]-tmp_w*0.075,par()$usr[3]+tmp_h*0.05,par()$usr[2]-tmp_w*0.025,par()$usr[3]+tmp_h*0.25)
  color.legend(coords[1],coords[2],coords[3],coords[4],labels,col,cex=3,gradient='h')
  #color.bar(col,0,1)
}

if(tmp_w<100) {
  scale_scale=1.0
  scale_text=expression(~1.0 ~degree)#paste("1",expression(~degree))
}
else {
scale_scale=100000
scale_text="100 km"
}
scale_x=par()$usr[1]+tmp_w*0.05
scale_y=par()$usr[3]+tmp_h*0.025
scale_text_off=tmp_h*0.04

SpatialPolygonsRescale(layout.scale.bar(), offset = c(scale_x,scale_y),
                       scale = scale_scale, fill = c("transparent", "black"), plot.grid = FALSE)
text(scale_x,scale_y+scale_text_off,"0",cex=base_cex)
text(scale_x+scale_scale,scale_y+scale_text_off,scale_text,cex=base_cex,adj=c(1,0.5))

dev.off()
##system("convert tmp.png -trim -gravity center tmp2.png")
#system(paste("convert tmp.png -trim -gravity center +repage -bordercolor white -border 10x10 +repage ",ofile,sep=""))
#system(paste("convert tmp.png -trim -gravity center +repage ",ofile,sep=""))
##system(paste("convert tmp.png -trim -gravity center -bordercolor white -border 10x10 +repage ",ofile,sep=""))
##system(paste("convert tmp2.png -trim -gravity center -bordercolor white -border 10x10 ",ofile,sep=""))
#unlink("tmp.png")
#unlink("tmp2.png")

print(paste("end make_img_raster"))

}

make_img_raster_diff <- function(raster1,raster2,raster3,ofile,ta,t1,t2,save_png=TRUE,png_w=1000,png_h=500,boundary=g_boundary) {

  print(paste("function make_img_raster_diff",ofile,save_png,png_w,png_h))

if (save_png==TRUE) png(filename=ofile,width=png_w, height=png_h,bg='white')
else ps(file=ofile)

par(mai=c(0,0,0,0),lwd=2)

  cols=c("green","blue","red")
  #cols=gray(c(0.0,0.66,0.5))
image(raster1,col=c("transparent",cols[1]))
image(raster2,col=c("transparent",cols[2]),add=T)
image(raster3,col=c("transparent",cols[3]),add=T)
plot(boundary,add=T)

#  base_cex=1.5
  base_cex=3

  #base_x=par()$usr[1]+8000
  #base_y=par()$usr[3]+6000
  #diff_y=35000
  base_x=par()$usr[2]-35000
  base_y=par()$usr[3]+30000

  scale_scale=100000
  scale_x=par()$usr[1]+8000
  scale_y=par()$usr[3]+6000
  scale_text_off <- 8000

  arrow_scale=20000
  arrow_x=par()$usr[1]+58000
  arrow_y=par()$usr[3]+20000

#  base2_x=par()$usr[2]-17000
#  base2_y=par()$usr[4]-4000
  base2_x=par()$usr[2]-10000
  base2_y=par()$usr[4]-15000
#  base2_cex=3
  base2_cex=6
  
##  if(g_pnid=="PNE") {
##    base_x=par()$usr[1]+2000
##    base_y=par()$usr[4]-10000
###    base_y=par()$usr[3]+1500
##    diff_y=8000
##    base_cex=2
##  }
  
legend(base_x,base_y,c(t1,t2,"intersect  "),fill=cols,inset=0.05,cex=base_cex)
SpatialPolygonsRescale(layout.scale.bar(), offset = c(scale_x,scale_y),
                       scale = scale_scale, fill = c("transparent", "black","transparent", "black"), plot.grid = FALSE)
#SpatialPolygonsRescale(layout.north.arrow(type = 1), offset = c(arrow_x,arrow_y),
#                       scale = arrow_scale, fill = c("transparent", "black","transparent", "black"), plot.grid = FALSE)
text(scale_x,scale_y+scale_text_off,"0",cex=base_cex)
text(scale_x+scale_scale,scale_y+scale_text_off,"100 km",cex=base_cex,adj=c(1,0.5))

#  text(base2_x,base2_y,paste(t1,"-",t2),cex=base2_cex,adj=c(0,0),font=2)
#  text(base2_x,base2_y-3000,g_year,cex=base2_cex,adj=c(0,0),font=2)
#  text(base2_x,base2_y,paste(t1,"-",t2," / ",g_year),cex=base2_cex,adj=c(1,0),font=2)

#  text(base2_x,base2_y,paste(ta,"/",t1,"vs.",t2),cex=base2_cex,adj=c(1,0),font=2)
  text(base2_x,base2_y,paste(t2),cex=base2_cex,adj=c(1,0),font=2)
##  text(base2_x,base2_y-3000,g_year,cex=base2_cex,adj=c(1,0),font=2)

  
                                        #legend("center",c("TM","MCD45","intersect"),fill=c("orange","blue","red"))

dev.off()
#system(paste("convert tmp.png -trim -gravity center +repage -bordercolor white -border 10x10 +repage ",ofile,sep=""))
#unlink("tmp.png")


}
# =================================
# end copied from process-pn.R

join_arrays <- function (array_list,row_names) {
  m1=matrix(nrow=length(row_names),ncol=length(array_list[[1]]))
  dimnames(m1)=list(row_names,names(array_list[[1]]))
  for(i in 1:length(array_list)) {
    m1[i,]=array_list[[i]]
  }
  invisible(m1)
}

burn_fraction_ratio <- function(ifile1,ifile2) {
  print(paste("burn_fraction_ratio",ifile1,ifile2))
  r1 <- readGDAL(ifile1,silent=debug_silent)
  r2 <- readGDAL(ifile2,silent=debug_silent)

  # TODO - which formula represents best the ratio of (burned area during period) / ( burned area total )
  # ask Andre and Sam
  
  #mean1 <- mean(r1@data[[1]],na.rm=TRUE)
  #mean2 <- mean(r2@data[[1]],na.rm=TRUE)
  #ratio <- mean1/mean2

  ratio <- mean(r1@data[[1]]/r2@data[[1]],na.rm=TRUE)
  
  #print(paste(mean1,mean2,ratio))
  invisible(ratio)
}

burn_pixel_ratio <- function(ifile1,ifile2) {
  print(paste("burn_pixel_ratio",ifile1,ifile2))
  r1 <- readGDAL(ifile1,silent=debug_silent)
  r2 <- readGDAL(ifile2,silent=debug_silent)
  ratio <- sum(r1@data[[1]],na.rm=TRUE) / sum(r2@data[[1]],na.rm=TRUE)
  invisible(ratio)
}

# this function masks a raster file with given vector cutline and raster mask
# this is needed to overcome a bug in gdalwarp that includes pixels that touch the boundary
mask_file <- function(ifile,ofile,nodata,cutline,mask,res,resample="near",t_srs="-t_srs EPSG:4326") {
  command=paste("gdalwarp -overwrite -dstnodata ",nodata," -cutline ",cutline," -crop_to_cutline -r ",resample," ",t_srs," -tr ",res," ",res," -tap ",ifile," tmp_mask_file.tif",sep="") 
  print(command) ; system(command) 
  command=paste("gdal_calc.py -A tmp_mask_file.tif -B ",mask," --calc A*B --NoDataValue=",nodata," --overwrite --outfile ",ofile,sep="")
  print(command) ; system(command) 
  system("rm -f tmp_mask_file.tif")
}


# this function returns a modified copy of input data, not very efficient, but R does not allow to pass arg. by reference...
classify_burn_dates <- function(data,doy1,doy2) {
  data[data<doy1+1] = 0
  data[data>doy2+1] = 0
  data[data>0] = 1
  #print(data)
  invisible(data)
}


process_scene <- function (scene) {
  prefix <- scene
  burn_tm_shp <- paste(prefix,"_pol.shp",sep="")
  burn_tm_zip <- paste("in/",prefix,"_pol.zip",sep="")
  lyr_shp<- paste(prefix,"_pol",sep="")

  burn_tm_bd_500m  <- paste(prefix,"_tm_bd_500m.tif",sep="")  # burn date at 500m
  burn_tm_bd_30m<- paste(prefix,"_tm_bd_30m.tif",sep="")     
  burn_tm_bp_30m<- paste(prefix,"_tm_bp_30m.tif",sep="")     
  burn_tm_bpa_30m<- paste(prefix,"_tm_bpa_30m.tif",sep="")     
#  burn_tm_tiff12<- paste(prefix,"_tm_bp_30m.tif",sep="")     
  burn_tm_bp_500m<- paste(prefix,"_tm_bp_500m.tif",sep="")    # burn pixel
  burn_tm_bf_5km <- paste(prefix,"_tm_bf_5km.tif",sep="")     # burned fraction
  burn_tm_bf_025d <- paste(prefix,"_tm_bf_025d.tif",sep="")
  burn_tm_bf_05d <- paste(prefix,"_tm_bf_05d.tif",sep="")
  
  burn_mcd45_bd_500m<- paste(prefix,"_mcd45_bd_500m.tif",sep="")
  burn_mcd45_bp_500m <- paste(prefix,"_mcd45_bp_500m.tif",sep="")
  burn_mcd45_bpa_500m <- paste(prefix,"_mcd45_bpa_500m.tif",sep="")
  burn_mcd45_bf_5km <- paste(prefix,"_mcd45_bf_5km.tif",sep="")
  burn_mcd45_bfa_5km <- paste(prefix,"_mcd45_bfa_5km.tif",sep="")
  burn_mcd45_bf_025d <- paste(prefix,"_mcd45_bf_025d.tif",sep="")
  burn_mcd45_bfa_025d <- paste(prefix,"_mcd45_bfa_025d.tif",sep="")
  burn_mcd45_bf_05d <- paste(prefix,"_mcd45_bf_05d.tif",sep="")

  burn_mcd64_bd_500m  <- paste(prefix,"_mcd64_bd_500m.tif",sep="")
  burn_mcd64_bp_500m <- paste(prefix,"_mcd64_bp_500m.tif",sep="")
  burn_mcd64_bpa_500m <- paste(prefix,"_mcd64_bpa_500m.tif",sep="")
  burn_mcd64_bf_5km <- paste(prefix,"_mcd64_bf_5km.tif",sep="")
  burn_mcd64_bfa_5km <- paste(prefix,"_mcd64_bfa_5km.tif",sep="")
  burn_mcd64_bf_025d <- paste(prefix,"_mcd64_bf_025d.tif",sep="")
  burn_mcd64_bfa_025d <- paste(prefix,"_mcd64_bfa_025d.tif",sep="")
  burn_mcd64_bf_05d <- paste(prefix,"_mcd64_bf_05d.tif",sep="")

  burn_gfed4_bf_025d <- paste(prefix,"_gfed4_bf_025d.tif",sep="")
  burn_gfed4_bfa_025d <- paste(prefix,"_gfed4_bfa_025d.tif",sep="")
  burn_gfed3_bf_05d <- paste(prefix,"_gfed3_bf_05d.tif",sep="")
  burn_gfed3_bfa_05d <- paste(prefix,"_gfed3_bfa_05d.tif",sep="")

  res1 <- 30
  res2 <- 462.5
  res3 <- 5000 # 5km
  res05 <- 0.5 # 05deg
  res025 <- 0.25 # 025deg
  res <- res2
  nodata <- 999
  
  cat(paste("\n======================\n",prefix,burn_tm_shp,"\n"))
  if ( ! file.exists(burn_tm_shp) ) {
    cat(paste("file",burn_tm_shp,"non-existent! creating from .zip file\n"))
    if ( ! file.exists(burn_tm_zip) ) {
      cat(paste("\nERROR! file",burn_tm_zip,"non-existent!\n"))
      stop()
    }
    command=paste("unzip ",burn_tm_zip,sep='')
    print(command);  system(command)
  }

  system("rm -f tmp*.tif")

  # get crs
  #tm_crs <- readOGR(burn_tm_shp,lyr_shp)
  tm_crs <- ogrInfo(burn_tm_shp,lyr_shp)$p4s

  #reproject clip map to crs
  map1_shp <- "map_tmp1.shp"
  map2_shp <- "map_tmp2.shp"
  command=paste("ogr2ogr -overwrite -where \"scene='",scene,"'\" -t_srs '",tm_crs,"' ",map1_shp," ",map_shp,sep="")
  print(command);  system(command)
  command=paste("ogr2ogr -overwrite -where \"scene='",scene,"'\" -t_srs 'EPSG:4326' ",map2_shp," ",map_shp,sep="")
  print(command);  system(command)
  g_boundary <<- readOGR(map1_shp,sub(".shp","",map1_shp))
  g_boundary2 <<- readOGR(map2_shp,sub(".shp","",map2_shp))
 
  
  #clip+reproject MCD45

  # 1) warp to target resolution and clip to scene
  if ( ! file.exists(burn_mcd45_bd_500m)  || force_rasterize ) {
    
  #command=paste("gdalwarp -overwrite -tr ",res," ",res," -s_srs '",modis_proj,"' -t_srs '",tm_crs,"' -cutline ",map2_shp," -cwhere \"scene='",scene,"'\" -crop_to_cutline -co COMPRESS=DEFLATE ",mcd45_bd_500m," tmp1.tif",sep="") 
  command=paste("gdalwarp -overwrite -tr ",res," ",res," -s_srs '",modis_proj,"' -t_srs '",tm_crs,"' -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE ",mcd45_tiff," tmp1.tif",sep="") 
  print(command)
  system(command)
  # 2) fill with nodata (999) outside of area of interest
  command=paste("gdalwarp -overwrite -tr ",res," ",res," -srcnodata ",nodata," -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE tmp1.tif ",burn_mcd45_bd_500m,sep="") 
  print(command)
  system(command)
  #file.copy("tmp2.tif",burn_mcd45_bd_500m,overwrite=TRUE)

  burn_mcd45_raster <- raster(burn_mcd45_bd_500m)
  extent <- burn_mcd45_raster@extent
  #dev.new()
  #image(burn_mcd45_raster,main="MCD45")
  }
  
  #clip+reproject MCD64

  # 1) warp to target resolution and clip to scene
  if ( ! file.exists(burn_mcd64_bd_500m)  || force_rasterize ) {

  command=paste("gdalwarp -overwrite -tr ",res," ",res," -s_srs '",modis_proj,"' -t_srs '",tm_crs,"' -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE ",mcd64_tiff," tmp1.tif",sep="") 
  print(command)
  system(command)
  # 2) fill with nodata (999) outside of area of interest
  command=paste("gdalwarp -overwrite -tr ",res," ",res," -srcnodata ",nodata," -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE tmp1.tif ",burn_mcd64_bd_500m,sep="") 
  print(command)
  system(command)
  #file.copy("tmp2.tif",burn_mcd64_bd_500m,overwrite=TRUE)
  burn_mcd64_raster <- raster(burn_mcd64_bd_500m)
  extent <- burn_mcd64_raster@extent
  #dev.new()
  #image(burn_mcd64_raster,main="MCD64")
  }
  
  # rasterize TM shape
  
  if ( ! file.exists(burn_tm_bd_500m) || force_rasterize ) {

  # 1) warp to high resolution and clip to scene, init with 0, order by GRIDCODE DESC so pixel that was mapped in first dates appears on that date
  #command=paste("gdal_rasterize -tr ",res," ",res," -te ",extent@xmin," ",extent@ymin," ",extent@xmax," ",extent@ymax," -a GRIDCODE -init 0 -co COMPRESS=DEFLATE ",burn_tm_shp," ","tmp1.tif",sep="")
#      command=paste("gdal_rasterize -ot Int16 -tr ",res1," ",res1," -te ",extent@xmin," ",extent@ymin," ",extent@xmax," ",extent@ymax," -a GRIDCODE -init 0 -co COMPRESS=DEFLATE ",burn_tm_shp," ","tmp1.tif",sep="")
    command=paste("gdal_rasterize -ot Int16 -tr ",res1," ",res1," -te ",extent@xmin," ",extent@ymin," ",extent@xmax," ",extent@ymax,"  -sql \"select GRIDCODE from '",lyr_shp,"' order by GRIDCODE DESC\" -a GRIDCODE -init 0 -co COMPRESS=DEFLATE ",burn_tm_shp," ","tmp1.tif",sep="")
    print(command)
    system(command)
    
  # 2) warp to target resolution with mode algorithm (so only pixels > 50% burned show up) and fill with nodata (999) outside of area of interest
  #command=paste("gdalwarp -overwrite -dstnodata ",nodata," -cutline ",map2_shp," -cwhere \"scene='",scene,"'\" -crop_to_cutline -co COMPRESS=DEFLATE -r near tmp1.tif tmp2.tif", sep="")
  # average / mode warp algorithms require patch to gdal - see http://trac.osgeo.org/gdal/ticket/5049
    command=paste("gdalwarp -overwrite -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE -r mode  -tr ",res," ",res," -te ",extent@xmin," ",extent@ymin," ",extent@xmax," ",extent@ymax," tmp1.tif tmp2.tif", sep="")
    print(command)
    system(command)

    # 3) clip 30m file
    command=paste("gdalwarp -overwrite -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE -r near tmp1.tif tmp3.tif", sep="")
    print(command)
    system(command)

    # rename resulting files
    file.copy("tmp3.tif",burn_tm_bd_30m,overwrite=TRUE)
    file.copy("tmp2.tif",burn_tm_bd_500m,overwrite=TRUE)

  }

  burn_tm_raster <- raster(burn_tm_bd_500m)
  #dev.new()
  #image(burn_tm_raster,main="TM")

  #make histograms of burn dates
  write_histo2(burn_mcd45_bd_500m,doy[[scene]],doyg[[scene]])
  write_histo2(burn_mcd64_bd_500m,doy[[scene]],doyg[[scene]])

  # should always run this now because of r3_bp_frac
  r2_bp_frac = 0
  r3_bp_frac = 0
  if ( force_rasterize2 ) {
    
  f1 <- burn_tm_bd_500m
  f4 <- burn_tm_bd_30m
  f2 <- burn_mcd45_bd_500m
  f3 <- burn_mcd64_bd_500m
  print(paste("reading",f1,f2,f3,f4))
  r1 <- readGDAL(f1,silent=debug_silent)
  r2 <- readGDAL(f2,silent=debug_silent)
  r3 <- readGDAL(f3,silent=debug_silent)
  r4 <- readGDAL(f4,silent=debug_silent)
#TMP test GFED vs MCD dates
  doy1 <- doy[[scene]][1]
  doy2 <- doy[[scene]][2]
  
  # classify burn dates=1 (value now = 1 or 0)
#  r1@data[[1]][r1@data[[1]]<doy1+1] = 0
#  r1@data[[1]][r1@data[[1]]>doy2+1] = 0
#  r1@data[[1]][r1@data[[1]]>0] = 1
  r1@data[[1]] = classify_burn_dates(r1@data[[1]],doy1,doy2)
  r4@data[[1]] = classify_burn_dates(r4@data[[1]],doy1,doy2)
  r2_all = r2
  r2@data[[1]] = classify_burn_dates(r2@data[[1]],doy1,doy2)
  r2_all@data[[1]] = classify_burn_dates(r2_all@data[[1]],1,365)
  r2_bp_frac = sum(r2@data[[1]],na.rm=TRUE) / sum(r2_all@data[[1]],na.rm=TRUE)
  r3_all = r3
  r3@data[[1]] = classify_burn_dates(r3@data[[1]],doy1,doy2)
  r3_all@data[[1]] = classify_burn_dates(r3_all@data[[1]],1,365)
  r3_bp_frac = sum(r3@data[[1]],na.rm=TRUE) / sum(r3_all@data[[1]],na.rm=TRUE)
  
  # save classified files
  #writeGDAL(r1,burn_tm_bp_500m,drivername = "GTiff",mvFlag=nodata,options=c("COMPRESS=DEFLATE"))
  print(paste("writing",burn_tm_bp_500m))
  writeGDAL(r1,burn_tm_bp_500m,drivername = "GTiff",mvFlag=nodata,options=c("COMPRESS=DEFLATE"))
  print(paste("writing",burn_tm_bp_30m))
  writeGDAL(r4,burn_tm_bp_30m,drivername = "GTiff",mvFlag=nodata,options=c("COMPRESS=DEFLATE"))
  print(paste("writing",burn_mcd45_bp_500m))
  writeGDAL(r2,burn_mcd45_bp_500m,drivername = "GTiff",mvFlag=nodata,options=c("COMPRESS=DEFLATE"))
  print(paste("writing",burn_mcd45_bpa_500m))
  writeGDAL(r2_all,burn_mcd45_bpa_500m,drivername = "GTiff",mvFlag=nodata,options=c("COMPRESS=DEFLATE"))
  print(paste("writing",burn_mcd64_bp_500m))
  writeGDAL(r3,burn_mcd64_bp_500m,drivername = "GTiff",mvFlag=nodata,options=c("COMPRESS=DEFLATE"))
  print(paste("writing",burn_mcd64_bpa_500m))
  writeGDAL(r3_all,burn_mcd64_bpa_500m,drivername = "GTiff",mvFlag=nodata,options=c("COMPRESS=DEFLATE"))

}
  
  # create 5km averages
  #command=paste("gdalwarp -overwrite -dstnodata ",nodata," -co COMPRESS=DEFLATE -r average  -tr ",res3," ",res3," ",burn_tm_bp_500m," ", burn_tm_bf_5km, sep="")
  #config_density="--config GDAL_WARP_AVERAGEMODE_DENSITY 1"
  config_density=""
  command=paste("gdalwarp -overwrite -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE -r average  -tr ",res3," ",res3," ",burn_tm_bp_30m," ", burn_tm_bf_5km, sep="")
  print(command);  system(command)
  command=paste("gdalwarp -overwrite -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE -r average  -tr ",res3," ",res3," ",burn_mcd45_bp_500m," ", burn_mcd45_bf_5km, sep="")
  print(command);  system(command)
  command=paste("gdalwarp -overwrite -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE -r average  -tr ",res3," ",res3," ",burn_mcd45_bpa_500m," ", burn_mcd45_bfa_5km, sep="")
  print(command);  system(command)
  command=paste("gdalwarp -overwrite -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE -r average  -tr ",res3," ",res3," ",burn_mcd64_bp_500m," ", burn_mcd64_bf_5km, sep="")
  print(command);  system(command)
  command=paste("gdalwarp -overwrite -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE -r average  -tr ",res3," ",res3," ",burn_mcd64_bpa_500m," ", burn_mcd64_bfa_5km, sep="")
  print(command);  system(command)

  # prepare 0.25deg and 0.5deg mask files
  tmpfile1=paste("map-",scene,"-005d.tif",sep="")
  tmpfile2=paste("map-",scene,"-025d.tif",sep="")
  mask025d=paste("map-",scene,"-025d-1.tif",sep="")
  tmpfile3=paste("map-",scene,"-05d.tif",sep="")
  mask05d=paste("map-",scene,"-05d-0_9.tif",sep="")
  #mask09=paste("map-",scene,"-025d-0_9.tif",sep="")
  command = paste("gdal_rasterize -tr 0.05 0.05 -burn 1 -a scene -init 0 ",map2_shp," ",tmpfile1,sep="")
  print(command);  system(command)
  command=paste("gdalwarp -tr 0.25 0.25 -tap -r average -overwrite ",tmpfile1," tmp1.tif",sep="")
  print(command);  system(command)
  command=paste("gdalwarp -tr 0.25 0.25 -tap -cutline ",map2_shp," -crop_to_cutline -r near -overwrite tmp1.tif ",tmpfile2,sep="")
  print(command);  system(command)
  unlink("tmp1.tif");
  command=paste("val_repl.py -ot Int16 -in 1 -out 0 -a_nodata 0 -c lt ",tmpfile2," ",mask025d,sep="")
  print(command);  system(command)
  command=paste("gdalwarp -tr 0.5 0.5 -tap -r average -overwrite ",tmpfile1," tmp1.tif",sep="")
  print(command);  system(command)
  command=paste("gdalwarp -tr 0.5 0.5 -tap -cutline ",map2_shp," -crop_to_cutline -r near -overwrite tmp1.tif ",tmpfile3,sep="")
  print(command);  system(command)
  unlink("tmp1.tif");
  command=paste("val_repl.py -ot Int16 -in 0.9 -out 0 -a_nodata 0 -c lt ",tmpfile3," ",mask05d,sep="")
  print(command);  system(command)

  # create 0.25deg averages, to compare with gfed4
  mask_file(burn_tm_bp_30m,burn_tm_bf_025d,nodata,map2_shp,mask025d,res025,"average")
  mask_file(burn_mcd45_bp_500m,burn_mcd45_bf_025d,nodata,map2_shp,mask025d,res025,"average")
  mask_file(burn_mcd64_bp_500m,burn_mcd64_bf_025d,nodata,map2_shp,mask025d,res025,"average")
  mask_file(burn_mcd45_bpa_500m,burn_mcd45_bfa_025d,nodata,map2_shp,mask025d,res025,"average")
  mask_file(burn_mcd64_bpa_500m,burn_mcd64_bfa_025d,nodata,map2_shp,mask025d,res025,"average")

  # create 0.5deg averages, to compare with gfed3?
  # for now only TM is used, but 0.25d values are plotted
  mask_file(burn_tm_bp_30m,burn_tm_bf_05d,nodata,map2_shp,mask05d,res05,"average")
  mask_file(burn_mcd45_bp_500m,burn_mcd45_bf_05d,nodata,map2_shp,mask05d,res05,"average")
  mask_file(burn_mcd64_bp_500m,burn_mcd64_bf_05d,nodata,map2_shp,mask05d,res05,"average")

  # create gfed files
  mons=paste(seq(moy[[scene]][1],moy[[scene]][2],1),collapse=",")
  # was timmean before - error! 2-3x smaller
  command=paste("cdo timsum -selmon,",mons," ",gfed4_nc," ","tmp1.nc",sep="")
  print(command);system(command) 
  command=paste("gdal_translate -of gtiff -a_srs EPSG:4326 tmp1.nc tmp1.tif")
  print(command);system(command)
  mask_file("tmp1.tif",burn_gfed4_bf_025d,nodata,map2_shp,mask025d,res025,t_srs="",)
  system("rm -f tmp*.nc tmp*.tif")

  command=paste("cdo timsum ",gfed4_nc," ","tmp1.nc",sep="")
  print(command);system(command) 
  command=paste("gdal_translate -of gtiff -a_srs EPSG:4326 tmp1.nc tmp1.tif")
  print(command);system(command)
  mask_file("tmp1.tif",burn_gfed4_bfa_025d,nodata,map2_shp,mask025d,res025)
  system("rm -f tmp*.nc tmp*.tif")

  command=paste("cdo timsum -selmon,",mons," ",gfed3_nc," ","tmp1.nc",sep="")
  print(command);system(command) 
  command=paste("gdal_translate -of gtiff -a_srs EPSG:4326 tmp1.nc tmp1.tif")
  print(command);system(command) 
  mask_file("tmp1.tif",burn_gfed3_bf_05d,nodata,map2_shp,mask05d,res05)
  system("rm -f tmp*.nc tmp*.tif")

  command=paste("cdo timsum ",gfed3_nc," ","tmp1.nc",sep="")
  print(command);system(command) 
  command=paste("gdal_translate -of gtiff -a_srs EPSG:4326 tmp1.nc tmp1.tif")
  print(command);system(command) 
  mask_file("tmp1.tif",burn_gfed3_bfa_05d,nodata,map2_shp,mask05d,res05)
  system("rm -f tmp*.nc tmp*.tif")

  # compute burn fraction ratio within burn mapping period
  br_mcd45_500m <- burn_pixel_ratio(burn_mcd45_bp_500m,burn_mcd45_bpa_500m)
  br_mcd64_500m <- burn_pixel_ratio(burn_mcd64_bp_500m,burn_mcd64_bpa_500m)
  br_mcd45_5km <- burn_fraction_ratio(burn_mcd45_bf_5km,burn_mcd45_bfa_5km)
  br_mcd64_5km <- burn_fraction_ratio(burn_mcd64_bf_5km,burn_mcd64_bfa_5km)
  br_mcd45_025d <- burn_fraction_ratio(burn_mcd45_bf_025d,burn_mcd45_bfa_025d)
  br_mcd64_025d <- burn_fraction_ratio(burn_mcd64_bf_025d,burn_mcd64_bfa_025d)
  br_gfed4_025d<- burn_fraction_ratio(burn_gfed4_bf_025d,burn_gfed4_bfa_025d)
  br_gfed3_05d<- burn_fraction_ratio(burn_gfed3_bf_05d,burn_gfed3_bfa_05d)

  # compute stats
  e2=process_rasters(burn_tm_bp_500m,burn_mcd45_bp_500m,scene,"TM","MCD45","MOD",make_img=TRUE)
  e3=process_rasters(burn_tm_bp_500m,burn_mcd64_bp_500m,scene,"TM","MCD64","MOD",make_img=TRUE)
  e2 <- append(e2,br_mcd45_500m)
  e3 <- append(e3,br_mcd64_500m)

  cat(paste("\nstats for scene",scene,"\n"))

  cat("\nconfusion matrix report:\n\n")
  # add r3_bp_frac
  m1 <- join_arrays(list(e2,e3),c("MCD45","MCD64"))
  c1 <- colnames(m1)
  c1[length(c1)] <- "bratio"
  colnames(m1) <- c1
  print(m1)
  write.csv(m1,paste(g_out_dir,scene,"_kappa.csv",sep=""))
  
    # compute spatial averages
  #title_prefix1=paste(scene,"/") # 5km/0.5d
  #title_prefix2=paste(scene,"- TM vs.")
  title_prefix1=""
  title_prefix2=""

  ave_5km_mcd45 <- spatial_average(burn_tm_bf_5km,burn_mcd45_bf_5km,"TM","MCD45","MOD",res2,  paste(title_prefix2,"MCD45"),paste(title_prefix1,"TM"),paste(title_prefix1,"MCD45"),br_mcd45_5km,do_scatterplot=T)
  ave_5km_mcd64 <- spatial_average(burn_tm_bf_5km,burn_mcd64_bf_5km,"TM","MCD64","MOD",res2,  paste(title_prefix2,"MCD64"),paste(title_prefix1,"TM"),paste(title_prefix1,"MCD64"),br_mcd64_5km,do_scatterplot=T)
  ave_025deg_mcd45 <- spatial_average(burn_tm_bf_025d,burn_mcd45_bf_025d,"TM","MCD45","MOD",res025,paste(title_prefix2,"MCD45"),paste(title_prefix1,"TM"),paste(title_prefix1,"MCD45"),br_mcd45_025d,do_scatterplot=F)
  ave_025deg_mcd64 <- spatial_average(burn_tm_bf_025d,burn_mcd64_bf_025d,"TM","MCD64","MOD",res025,paste(title_prefix2,"MCD64"),paste(title_prefix1,"TM"),paste(title_prefix1,"MCD64"),br_mcd64_025d,do_scatterplot=F)
  ave_025deg_gfed4 <- spatial_average(burn_tm_bf_025d,burn_gfed4_bf_025d,"TM","GFED4","GFED",res025,paste(title_prefix2,"GFED4"),paste(title_prefix1,"TM"),paste(title_prefix1,"GFED4"),br_gfed4_025d,do_scatterplot=F)
  ave_05deg_gfed3 <- spatial_average(burn_tm_bf_05d,burn_gfed3_bf_05d,"TM","GFED3","GFED",res05,paste(title_prefix2,"GFED3"),paste(title_prefix1,"TM"),paste(title_prefix1,"GFED3"),br_gfed3_05d,do_scatterplot=F)
#  ave_05deg_2 <- spatial_average(burn_tm_bf_05d,burn_mcd45_bf_05d,"TM","MCD45","MOD",res05,paste(title_prefix2,"MCD45"),paste(title_prefix1,"TM"),paste(title_prefix1,"MCD45"),do_scatterplot=FALSE)
#  ave_05deg_3 <- spatial_average(burn_tm_bf_05d,burn_mcd64_bf_05d,"TM","MCD64","MOD",res05,paste(title_prefix2,"MCD64"),paste(title_prefix1,"TM"),paste(title_prefix1,"MCD64"),do_scatterplot=FALSE) #,scene

  cat("\nspatial averages:\n\n")
  #m4 <- join_arrays(list(ave_5km_2,ave_5km_3,ave_025deg_2,ave_025deg_3,ave_05deg_2,ave_05deg_3),c("MCD45-5km","MCD64-5km","MCD45-0.25d","MCD64-0.25d","MCD45-0.5d","MCD64-0.5d"))
  m4 <- join_arrays(list(ave_5km_mcd45,ave_5km_mcd64,ave_025deg_mcd45,ave_025deg_mcd64,ave_025deg_gfed4,ave_05deg_gfed3),
                    c("MCD45-5km","MCD64-5km","MCD45-0.25d","MCD64-0.25d","GFED4-0.25d","GFED3-0.5d"))
  print(m4)
  write.csv(m4,paste(g_out_dir,scene,"_average.csv",sep=""))
  cat("\n")

  print('montage...')
  setwd(paste('out/',prefix,sep=""))
  command=paste( "montage -geometry +10+10",paste(prefix,"_tm_bp_500m-",prefix,"_mcd45_bp_500m.png",sep=""),paste(prefix,"_tm_bp_500m-",prefix,"_mcd64_bp_500m.png",sep=""),"null:",paste(prefix,"_mcd45_bf_5km.png",sep=""),paste(prefix,"_mcd64_bf_5km.png",sep=""),paste(prefix,"_tm_bf_5km.png",sep=""),paste(prefix,"_montage1.png",sep=""))
  print(command) ;  system(command)

  command=paste( "montage -geometry +10+10 -tile x2 ",paste(prefix,"_mcd45_bf_025d.png",sep=""),paste(prefix,"_mcd64_bf_025d.png",sep=""),paste(prefix,"_gfed4_bf_025d.png",sep=""),paste(prefix,"_tm_bf_025d.png",sep=""),paste(prefix,"_montage2.png",sep=""))
  print(command) ;  system(command)
  setwd('../..')

  invisible(list(m1,m4))
}

#write_histo <- function(tags,values1,values2,values3,locations,filen,mtitle,axis,save_png=TRUE) {
write_histo <- function(tags,values,locations,filen,mtitle,axis,save_png=TRUE,ymin=0,ymax=NA) {

  nloc=length(locations)

  file_png=paste(g_out_dir,filen,".png",sep="")
  file_ps=paste(g_out_dir,filen,".ps",sep="")
  ps_w=8.5
  ps_h=8.5
  png_w=800

  print(paste("function write_histo",file_png))

  tmp_values <- values
  xlabs <- locations
  if (save_png==TRUE)  png(filename=file_png,width=png_w,bg='white')
#  else postscript(file=file_ps)
  else postscript(file=file_ps,paper="special",width=ps_w,height=ps_h,horizontal=F)

  mar <- par("mar")
  mar[2] <- mar[2]+1.5
  mar[4] <- mar[4]-1
  par(mar=mar)

  par(mgp=c(4,1,0))
  
  ylim=get_ylim(tmp_values[,],scale=0.05)
  ylim[1] <- ymin
  if(!is.na(ymax)) ylim[2] = ymax

#  ylim <- NULL

  tTicks <- barplot( main=mtitle,
                    xlab="scenes",ylab="",
                    las=1,font.main=2,font.lab=2,legend.text=tags,args.legend = list(x = "top"),
                    tmp_values,names.arg=xlabs,beside=TRUE,xaxt='n',ylim=ylim,cex.axis=1,cex.lab=1.5,cex.main=2)
  tTicks <- tapply(tTicks, rep(1:length(xlabs), each=length(tags)), mean)
  #axis(1, tTicks, xlabs)
  #text(tTicks, par("usr")[3] - 1.5, labels=xlabs, srt=45, xpd=TRUE,pos=1, offset=2, adj=1)
  text(tTicks, par("usr")[3], labels=xlabs, srt=45, xpd=TRUE,adj=c(1,2))
  mtext(2, text = axis, line=3.5, font=2, cex=1.5)
  box()
  dev.off()
#  suppressWarnings(par(oldpar))

}

# TODO oly plot from 120-300
write_histo2 <- function(ifile,doy,doyg,save_png=T){

  file_png=paste(g_out_dir,sub(".tif",".png",ifile),sep="")
  file_ps=paste(g_out_dir,sub(".tif",".ps",ifile),sep="")
  ps_w=8.5
  ps_h=8.5
  png_w=1600

  print(paste("function write_histo",ifile,file_png))

  r <- readGDAL(ifile,silent=debug_silent)
#  t <- table(r@data[[1]], exclude=NULL, useNA='always')
  d <- r@data[[1]]
  #d[d==0] = NA # remove unburned pixels...
  l <- seq(1,365,1)
  f <- factor(d,levels=l)
  tmp_values<- table(f)
  
  if (save_png==TRUE)  png(filename=file_png,width=png_w,bg='white')
#  else postscript(file=file_ps)
  else postscript(file=file_ps,paper="special",width=ps_w,height=ps_h,horizontal=F)

  plot(tmp_values,xlab="date of burn",ylab="frequency",main=ifile, , xaxs = "i", yaxs = "i",axes=F)#, xaxt='n')
  axis(1,at=seq(10,365,10),labels=T)
  axis(1,at=l,labels=F,tcl=-0.25)
  # display doy/doyg values as blue/red tick marks and vertical dotted lines
  axis(1,at=c(doy[1],doy[2]),labels=F,col.ticks="blue")
  axis(1,at=c(doyg[1],doyg[2]),labels=F,col.ticks="red")
  axis(3,at=c(doy[1],doy[2]),labels=F,col.ticks="blue")
  axis(3,at=c(doyg[1],doyg[2]),labels=F,col.ticks="red")
  abline(v=doy[1],lty=3,col="blue")
  abline(v=doy[2],lty=3,col="blue")
  abline(v=doyg[1],lty=3,col="red")
  abline(v=doyg[2],lty=3,col="red")
  axis(2)

  box()
  
  dev.off()

}

# ==============================================================================
# MAIN 

locations<-c("224_066","224_067","225_065","226_067","226_070","226_071","227_065","232_067")
#locations<-c("224_067")

#julian days vs. month
#1  2  3  4   5   6   7   8   9  10  11  12
#1 32 60 91 121 152 182 213 244 274 305 335

doy <- new.env() # julian DOY of first/last date for MCD data
moy <- new.env() #the first/last month for GFED data
doyg <- new.env() # the DOY corresponding to moy


doy[["224_066"]]<-c(175,271)     #96d   1.0 
moy[["224_066"]]<-c(7,9)         #90d   1.0 182-274
doyg[["224_066"]]<-c(182,274) 

doy[["224_067"]]<-c(207,255)     #48d
moy[["224_067"]]<-c(8,9)         #30d                was c(8,8) 
doyg[["224_067"]]<-c(213,274)

doy[["225_065"]]<-c(166,246)     #80d
moy[["225_065"]]<-c(6,8)         #90d                was c(7,8) 
doyg[["225_065"]]<-c(152,244)

doy[["226_067"]]<-c(205,285)     #80d
moy[["226_067"]]<-c(8,9)         #60d
doyg[["226_067"]]<-c(213,274)

doy[["226_070"]]<-c(173,269)     #96d
moy[["226_070"]]<-c(7,9)         #90d
doyg[["226_070"]]<-c(182,274)

doy[["226_071"]]<-c(205,269)     #64d
moy[["226_071"]]<-c(8,9)         #60d
doyg[["226_071"]]<-c(213,274)

doy[["227_065"]]<-c(164,244)     #80d
moy[["227_065"]]<-c(6,8)         #90d                was c(7,8)
doyg[["227_065"]]<-c(152,244)

doy[["232_067"]]<-c(135,231)     #96d
moy[["232_067"]]<-c(6,8)         #90d
doyg[["232_067"]]<-c(152,244)
#doy[["228_070"]]<-c(155,251)
#moy[["228_070"]]<-c(6,8)

force_rasterize <- F
force_rasterize2 <- T
#make_img_single <- FALSE
#make_img_diff <- TRUE
debug_silent <- TRUE
options(width = 150)

map_shp <<- "in/map_wgs84.shp"
mcd45_tiff <<- "in/MCD45.burndate.cerramaz.2010.sin.tif"
mcd64_tiff <<- "in/MCD64A1.A2010.AMZ-sin.tif"
gfed4_nc <<- "in/gfed4_sam_2010_025d.nc"
gfed3_nc <<- "in/gfed3_2010_BF_sam_05d.nc"


#burn_mcd45_raster1 <- raster(burn_mcd45_tiff)
modis_proj='+proj=sinu +R=6371007.181 +nadgrids=@null +wktext'

g_out_basedir <<- "out"

tags_5km <- c("TM","MCD45","MCD64")
tags2_5km <- c("MCD45","MCD64")
#tags_025d <- c("TM","GFED4","GFED3")
#tags2_025d <- c("GFED4","GFED3")
tags_025d <- c("TM","MCD45","MCD64","GFED4","GFED3")
tags2_025d <- c("MCD45","MCD64","GFED4","GFED3")

histo_ba <- matrix(NA,nrow=3,ncol=length(locations))
dimnames(histo_ba) <- list(tags_5km,locations)
histo_bf <- matrix(NA,nrow=3,ncol=length(locations))
dimnames(histo_bf) <- list(tags_5km,locations)
histo_k <- matrix(NA,nrow=2,ncol=length(locations))
dimnames(histo_k) <- list(tags2_5km,locations)
histo_oa <- matrix(NA,nrow=2,ncol=length(locations))
dimnames(histo_oa) <- list(tags2_5km,locations)
histo_ce <- matrix(NA,nrow=2,ncol=length(locations))
dimnames(histo_ce) <- list(tags2_5km,locations)
histo_oe <- matrix(NA,nrow=2,ncol=length(locations))
dimnames(histo_oe) <- list(tags2_5km,locations)
histo_sp_5km <- matrix(NA,nrow=2,ncol=length(locations))
dimnames(histo_sp_5km) <- list(tags2_5km,locations)

histo_sp_5km <- matrix(NA,nrow=2,ncol=length(locations))
dimnames(histo_sp_5km) <- list(tags2_5km,locations)
histo_sp_025d <- matrix(NA,nrow=4,ncol=length(locations))
dimnames(histo_sp_025d) <- list(tags2_025d,locations)
#histo_sp_05d <- matrix(NA,nrow=2,ncol=length(locations))
#dimnames(histo_sp_05d) <- list(tags2_5km,locations)
histo_bf_025d <- matrix(NA,nrow=5,ncol=length(locations))
dimnames(histo_bf_025d) <- list(tags_025d,locations)


for (i in 1:length(locations)) {
    location<-locations[i]
    g_out_dir <<- paste(g_out_basedir,"/",location,"/",sep="")
    system(paste("mkdir -p",g_out_dir))

    result <- process_scene(location)
    gc(verbose=T)
    
    dimnames(result[[1]])=list(paste(location,"-",dimnames(result[[1]])[[1]]),dimnames(result[[1]])[[2]])
    dimnames(result[[2]])=list(paste(location,"-",dimnames(result[[2]])[[1]]),dimnames(result[[2]])[[2]])

    histo_ba[1,i] <- result[[1]][1,2]
    histo_ba[2,i] <- result[[1]][1,1]
    histo_ba[3,i] <- result[[1]][2,1]
    histo_bf[1,i] <- result[[1]][1,7]
    histo_bf[2,i] <- result[[1]][1,6]
    histo_bf[3,i] <- result[[1]][2,6]

    histo_k[1,i] <- result[[1]][1,14]
    histo_k[2,i] <- result[[1]][2,14]
    histo_oa[1,i] <- result[[1]][1,11]
    histo_oa[2,i] <- result[[1]][2,11]
    histo_ce[1,i] <- result[[1]][1,12]
    histo_ce[2,i] <- result[[1]][2,12]
    histo_oe[1,i] <- result[[1]][1,13]
    histo_oe[2,i] <- result[[1]][2,13]
    
    histo_sp_5km[1,i] <- result[[2]][1,3]
    histo_sp_5km[2,i] <- result[[2]][2,3]
    histo_sp_025d[1,i] <- result[[2]][3,3]
    histo_sp_025d[2,i] <- result[[2]][4,3]
    histo_sp_025d[3,i] <- result[[2]][5,3]
    histo_sp_025d[4,i] <- result[[2]][6,3]
    
    histo_bf_025d[1,i] <- result[[2]][3,1]
    histo_bf_025d[2,i] <- result[[2]][3,2]
    histo_bf_025d[3,i] <- result[[2]][4,2]
    histo_bf_025d[4,i] <- result[[2]][5,2]
    histo_bf_025d[5,i] <- result[[2]][6,2]

    if ( i == 1 ) {
      m1 <- result[[1]]
      m2 <- result[[2]]
    }
    else {
      m1 <- rbind(m1,result[[1]])
      m2 <- rbind(m2,result[[2]])
    }
  }

cat(paste("\n\nfinal report:\n\n"))
    print("m1:")
    print(m1)
    print("m2:")
    print(m2)

print(paste('writing csv to out dir',g_out_basedir))
print(paste(g_out_basedir,"/all_conf_matrix.csv",sep=""))
write.csv(m1,paste(g_out_basedir,"/all_conf_matrix.csv",sep=""))
write.csv(m2,paste(g_out_basedir,"/all_spatial.csv",sep=""))

g_out_dir <<- paste(g_out_basedir,"/histo/",sep="")
system(paste("mkdir -p",g_out_dir))

write_histo(tags_5km,histo_ba,locations,"histo_ba","Burned Area by scene (5km)","Burned Area (km^2)",save_png=T)
write_histo(tags_5km,histo_bf,locations,"histo_bf","Burned Fraction by scene (5km)","Burned Fraction (%)",save_png=T)
write_histo(tags2_5km,histo_k,locations,"histo_k","Kappa score by scene (5km)","Kappa score",save_png=T)
write_histo(tags2_5km,histo_oa,locations,"histo_oa","Overall Accuracy by scene (5km)","Overall Accuracy (%)",save_png=T)
write_histo(tags2_5km,histo_ce,locations,"histo_ce","Commision Error by scene (5km)","Commision Error (%)",save_png=T)
write_histo(tags2_5km,histo_oe,locations,"histo_oe","Ommision Error by scene (5km)","Omision Error (%)",save_png=T)

#TODO
#should MCDxx and GFED be separate in 025deg?
write_histo(tags2_5km,histo_sp_5km,locations,"histo_sp5km","Burned fraction (5km) spatial corr.","Spatial correlation",save_png=T,ymin=0,ymax=1.05)
write_histo(tags2_025d,histo_sp_025d,locations,"histo_sp_025d","Burned fraction (0.25d) spatial corr.","Spatial correlation",save_png=T,ymin=0,ymax=1.05)
write_histo(tags_025d,histo_bf_025d,locations,"histo_bf_025d","Burned Fraction by scene (0.25d)","Burned Fraction (%)",save_png=T)

system("mkdir -p out/bd")
system("cp -f out/???_???/???_???_mcd??_bd_500m.png out/bd")

# ==============================================================================
# shapefile processing...

# for f in ../phase1/*_pol.zip ; do echo $f; unzip $f ; done

# phase0 :

# 1) modify numbers
# lyr=226_071_20100926_pol
# ogrinfo -sql "select count(*) from '${lyr}'" ${lyr}.shp
# ogrinfo -sql "select distinct gridcode from '${lyr}'" ${lyr}.shp
# ogrinfo -sql "select count(*) from '${lyr}' where GRIDCODE=0" ${lyr}.shp

# ogrinfo -dialect SQLite -sql "delete from '${lyr}' where GRIDCODE=0" ${lyr}.shp
# ogrinfo -dialect SQLite -sql "update '${lyr}' set gridcode=205 where GRIDCODE=2" ${lyr}.shp


# 2) merge into one file, and remove all columns except GRIDCODE

# phase1 :
# 1) add GRIDCODE (int 10) to all shapes
# 2 ) ogrinfo -dialect SQLite -sql "update '${lyr}' set gridcode=231" ${lyr}.shp
# 3 ) merge into one layer (save as... from first, then paste features from second), then delete other attributes



### ideas
# - plot MCD45 + MCD64 histogram with doy/moy markers to compare
