#!/bin/bash

#years="2001 2009"
years="2009"

#idir="/data/research/data/modis/mcd12q2"
##indexes_hv="h13v09 h13v10 h13v11 h12v09 h12v10 h12v11"
#indexes_hv="h13v09 h13v10 h13v11 h12v10 h12v11"
#indexes_hv=""
#indexes_hv="h13v11"
options_gtiff="-co COMPRESS=DEFLATE" 
nodata=255
init_dest=0
wgs_res=0.00416666666666667
product="MCD12Q1"
#region="SA"
region="world"
idir="../hdf/world"
#hhs=`seq -w 09 16` 
hhs=`seq -w 00 35` 
#vars=( "IGBP" )
#ivars=( "MOD12Q1:Land_Cover_Type_1" )
#vars=( "IGBP" "UMD" )
#ivars=( "MOD12Q1:Land_Cover_Type_1" "MOD12Q1:Land_Cover_Type_2" )
#vars=( "IGBP" "UMD" "LAI-fPAR" "NPP-BGC" "PFT" "QC" )
#ivars=( "MOD12Q1:Land_Cover_Type_1" "MOD12Q1:Land_Cover_Type_2" "MOD12Q1:Land_Cover_Type_3" "MOD12Q1:Land_Cover_Type_4" "MOD12Q1:Land_Cover_Type_5" "MOD12Q1:Land_Cover_Type_QC")
#vars=( "LAI-fPAR" "NPP-BGC" "PFT" )
#ivars=( "MOD12Q1:Land_Cover_Type_3" "MOD12Q1:Land_Cover_Type_4" "MOD12Q1:Land_Cover_Type_5" )
vars=( "UMD" )
ivars=( "MOD12Q1:Land_Cover_Type_2" )

do_clean=0

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

    for (( i=0; i<${#vars[@]}; i++ )); do
	var=${vars[$i]}
	ivar=${ivars[$i]}
	ofile=$product.$var.$region.$year.msin.tif
	ofile2=$product.$var.$region.$year-2.msin.tif
	ofile_wgs=$product.$var.$region.$year.wgs84.tif
	ofile2_wgs=$product.$var.$region.$year-2.wgs84.tif
	echo "++++ "$i $var $ivar $ofile " - "$ofile_utm
##    rm -f $ofile*  $ofile_wgs*
	
	ifiles=`ls $idir/$product.A${year}001.h??v??.*.hdf.gz`
##	ifiles=""
	for ifile in $ifiles; do

        ifile_base=`basename $ifile .gz`
		ifile_hdf="HDF4_EOS:EOS_GRID:\""$ifile_base"\":"$ivar
        index_hv=${ifile_base:17:6}
		ofile_hv=$product.$var.$index_hv.$year.tif
		#ofile_hv=`basename $ifile_base .hdf`.tif
		#gdalinfo $ifile_hdf
#		    rm -f $ofile_hv
        if [ ! -f $ofile_hv ]; then 
            echo $ifile $ofile $ifile_hdf $ofile_hv
            gunzip -c $ifile>$ifile_base
	        gdal_translate $options_gtiff $ifile_hdf $ofile_hv
            rm -f $ifile_base
        fi
	    done #ifiles
#	done #indexes_hv

#do warp by hh chunks
        for hh in $hhs; do
            echo hh: $hh
            if [ ! -f  $product.$var.h${hh}.$year.tif ]; then 
                gdalwarp -multi $options_gtiff -overwrite $product.$var.h${hh}v??.$year.tif $product.$var.h${hh}.$year.tif
                fi
        done
        
        #combine hh chunks
        if [ ! -f  $ofile ]; then 
            gdalbuildvrt -srcnodata $nodata -vrtnodata $nodata -overwrite tmp.vrt $product.$var.h??.$year.tif
            gdal_translate  $options_gtiff -a_nodata $nodata tmp.vrt $ofile #&
            #echo gdalbuildvrt -overwrite tmp.vrt $product.$var.h??.$year.tif
            #echo gdal_translate $options_gtiff tmp.vrt $ofile2
        fi
        #wait

        if [ ! -f  $ofile_wgs ]; then 
	        gdalwarp -of vrt -overwrite -s_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' -t_srs EPSG:4326 -tr $wgs_res $wgs_res $ofile $ofile_wgs.vrt
            gdal_translate $options_gtiff -a_nodata $nodata $ofile_wgs.vrt $ofile_wgs &
            #gdal_translate $options_gtiff tmp.vrt $ofile2_wgs
        fi

        #rm -f tmp.vrt
        rm *.vrt


    done #vars

        wait

        if [[ "$do_clean" == 1 ]]; then
            rm -f $product.*.h??v??.$year.tif*
            rm -f $product.*.h??.$year.tif*
        fi

done
