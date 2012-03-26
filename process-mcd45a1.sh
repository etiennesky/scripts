#!/bin/bash

#years="2010"
years=`seq 2000 2011`
#years=2011

#idir="/data/research/data/modis/modis-fire/hdf"
idir="../hdf"
idir="/data/research/work/modis/mcd45/hdf"
#indexes_hv="h13v09 h13v10 h13v11 h12v10 h12v11 h11v09 h11v10 h12v09 h11v08 h12v08"
##indexes_hv="h14v09 h14v10 h14v11 h13v09 h13v10 h13v11 h13v12 h13v13 h13v14 h12v08 h12v09 h12v10 h12v11 h12v12 h11v08 h11v09 h11v10"
indexes_hv="h14v09 h14v10 h14v11 h13v09 h13v10 h13v11 h13v12 h13v13 h13v14 h12v08 h12v09 h12v10 h12v11 h12v12 h11v08 h11v09 h11v10"
#indexes_hv="h11v09 h12v09"
#indexes_hv=""
#indexes_hv="h13v11"
options_gtiff="COMPRESS=DEFLATE" 
nodata=0
iproduct="MCD45A1"
product="MCD45"
region="cerramaz"
vars="burndate ba_qa"
#vars="burndate"

for year in $years ; do
    echo "===================================================="
    echo $year
#    rm -f $product.burndate.h??v??.$year.tif*  $product.ba_qa.h??v??.$year.tif* 

    for index_hv in $indexes_hv ; do
#    rm -f $product.burndate.$index_hv.$year.tif*  $product.ba_qa.$index_hv.$year.tif* 
	ofile=$product.burndate.$index_hv.$year.tif
	ofile_qa=$product.ba_qa.$index_hv.$year.tif
#	echo "++++ "$index_hv $ofile $ofile_qa `ls -l $idir/$year/*$index_hv*.hdf | wc -l`" files"
	echo "++++ "$index_hv $ofile $ofile_qa `ls -l $idir/$iproduct.A$year???.$index_hv.*.hdf | wc -l`" files"
	rm -f $ofile* $ofile_qa*
	echo mcd45a1-m2y -o $ofile_qa $ofile $idir/$iproduct.A$year???.$index_hv.*.hdf
	mcd45a1-m2y -o $ofile_qa $ofile $idir/$iproduct.A$year???.$index_hv.*.hdf &
# 	echo mcd45a1-m2y -o $ofile_qa $ofile $idir/*$index_hv*.hdf
# 	mcd45a1-m2y -o $ofile_qa $ofile $idir/*$index_hv*.hdf &
#	gdalwarp  -srcnodata $nodata -dstnodata $nodata -overwrite -tr 463.312716527499902 463.312716527499902 -s_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' -t_srs "+proj=utm +zone=23 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs" $ofile MCD45.burndate.$index_hv.$year.utm23s.tif
    done
echo waiting
wait
echo done
#vars=""
#    for var in $vars ; do
    for var in burndate ; do
	ofile=$product.$var.$region.$year.sin.tif
	ofile_vrt=$product.$var.$region.$year.sin.vrt
	ofile_wgs=$product.$var.$region.$year.wgs84.tif
#	ofile_utm=$product.$var.$region.$year.utm23s.tif
	echo "++++ "$var $ofile " - "$ofile_utm
	rm -f tmp.vrt $ofile*  $ofile_wgs* #$ofile_utm*
#	gdal_merge.py -co "$options_gtiff" -v -o $ofile -n $nodata -n $nodata $product.$var.h??v??.$year.tif
	gdalwarp  -co "$options_gtiff" -srcnodata $nodata -dstnodata $nodata -overwrite $product.$var.h??v??.$year.tif $ofile
#    gdalwarp -srcnodata $nodata -dstnodata $nodata -dstnodata $nodata -overwrite -of vrt $product.$var.h??v??.$year.tif tmp.vrt
#    gdalbuildvrt $ofile_vrt $product.$var.h??v??.$year.tif
##    gdal_translate -co "$options_gtiff" -a_nodata $nodata $ofile_vrt $ofile
#	gdalwarp  -co "$options_gtiff" -srcnodata $nodata -dstnodata $nodata -overwrite -s_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' -t_srs EPSG:4326 $ofile_vrt $ofile_wgs
#    rm -f $ofile_vrt
# 	if [ "$var" == "burndate" ] ; then

##	gdalwarp  -co "$options_gtiff" -srcnodata $nodata -dstnodata $nodata -overwrite -tr 463.312716527778 463.312716527778 -s_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' -t_srs "+proj=utm +zone=23 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs" $ofile $ofile_utm
	gdalwarp  -co "$options_gtiff" -srcnodata $nodata -dstnodata $nodata -overwrite -s_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' -t_srs EPSG:4326 $ofile $ofile_wgs

#	fi
    done #vars

    echo rm -f $product.*.h??v??.$year.tif*
    rm -f $product.*.h??v??.$year.tif*
    
done


wait
echo finished

