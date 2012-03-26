#!/bin/bash

#years=`seq 2000 2010`
years=2010
idir="/data/research/work/modis/mcd45/gtiff"
indexes="Win05 Win06"
#indexes="Win05"
#indexes_hv=""
#indexes_hv="h13v11"
options_gtiff="COMPRESS=LZW" 
nodata=0
product="MCD45monthly"
region="sam"
#vars="burndate ba_qa"
vars="burndate"

for year in $years ; do

    for index in $indexes ; do
	for var in $vars; do
	ofile=$product.$var.$index.$year.tif
#	echo "++++ "$index $ofile $ofile_qa `ls -l $idir/$year/*$index*.tif.gz | wc -l`" files"
	echo "++++ "$index $ofile
#	rm -f $ofile* $ofile_qa*
	ifiles=$idir"/"$year"/"$product".A"$year"*."$index".005."$var"*.tif" 

    process-mcd45a1.py $ofile $ifiles &
#	gdalwarp  -srcnodata $nodata -dstnodata $nodata -overwrite -tr 463.312716527499902 463.312716527499902 -s_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' -t_srs "+proj=utm +zone=23 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs" $ofile MCD45.burndate.$index.$year.utm23s.tif
	done #vars
    done #indexes

    wait 
    ofile_vrt=$product.$var.$region.$year.vrt
    ofile_tif=$product.$var.$region.$year.tif

#    rm -f $ofile_vrt $ofile_tif*
    rm -f $ofile_tif*
#    echo gdalwarp  -co "$options_gtiff" -srcnodata $nodata -dstnodata $nodata -overwrite $product.$var.Win{05,06}.$year.tif  $ofile_tif
    gdalwarp  -co "$options_gtiff" -srcnodata $nodata -dstnodata $nodata -overwrite $product.$var.Win{05,06}.$year.tif  $ofile_tif
#    echo gdalbuildvrt $ofile_vrt $product.$var.Win{05,06}.$year.tif
#    gdalbuildvrt $ofile_vrt $product.$var.Win{05,06}.$year.tif
#    gdalbuildvrt $ofile_vrt $product.$var.Win{05,06}.$year.tif
#	#gdalwarp  -co "$options_gtiff" -srcnodata $nodata -dstnodata $nodata -overwrite $ofile_vrt $ofile_tif
#    gdal_translate -co "$options_gtiff" -a_nodata $nodata $ofile_vrt $ofile_tif
 #   rm -f $ofile_vrt  #$product.$var.Win{05,06}.$year.tif

done
