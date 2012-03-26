#!/bin/bash

#years="2001 2009"
years="2002"

#idir="/data/research/data/modis/mcd12q2"
##indexes_hv="h13v09 h13v10 h13v11 h12v09 h12v10 h12v11"
#indexes_hv="h13v09 h13v10 h13v11 h12v10 h12v11"
#indexes_hv=""
#indexes_hv="h13v11"
options_gtiff="COMPRESS=DEFLATE" 
nodata=255
product="MCD12Q1"
region="cerrado"
vars=( "IGBP" )
ivars=( "MOD12Q1:Land_Cover_Type_1" )
#vars=( "IGBP" "UMD" )
#ivars=( "MOD12Q1:Land_Cover_Type_1" "MOD12Q1:Land_Cover_Type_2" )
#vars=( "IGBP" "UMD" "LAI-fPAR" "NPP-BGC" "PFT" "QC" )
#ivars=( "MOD12Q1:Land_Cover_Type_1" "MOD12Q1:Land_Cover_Type_2" "MOD12Q1:Land_Cover_Type_3" "MOD12Q1:Land_Cover_Type_4" "MOD12Q1:Land_Cover_Type_5" "MOD12Q1:Land_Cover_Type_QC")

#Land Cover Type 1 (IGBP)*	 Class #	 8-bit unsigned	 255	 0–254
#Land Cover Type 2 (UMD)*	 Class #	 8-bit unsigned	 255	 0–254
#Land Cover Type 3 (LAI/fPAR)*	 Class #	 8-bit unsigned	 255	 0–254
#Land Cover Type 4 (NPP/BGC)*	 Class #	 8-bit unsigned	 255	 0–254
#Land Cover Type 5 (PFT)**	 Class #	 8-bit unsigned	 255	 0–254
#Land Cover Type 1 Assessment	 % Integer	 8-bit unsigned	 255	 0–254
#Land Cover Type 2 Assessment	 Not populated	 8-bit unsigned	 255	 0–254
#Land Cover Type 3 Assessment	 Not populated	 8-bit unsigned	 255	 0–254
#Land Cover Type 4 Assessment	 Not populated	 8-bit unsigned	 255	 0–254
#Land Cover Type 5 Assessment	 Not populated	 8-bit unsigned	 255	 0–254
#Land Cover QC	 Concatenated Flags	 8-bit unsigned	 255	 0–254
#Land Cover Type 1 Secondary	 Class #	 8-bit unsigned	 255	 0–254
#Land Cover Type 1 Secondary %	 Not populated	 8-bit unsigned	 255	 0–254
#Land Cover Property 1	 Not populated	 8-bit unsigned	 255	 0–254
#Land Cover Property 2	 Not populated	 8-bit unsigned	 255	 0–254
#Land Cover Property 3	 Not populated	 8-bit unsigned	 255	 0–254

for year in $years ; do
    echo "===================================================="
    echo $year
    rm -f $product.*.h??v??.$year.tif*

#    for var in $vars ; do
    for (( i=0; i<${#vars[@]}; i++ )); do
	var=${vars[$i]}
	ivar=${ivars[$i]}
	ofile=$product.$var.$region.$year.sin.tif
	ofile_wgs=$product.$var.$region.$year.wgs84.tif
#	ofile_utm=$product.$var.$region.$year.utm23s.tif
	echo "++++ "$i $var $ivar $ofile " - "$ofile_utm
#	rm -f $ofile*  $ofile_wgs* $ofile_utm*
	rm -f $ofile*  $ofile_wgs*
	
#	for index_hv in $indexes_hv ; do 

#	ifiles=`ls $product.A${year}001.h??v??.*.hdf`
	    ifiles=`ls $product.A${year}001.${index_hv}.*.hdf`
#	    echo $ifiles
#	    echo ${#vars[@]}
	    for ifile in $ifiles; do
     	        #HDF4_EOS:EOS_GRID:"MCD12Q1.A2009001.h12v10.005.2011059191214.hdf":MOD12Q1:Land_Cover_Type_1
		ifile_hdf="HDF4_EOS:EOS_GRID:\""$ifile"\":"$ivar
		ofile_hv=$product.$var.$index_hv.$year.tif
		echo $ifile $ofile $ifile_hdf 
		#gdalinfo $ifile_hdf
##		rm -f $ofile_hv
##		gdal_translate -co $options_gtiff $ifile_hdf $ofile_hv
	    done #ifiles
#	done #indexes_hv

##	gdal_merge2.py -co "$options_gtiff" -v -o $ofile -n $nodata -a_nodata $nodata $product.$var.h??v??.$year.tif
#	gdalwarp  -co "$options_gtiff" -srcnodata $nodata -dstnodata $nodata -overwrite -tr 463.312716527778 463.312716527778 -s_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' -t_srs "+proj=utm +zone=23 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs" $ofile $ofile_utm
##	gdalwarp  -co "$options_gtiff" -srcnodata $nodata -dstnodata $nodata -overwrite -s_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' -t_srs EPSG:4326 $ofile $ofile_wgs
    done #vars

    #rm -f $product.*.h??v??.$year.tif*
    
done
