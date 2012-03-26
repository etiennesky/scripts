#!/bin/bash

#set -x

source /data/docs/research/bin/functions

years1=( `seq 2000 2010` )
years2=( `seq 2001 2011` )
#years1="2010"
#years2="2011"
days1n="152 182 213 244 274 305 335"
days2n="001 032 060 091 121"
days1b="153 183 214 245 275 306 336"
days2b="001 032 061 092 122"

echo "years1: $years1"
echo "years2: $years2"
echo "days: "$days

#exit

#idir="/data/research/data/modis/modis-fire/hdf"
#idir="/data/research/work/modis/hdf/"
idir="../hdf"
indexes_hv="h13v09 h13v10 h13v11 h12v10 h12v11"
#indexes_hv=""
#indexes_hv="h13v11"
options_gtiff="COMPRESS=DEFLATE" 
nodata=0
product="MCD45"
region="cerrado"
#vars="burndate ba_qa"
vars="ba_qa"

#rm -f MCD45.cerrado* MCD45.pnsc*

rm -f $product.burndate.h??v??.*.tif* $product.ba_qa.h??v??.*.tif*

#for year in $years ; do
for (( i=0; i<${#years1[@]}; i++ )); do
    year1=${years1[$i]}
    year2=${years2[$i]}
    echo "===================================================="
    echo $i"-"$year1"-"$year2
    ls

    days1=$days1n
    days2=$days2n
    if [ "$year1" = "2000" -o "$year1" = "2004" -o "$year1" = "2008" ] ; then days1=$days1b; fi
    if [ "$year2" = "2000" -o "$year2" = "2004" -o "$year2" = "2008" ] ; then days2=$days2b; fi

    for index_hv in $indexes_hv ; do
	ofile=$product.burndate.$index_hv.$year1-$year2.tif
	ofile_qa=$product.ba_qa.$index_hv.$year1-$year2.tif
#	if [ "$year1" = "2010" ]; then
#	    ofile=$product.burndate.$index_hv.jun2010-dec2010.tif
#	    ofile_qa=$product.ba_qa.$index_hv.jun2010-dec2010.tif
#	fi
	#echo "++++ "$index_hv $ofile $ofile_qa `ls -l $idir/$year/*$index_hv*.hdf | wc -l`" files"
	echo "++++ "$index_hv $ofile $ofile_qa
	rm -f $ofile* $ofile_qa*
	ifiles=""

	for day in $days1 ; do 
	    ifile=$idir"/"$year1"/MCD45A1.A"$year1$day"."$index_hv".*.hdf" 
	    if [ -f $ifile ]; then ifiles=$ifiles" "$ifile ; fi
	done
	for day in $days2 ; do 
	    ifile=$idir"/"$year2"/MCD45A1.A"$year2$day"."$index_hv".*.hdf" 
	    if [ -f $ifile ]; then ifiles=$ifiles" "$ifile ; fi
	done
	echo -e $ifiles
	mcd45a1-m2y -V -o $ofile_qa $ofile $ifiles

#	rm -f $ofile.aux.xml $ofile_qa.aux.xml 
    done

    for var in $vars ; do

    ofile=$product.$var.cerrado.$year1-$year2.sin.tif
#    ofile_pnsc=MCD45.pnsc.burndate.jun$year1-may$year2.tif
#    if [ "$year1" = "2010" ]; then
#	ofile=$product.$var.cerrado.jun2010-dec2010.sin.tif
#    fi
#    ofile_utm=$(namename $ofile).utm23s.tif

    ofile_wgs=`echo $ofile |  sed 's/.sin./.wgs84./'`
    ofile_utm=`echo $ofile |  sed 's/.sin./.utm23s./'`

    echo "++++ "$var - $ofile" - "$ofile_utm
    rm -f $ofile* $ofile_utm*

    gdal_merge2.py -co "$options_gtiff" -v -o $ofile -n $nodata -a_nodata $nodata $product.$var.h??v??.*.tif
    gdalwarp  -co $options_gtiff -srcnodata $nodata -dstnodata $nodata -overwrite -tr 463.312716527778 463.312716527778 -s_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' -t_srs "+proj=utm +zone=23 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs" $ofile $ofile_utm
    gdalwarp  -co $options_gtiff -srcnodata $nodata -dstnodata $nodata -overwrite -s_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' -t_srs EPSG:4326 $ofile $ofile_wgs
    
#    clip-pnsc-tm $ofile_utm 

    done #vars

    rm -f $product.burndate.h??v??.*.tif* $product.ba_qa.h??v??.*.tif*

    
done

#rm -f $product.burndate.h??v??.*.tif* $product.ba_qa.h??v??.*.tif*