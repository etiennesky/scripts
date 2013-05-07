source("/data/docs/research/scripts/myFunctions.R")
library(car)
library(stringr)

# source("/data/docs/research/scripts/process-ba.R")

# f in ???_???_{tm,mcd??}_500m.tif ; do echo $f ; gdal_translate -of aaigrid $f fuzzy/`basename $f .tif`.asc ; done

# ==============================================================================
# functions

spatial_average <- function( ifile1,ifile2,n1,n2,n3,res,title,do_scatterplot=TRUE,save_png=TRUE) {
  print(paste("reading",ifile1,ifile2))
  r1 <- readGDAL(ifile1,silent=debug_silent)
  r2 <- readGDAL(ifile2,silent=debug_silent)

  # report means and correlation
  mean1 <- mean(r1@data[[1]],na.rm=TRUE)
  mean2 <- mean(r2@data[[1]],na.rm=TRUE)
  cor1 <- cor(r1@data[[1]],r2@data[[1]], use="complete.obs",  method = "pearson")
  #cat(paste("\nmean_",n1," : ",mean1," mean_",n2," : ",mean2,"\ntot_",n1,"  : ",mean1*res*res," tot_",n2,"  : ",mean2*res*res," \nspatial correlation: ",cor1,"\n\n"),sep="")

  names=c(paste("mean_",n1,sep=""),paste("mean_",n3,sep=""),paste("tot_",n1,sep=""),paste("tot_",n3,sep=""),"sp. corr.")
  values=c(mean1,mean2,mean1*res*res,mean2*res*res,cor1)
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

  #print("")
  #print(values)
  invisible(values)
}

# =================================
# begin copied from process-pn.R

process_files <- function (ifile1,ifile2,t1,t2,make_img=FALSE) {
print(paste("===== function process_files(",ifile1,ifile2,")"))
#print(ifile1)
#print(ifile2)
#make_imgs(ifile1,ifile2)

tmpi1=str_locate(ifile1,"\\.")
tmpi2=str_locate(ifile2,"\\.")
ofile_prefix=paste(substr(ifile1,1,tmpi1[1]-1),"-",substr(ifile2,1,tmpi2[1]-1),".",sub(".tif","",substring(ifile1,tmpi1[1]+1)),sep="")
#print(ofile_prefix)
##if(make_img==TRUE) make_imgs(ifile1,ifile2,ofile_prefix,t1,t2,save_png=TRUE)
#make_imgs(ifile1,ifile2,ofile_prefix)

if ( file.exists(ifile1) && file.exists(ifile2) )
  e1=myErrReport(ifile2,ifile1)
else e1=NA

invisible(e1)
}

process_rasters <- function (ifile1,ifile2,r1,r2,ta,t1,t2,t3,make_img=FALSE) {
print(paste("===== function process_files(",ifile1,ifile2,")"))
#print(ifile1)
#print(ifile2)
#make_imgs(ifile1,ifile2)

tmpi1=str_locate(ifile1,"\\.")
tmpi2=str_locate(ifile2,"\\.")
ofile_prefix=paste(substr(ifile1,1,tmpi1[1]-1),"-",substr(ifile2,1,tmpi2[1]-1),".",sub(".tif","",substring(ifile1,tmpi1[1]+1)),sep="")
print(ofile_prefix)
if(make_img==TRUE) make_imgs(ifile1,ifile2,ofile_prefix,ta,t1,t2,save_png=TRUE)
#make_imgs(ifile1,ifile2,ofile_prefix)

#if ( file.exists(ifile1) && file.exists(ifile2) )
#  e1=myErrReport(ifile2,ifile1)
#else e1=NA

#cat("\nreport",t1,"vs.",t2,":\n")
e1=myErrReport2(r2,r1,t3,t1)
#print(e1)
invisible(e1)
}

make_imgs <- function (ifile1,ifile2,ofile_prefix,ta,t1,t2,save_png=TRUE) {
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
    raster1=readGDAL(ifile1,silent=debug_silent)
    if ( make_img_single )
      make_img_raster(raster1,ofile1_png,save_png=TRUE,png_w=png_w,png_h=png_h,ta=ta,t1=t1)
  }
  
  if(e_if2) {
    raster2=readGDAL(ifile2,silent=debug_silent)
    if ( make_img_single )
      make_img_raster(raster2,ofile2_png,save_png=TRUE,png_w=png_w,png_h=png_h,ta=ta,t1=t2)
  }
  if(make_img_diff && e_if1 && e_if2) {
    raster3=raster1
    raster3@data=raster1@data*raster2@data
    make_img_raster_diff(raster1,raster2,raster3,ofile_png,ta,t1,t2,save_png=TRUE,png_w=png_w,png_h=png_h)
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
make_img_raster<- function (raster,ofile,col=c("white","black"),save_png=TRUE,png_w=1000,png_h=500,ta="",t1="") {
print(paste("make_img_raster(",ofile))


#print(paste("function make_img(",ifile,ofile,save_png))
print(paste("function make_img_raster(",ofile,save_png,")"))
#raster=readGDAL(ifile)

#png(filename=ofile,width=png_w, height=png_h,bg='white')
if (save_png==TRUE)  png(filename=ofile,width=png_w, height=png_h,bg='white')
else postscript(file=ofile)
par(mai=c(0,0,0,0),lwd=2)

#print("doing plot")
image(raster,col=col)
#print("adding bound.")
plot(g_boundary,add=T)

#print("done plot")

  base2_x=par()$usr[2]-10000
  base2_y=par()$usr[4]-15000
#  base2_cex=3
  base2_cex=6
  text(base2_x,base2_y,paste(t1),cex=base2_cex,adj=c(1,0),font=2)
  ##text(base2_x,base2_y-3000,g_year,cex=base2_cex,adj=c(1,0),font=2)

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

make_img_raster_diff <- function(raster1,raster2,raster3,ofile,ta,t1,t2,save_png=TRUE,png_w=1000,png_h=500) {

  print(paste("function make_img_raster_diff",ofile,save_png,png_w,png_h))

if (save_png==TRUE) png(filename=ofile,width=png_w, height=png_h,bg='white')
else ps(file=ofile)

par(mai=c(0,0,0,0),lwd=2)

image(raster1,col=c("transparent","green"))
image(raster2,col=c("transparent","blue"),add=T)
image(raster3,col=c("transparent","red"),add=T)
plot(g_boundary,add=T)

#legend(par()$usr[1]+3000,par()$usr[3]+12000,c(t1,t2,"intersect  "),fill=c("orange","blue","red"),inset=0.05,cex=1.5)
#SpatialPolygonsRescale(layout.scale.bar(), offset = c(par()$usr[1]+3000,par()$usr[3]+2000),
#                       scale = 10000, fill = c("transparent", "black"), plot.grid = FALSE)
#text(par()$usr[1]+3000,par()$usr[3]+3500,"0",cex=1.5)
#text(par()$usr[1]+13000,par()$usr[3]+3500,"10 km",cex=1.5,adj=c(0.5,0.5))

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
  
legend(base_x,base_y,c(t1,t2,"intersect  "),fill=c("green","blue","red"),inset=0.05,cex=base_cex)
SpatialPolygonsRescale(layout.scale.bar(), offset = c(scale_x,scale_y),
                       scale = scale_scale, fill = c("transparent", "black","transparent", "black"), plot.grid = FALSE)
#SpatialPolygonsRescale(layout.north.arrow(type = 1), offset = c(arrow_x,arrow_y),
#                       scale = arrow_scale, fill = c("transparent", "black","transparent", "black"), plot.grid = FALSE)
text(scale_x,scale_y+scale_text_off,"0",cex=base_cex)
text(scale_x+scale_scale,scale_y+scale_text_off,"100 km",cex=base_cex,adj=c(1,0.5))

#  text(base2_x,base2_y,paste(t1,"-",t2),cex=base2_cex,adj=c(0,0),font=2)
#  text(base2_x,base2_y-3000,g_year,cex=base2_cex,adj=c(0,0),font=2)
#  text(base2_x,base2_y,paste(t1,"-",t2," / ",g_year),cex=base2_cex,adj=c(1,0),font=2)
  text(base2_x,base2_y,paste(ta,"/",t1,"vs.",t2),cex=base2_cex,adj=c(1,0),font=2)
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

process_scene <- function (scene) {
  prefix <- scene
  burn_tm_shp <- paste(prefix,"_pol.shp",sep="")
  lyr_shp<- paste(prefix,"_pol",sep="")

  burn_tm_tiff <- paste(prefix,"_tm_bd_500m.tif",sep="")
  burn_tm_tiff1 <- paste(prefix,"_tm_30m.tif",sep="")
  burn_tm_tiff2 <- paste(prefix,"_tm_500m.tif",sep="")
  burn_tm_tiff3 <- paste(prefix,"_tm_5km.tif",sep="")
  burn_tm_tiff4 <- paste(prefix,"_tm_05deg.tif",sep="")
  
  #burn_mcd45_tiff <- "tmp-mcd45.tif"
  burn_mcd45_tiff <- paste(prefix,"_mcd45_bd_500m.tif",sep="")
  burn_mcd45_tiff2 <- paste(prefix,"_mcd45_500m.tif",sep="")
  burn_mcd45_tiff3 <- paste(prefix,"_mcd45_5km.tif",sep="")
  burn_mcd45_tiff4 <- paste(prefix,"_mcd45_05deg.tif",sep="")

  #burn_mcd64_tiff <- "tmp-mcd64.tif"
  burn_mcd64_tiff <- paste(prefix,"_mcd64_bd_500m.tif",sep="")
  burn_mcd64_tiff2 <- paste(prefix,"_mcd64_500m.tif",sep="")
  burn_mcd64_tiff3 <- paste(prefix,"_mcd64_5km.tif",sep="")
  burn_mcd64_tiff4 <- paste(prefix,"_mcd64_05deg.tif",sep="")

  res1 <- 30
  res2 <- 462.5
  res3 <- 5000 # 5km
  res4 <- 0.5 # 05deg
  res <- res2
  nodata <- 999
  
  cat(paste("\n======================\n",prefix,burn_tm_shp,"\n"))
  if ( ! file.exists(burn_tm_shp) ) {
    cat(paste("\nERROR! file",burn_tm_shp,"non-existent!\n"))
  }

  # get crs
  #tm_crs <- readOGR(burn_tm_shp,lyr_shp)
  tm_crs <- ogrInfo(burn_tm_shp,lyr_shp)$p4s
  print(tm_crs)

  #reproject clip map to crs
  map_shp <- "map_wgs84.shp"
  map2_shp <- "map_tmp.shp"
  command=paste("ogr2ogr -overwrite -where \"scene='",scene,"'\" -t_srs '",tm_crs,"' ",map2_shp," ",map_shp,sep="")
  print(command)
  system(command)
  g_boundary <<- readOGR(map2_shp,sub(".shp","",map2_shp))
 
  
  #clip+reproject MCD45

  # 1) warp to target resolution and clip to scene
  if ( ! file.exists(burn_mcd45_tiff)  || force_rasterize ) {
    
  #command=paste("gdalwarp -overwrite -tr ",res," ",res," -s_srs '",modis_proj,"' -t_srs '",tm_crs,"' -cutline ",map2_shp," -cwhere \"scene='",scene,"'\" -crop_to_cutline -co COMPRESS=DEFLATE ",mcd45_tiff," tmp1.tif",sep="") 
  command=paste("gdalwarp -overwrite -tr ",res," ",res," -s_srs '",modis_proj,"' -t_srs '",tm_crs,"' -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE ",mcd45_tiff," tmp1.tif",sep="") 
  print(command)
  system(command)
  # 2) fill with nodata (999) outside of area of interest
  command=paste("gdalwarp -overwrite -tr ",res," ",res," -srcnodata ",nodata," -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE tmp1.tif tmp2.tif",sep="") 
  print(command)
  system(command)
  file.copy("tmp2.tif",burn_mcd45_tiff,overwrite=TRUE)
  burn_mcd45_raster <- raster(burn_mcd45_tiff)
  extent <- burn_mcd45_raster@extent
  #dev.new()
  #image(burn_mcd45_raster,main="MCD45")
  }
  
  #clip+reproject MCD64

  # 1) warp to target resolution and clip to scene
  if ( ! file.exists(burn_mcd64_tiff)  || force_rasterize ) {

  command=paste("gdalwarp -overwrite -tr ",res," ",res," -s_srs '",modis_proj,"' -t_srs '",tm_crs,"' -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE ",mcd64_tiff," tmp1.tif",sep="") 
  print(command)
  system(command)
  # 2) fill with nodata (999) outside of area of interest
  command=paste("gdalwarp -overwrite -tr ",res," ",res," -srcnodata ",nodata," -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE tmp1.tif tmp2.tif",sep="") 
  print(command)
  system(command)
  file.copy("tmp2.tif",burn_mcd64_tiff,overwrite=TRUE)
  burn_mcd64_raster <- raster(burn_mcd64_tiff)
  extent <- burn_mcd64_raster@extent
  #dev.new()
  #image(burn_mcd64_raster,main="MCD64")
  }
  
  # rasterize TM shape
  
  if ( ! file.exists(burn_tm_tiff) || force_rasterize ) {

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
    file.copy("tmp1.tif",burn_tm_tiff1,overwrite=TRUE)
    file.copy("tmp2.tif",burn_tm_tiff,overwrite=TRUE)

  }

  burn_tm_raster <- raster(burn_tm_tiff)
  #dev.new()
  #image(burn_tm_raster,main="TM")
  
  f1 <- burn_tm_tiff
  f2 <- burn_mcd45_tiff
  f3 <- burn_mcd64_tiff
  print(paste("reading",f1,f2,f3))
  r1 <- readGDAL(f1,silent=debug_silent)
  r2 <- readGDAL(f2,silent=debug_silent)
  r3 <- readGDAL(f3,silent=debug_silent)
  doy1 <- doy[[scene]][1]
  doy2 <- doy[[scene]][2]
  print(paste(doy1,doy2))

  # classify burn dates=1 (value now = 1 or 0)
  #image(r1)
  r1@data[[1]][r1@data[[1]]<doy1+1] = 0
  r1@data[[1]][r1@data[[1]]>doy2+1] = 0
  r1@data[[1]][r1@data[[1]]>0] = 1
  r2@data[[1]][r2@data[[1]]<doy1+1] = 0
  r2@data[[1]][r2@data[[1]]>doy2+1] = 0
  r2@data[[1]][r2@data[[1]]>0] = 1
  r3@data[[1]][r3@data[[1]]<doy1+1] = 0
  r3@data[[1]][r3@data[[1]]>doy2+1] = 0
  r3@data[[1]][r3@data[[1]]>0] = 1
#  d1[d2>doy2] = 0
#  d1[d2>0] = 1
  #dev.new()
  #image(r1)

  # save classified files
  #writeGDAL(r1,burn_tm_tiff2,drivername = "GTiff",mvFlag=nodata,options=c("COMPRESS=DEFLATE"))
  print(paste("writing",burn_tm_tiff2))
  writeGDAL(r1,burn_tm_tiff2,drivername = "GTiff",mvFlag=nodata,options=c("COMPRESS=DEFLATE"))
  print(paste("writing",burn_mcd45_tiff2))
  writeGDAL(r2,burn_mcd45_tiff2,drivername = "GTiff",mvFlag=nodata,options=c("COMPRESS=DEFLATE"))
  print(paste("writing",burn_mcd64_tiff2))
  writeGDAL(r3,burn_mcd64_tiff2,drivername = "GTiff",mvFlag=nodata,options=c("COMPRESS=DEFLATE"))
  
  # create 5km averages
  #command=paste("gdalwarp -overwrite -dstnodata ",nodata," -co COMPRESS=DEFLATE -r average  -tr ",res3," ",res3," ",burn_tm_tiff2," ", burn_tm_tiff3, sep="")
  command=paste("gdalwarp -overwrite -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE -r average  -tr ",res3," ",res3," ",burn_tm_tiff2," ", burn_tm_tiff3, sep="")
  print(command)
  system(command)
  command=paste("gdalwarp -overwrite -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE -r average  -tr ",res3," ",res3," ",burn_mcd45_tiff2," ", burn_mcd45_tiff3, sep="")
  print(command)
  system(command)
  command=paste("gdalwarp -overwrite -dstnodata ",nodata," -cutline ",map2_shp," -crop_to_cutline -co COMPRESS=DEFLATE -r average  -tr ",res3," ",res3," ",burn_mcd64_tiff2," ", burn_mcd64_tiff3, sep="")
  print(command)
  system(command)

  # create 0.5deg averages, to compare with gfed
  command=paste("gdalwarp -overwrite --config GDAL_WARP_AVERAGEMODE_DENSITY 0.75 -dstnodata ",nodata," -r average  -t_srs EPSG:4326 -tr ",res4," ",res4," -tap ",burn_tm_tiff2," ", burn_tm_tiff4, sep="")
  print(command)
  system(command)
  command=paste("gdalwarp -overwrite --config GDAL_WARP_AVERAGEMODE_DENSITY 0.75 -dstnodata ",nodata," -r average  -t_srs EPSG:4326 -tr ",res4," ",res4," -tap ",burn_mcd45_tiff2," ", burn_mcd45_tiff4, sep="")
  print(command)
  system(command)
  command=paste("gdalwarp -overwrite --config GDAL_WARP_AVERAGEMODE_DENSITY 0.75 -dstnodata ",nodata," -r average  -t_srs EPSG:4326 -tr ",res4," ",res4," -tap ",burn_mcd64_tiff2," ", burn_mcd64_tiff4, sep="")
  print(command)
  system(command)

  # compute stats
  #cm <- myConfMatrix(r1@data[,1],r2@data[,1])
  #print(r2@data[[1]])
  #print(r1@data[[1]])
  
  #e2=myErrReport2(r1,r2,"   TM","MCD45")
  #cat("\nreport TM vs. MCD45:\n")
  #print(e2)
  #e3=myErrReport2(r1,r3,"   TM","MCD64")
  #cat("\nreport TM vs. MCD64:\n")
  #print(e3)
  e2=process_rasters(burn_tm_tiff2,burn_mcd45_tiff2,r1,r2,scene,"TM","MCD45","MOD",make_img=TRUE)
  e3=process_rasters(burn_tm_tiff2,burn_mcd64_tiff2,r1,r3,scene,"TM","MCD64","MOD",make_img=TRUE)

  # compute spatial averages
  ave_5km_2 <- spatial_average(burn_tm_tiff3,burn_mcd45_tiff3,"TM","MCD45","MOD",res,do_scatterplot=TRUE,paste(scene,"- TM vs. MCD45"))
  ave_5km_3 <- spatial_average(burn_tm_tiff3,burn_mcd64_tiff3,"TM","MCD64","MOD",res,do_scatterplot=TRUE,paste(scene,"- TM vs. MCD64"))
  ave_05deg_2 <- spatial_average(burn_tm_tiff4,burn_mcd45_tiff4,"TM","MCD45","MOD",res,do_scatterplot=FALSE,paste(scene,"- TM vs. MCD45"))
  ave_05deg_3 <- spatial_average(burn_tm_tiff4,burn_mcd64_tiff4,"TM","MCD64","MOD",res,do_scatterplot=FALSE,paste(scene,"- TM vs. MCD64"))

  cat(paste("\nstats for scene",scene,"\n"))

  cat("\nkappa report:\n\n")
  #print(e2)
  #print(e3)
  m1 <- join_arrays(list(e2,e3),c("MCD45","MCD64"))
  print(m1)
  write.csv(m1,paste("out/",scene,"_kappa.csv",sep=""))
  
  #cat("\n5km spatial averages:\n\n")
  #print(ave_5km_2)
  #print(ave_5km_3)
  #m2 <- join_arrays(list(ave_5km_2,ave_5km_3),c("MCD45","MCD64"))
  #print(m2)
  #cat("\n0.5deg spatial averages:\n\n")
  #print(ave_05deg_2)
  #print(ave_05deg_3)
  #m3 <- join_arrays(list(ave_05deg_2,ave_05deg_3),c("MCD45","MCD64"))
  #print(m3)
  #cat("\n")

  cat("\nspatial averages:\n\n")
  m4 <- join_arrays(list(ave_5km_2,ave_5km_3,ave_05deg_2,ave_05deg_3),c("MCD45-5km","MCD64-5km","MCD45-0.5d","MCD64-0.5d"))
  print(m4)
  write.csv(m4,paste("out/",scene,"_average.csv",sep=""))
  cat("\n")

  invisible(list(m1,m4))
}


# ==============================================================================
# MAIN 

locations<-c("224_067","226_070","226_071","227_065","232_067","224_066","225_065","226_067")
#locations<-c("226_070")
#dates <- new.env()
#dates[["224_067"]]<-c("20100726","20100912")
#dates[["226_070"]]<-c("20100724","20100910")
#dates[["226_070"]]<-c("20100724")

#this could be read from a csv file...
doy <- new.env()
doy[["224_067"]]<-c(207,255)
doy[["226_070"]]<-c(173,269)
doy[["226_071"]]<-c(205,269)
doy[["227_065"]]<-c(164,244)
doy[["232_067"]]<-c(135,231)
doy[["224_066"]]<-c(175,271)
doy[["225_065"]]<-c(166,246)
doy[["226_067"]]<-c(205,285)
doy[["228_070"]]<-c(155,251)

force_rasterize <- FALSE
#force_rasterize <- TRUE
make_img_single <- FALSE
make_img_diff <- TRUE
debug_silent <- TRUE
options(width = 150)

#print("1")
#map_shp <- readOGR("map.shp","map")
#print("2")
#print(map_shp)

#burn_mcd45_tiff <- "MCD45.burndate.cerramaz.2010.wgs84.tif"
mcd45_tiff <- "MCD45.burndate.cerramaz.2010.sin.tif"
mcd64_tiff <- "MCD64A1.A2010.AMZ-sin.tif"

#burn_mcd45_raster1 <- raster(burn_mcd45_tiff)
modis_proj='+proj=sinu +R=6371007.181 +nadgrids=@null +wktext'

g_out_dir <<- "out/"

for (i in 1:length(locations)) {
    location<-locations[i]
    result <- process_scene(location)
    dimnames(result[[1]])=list(paste(location,"-",dimnames(result[[1]])[[1]]),dimnames(result[[1]])[[2]])
    dimnames(result[[2]])=list(paste(location,"-",dimnames(result[[2]])[[1]]),dimnames(result[[2]])[[2]])
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

  write.csv(m1,paste("out/all_kappa.csv",sep=""))
  write.csv(m2,paste("out/all_spatial.csv",sep=""))


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


# ==============================================================================
# old code...

  #clip+reproject MCD45

  #mcd45_crs <- burn_mcd45_raster1@crs
  #print(mcd45_crs)
  #clip_mcd45_shp<-spTransform(map_shp,mcd45_crs)
  #r2 <- crop( burn_mcd45_raster1,clip_mcd45_shp)
  #image(r2)
  #r3 <- projectRaster(r2,res=c(500,500),crs=tm_crs)
  #image(r3)
  #gdalwarp -overwrite -tr 30 30  -t_srs '+proj=utm +zone=21 +south +datum=WGS84 +units=m +no_defs ' -cutline  map-21S.shp -cwhere "scene='226_070'" -crop_to_cutline MCD45.burndate.cerramaz.2010.wgs84.tif tmp1.tif

  # read raster
  #r <- raster(burn_tm_tiff)
  #print(r)
  #print(str(r))
  #print(r@extent)
  #tm_crs <- r@crs
  #print(crs)
  #image(r)

  # get clip polygon
  #clip_tm_shp<-spTransform(map_shp,tm_crs)
  #print(map2_shp)
  #d <- map2_shp@data
  #i <- d[ d$scene == scene, ]$id # TODO error checking
  #print(i)
  #p <- map2_shp@polygons[[i]]@Polygons[[1]]
  #print(p)
  #print(p@coords)

  # crop raster
  #burn_tm_raster <- crop(r,clip_tm_shp)
  #image(r)




process_file1 <- function (scene,date) {
  prefix <- paste(scene,"_",date,sep="")
  file_shp <- paste(prefix,"_pol.shp",sep="")
  lyr_shp<- paste(prefix,"_pol",sep="")
  file_raster <- paste(prefix,"_rgb.tif",sep="")
  print(paste(prefix,file_shp))
  if ( ! file.exists(file_shp) ) {
    print(paste("ERROR! file",file_shp,"none-existent"))
  }

  # read raster
  r <- raster(file_raster)
  #print(str(r))
  print(r@extent)
  crs <- r@crs
  print(crs)
  #image(r)

  # get clip polygon
  map2_shp<-spTransform(map_shp,crs)
  print(map2_shp)
  d <- map2_shp@data
  i <- d[ d$scene == scene, ]$id # TODO error checking
  print(i)
  p <- map2_shp@polygons[[i]]@Polygons[[1]]
  #print(p)
  print(p@coords)

#  # crop raster
#  r1<-crop(r,map2_shp)
#  #image(r)
#  #image(r1)
#  burn_shp<- readOGR(file_shp,lyr_shp)

#  burn_raster <- rasterize(burn_shp,r1)
#  image(burn_raster)

}

process_scene1 <- function (location) {
#  print(paste(location,date))
  
    d <- dates[[location]]
    print(location)
    for (j in 1:length(d)) {
      date<-d[j]
      #print(date)
      process_file(location,date)
    }   
    
}
