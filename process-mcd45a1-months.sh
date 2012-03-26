#!/bin/bash

#years="2001 2009"
years="2001"
#years=`seq 2000 2010`
declare -a daysn=( 001 032 060 091 121 152 182 213 244 274 305 335 )
declare -a daysb=( 001 032 061 092 122 153 183 214 245 275 306 336 )
declare -a months=( 01 02 03 04 05 06 07 08 09 10 11 12 )
nmonths=12

#idir="/data/research/data/modis/mcd12q2"
odir=`pwd`
idir=/data/research/work/mcd45/hdf/
#indexes_hv="h13v09 h13v10 h13v11 h12v09 h12v10 h12v11"
indexes_hv="h13v09 h13v10 h13v11 h12v10 h12v11"
#indexes_hv=""
#indexes_hv="h13v11 h13v10"
options_gtiff="COMPRESS=DEFLATE" 
nodata=0
product="MCD45A1"
region="cerrado"
vars=( "burndate" "ba_qa" )
ivars=( "burndate" "ba_qa" )
#vars=( "burndate" )
#ivars=( "burndate" )
ivarp="MOD_GRID_Monthly_500km_BA"

for year in $years ; do
    echo "===================================================="
    declare -a days=( "${daysn[@]}" )
    if [ "$year" = "2000" -o "$year" = "2004" -o "$year" = "2008" ] ; then declare -a days=( "${daysb[@]}" ); fi
    echo $year - $days
    rm -f $odir/$product.*.h??v??.$year-??.*.tif*
    cd $idir/$year
    
#    for var in $vars ; do
    for (( i=0; i<${#vars[@]}; i++ )); do
	var=${vars[$i]}
	ivar=${ivars[$i]}
	echo "++++ "$i $var $ivar $ofile " - "$ofile_utm
	rm -f $odir/$product.$var.h??v??.$year.??.tif*

	for (( j=0; j<$nmonths; j++ )); do
	    day=${days[$j]}
	    month=${months[$j]}

	    for index_hv in $indexes_hv ; do 

		ifile=`ls $product.A${year}${day}.${index_hv}.*.hdf`
		if [ $ifile ] ; then
		ifile_hdf="HDF4_EOS:EOS_GRID:\""$ifile"\":"$ivarp":"$ivar
		ofile_hv=$product.$var.$index_hv.$year-$month.tif
		echo $j $day $month $ifile $ofile_hv $ifile_hdf 
		#gdalinfo $ifile_hdf
		#rm -f $ofile_hv
		gdal_translate -co $options_gtiff $ifile_hdf $odir/$ofile_hv
		fi
	    done #indexes_hv

	    ifiles=`ls $odir/$product.$var.h??v??.$year-$month.tif`
	    if [ "$ifiles" != "" ] ; then
		echo == $ifiles
		ofile=$product.$var.$region.$year-$month.msin.tif
		ofile_wgs=$product.$var.$region.$year-$month.wgs84.tif
		echo gdal_merge2.py -co "$options_gtiff" -v -n $nodata -a_nodata $nodata -o $odir/$ofile $ifiles
		gdal_merge2.py -co "$options_gtiff" -v -n $nodata -a_nodata $nodata -o $odir/$ofile $ifiles
#		gdalwarp  -co "$options_gtiff" -srcnodata $nodata -dstnodata $nodata -overwrite -s_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' -t_srs EPSG:4326 $odir/$ofile $odir/$ofile_wgs
		rm -f $odir/$product.$var.h??v??.$year-$month.tif*
	    fi

	done #months

    done #vars

    
    
done
