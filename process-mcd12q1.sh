#!/bin/bash

#set -x
#years="2002"
years="2009"

#idir="/data/research/data/modis/mcd12q2"
##indexes_hv="h13v09 h13v10 h13v11 h12v09 h12v10 h12v11"
#indexes_hv="h13v09 h13v10 h13v11 h12v10 h12v11"
#indexes_hv=""
#indexes_hv="h13v11"
options_gtiff="-co COMPRESS=DEFLATE" 
water_id=0
nodata=255
init_dest=0
product="MCD12Q1"
region="SA"
#idir="../hdf/world"
idir="../../../data/modis/mcd12q1/hdf/"
tiles="h10v08,h11v08,h12v08,h10v09,h11v09,h12v09,h13v09,h14v09,h10v10,h11v10,h12v10,h13v10,h14v10,h11v11,h12v11,h13v11,h14v11,h11v12,h12v12,h13v12,h12v13,h13v13,h13v14,h14v14,h13v08,h09v09,h10v07,h11v07,h09v08,h09v07,h12v07"
#tiles="h10v08,h11v08,h12v08,h10v09,h11v09,h12v09,h13v09,h14v09,h10v10,h11v10,h12v10,h13v10,h14v10,h11v11,h12v11,h13v11,h14v11,h11v12,h12v12,h13v12,h12v13,h13v13,h13v14,h14v14,h13v08,h09v09,h10v07,h11v07,h09v08,h09v07,h12v07,h14v07,h16v14"

wgs_res=0.00416666666666667
wgs_projwin="-projwin -81.5 13 -34.5 -56.0 "
#mosaic_levs="2 4 8 16 32 64 120 128 256"
#mosaic_outsize="-outsize 96 138"
vars=( "IGBP" )
ivars=( "MOD12Q1:Land_Cover_Type_1" )
#vars=( "IGBP" "UMD" )
#ivars=( "MOD12Q1:Land_Cover_Type_1" "MOD12Q1:Land_Cover_Type_2" )
#vars=( "IGBP" "UMD" "LAI-fPAR" "NPP-BGC" "PFT" "QC" )
#ivars=( "MOD12Q1:Land_Cover_Type_1" "MOD12Q1:Land_Cover_Type_2" "MOD12Q1:Land_Cover_Type_3" "MOD12Q1:Land_Cover_Type_4" "MOD12Q1:Land_Cover_Type_5" "MOD12Q1:Land_Cover_Type_QC")
#vars=""
#ivars=""

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
3
for year in $years ; do
    echo "===================================================="
    echo $year
    echo "vars: "${vars[@]} ${#vars[@]}
    #if [[ "$vars" -ne "" ]]; then
    for (( i=0; i<${#vars[@]}; i++ )); do
	var=${vars[$i]}
	ivar=${ivars[$i]}
	ofile=$product.$var.$region.$year.msin.tif
	ofile2=$product.$var.$region.$year.msin2.tif
	ofile_wgs=$product.$var.$region.$year.wgs84.tif
    #file with dominant
	ofile_wgs_mode=$product.$var.$region.$year.wgs84.dominant_05.tif
	ofile_wgs_mosaic=$product.$var.$region.$year.wgs84.mosaic.tif
	ofile_wgs_mosaic2=$product.$var.$region.$year.wgs84.mosaic_05.tif
	echo "++++ "$i $var $ivar $ofile " - "$ofile_utm
##    rm -f $ofile*  $ofile_wgs*
	
#	ifiles=`ls $idir/$product.A${year}001.h??v??.*.hdf.gz`
	ifiles1=`eval echo $product.A${year}001.{${tiles}}.*.hdf.gz`
    echo $ifiles
	for ifile1 in $ifiles1; do

        ifile=`ls $idir/$ifile1`
        ifile_base=`basename $ifile .gz`
		ifile_hdf="HDF4_EOS:EOS_GRID:\""$ifile_base"\":"$ivar
        index_hv=${ifile_base:17:6}
		ofile_hv=$product.$var.$index_hv.$year.tif
		#ofile_hv=`basename $ifile_base .hdf`.tif
		echo $ifile $ofile $ifile_hdf $ofile_hv
#		    rm -f $ofile_hv
        if [ ! -f "$ofile_hv" ]; then 
        if [ -f "$ifile" ]; then 
            gunzip -c $ifile>$ifile_base
	        gdal_translate $options_gtiff $ifile_hdf $ofile_hv
            rm -f $ifile_base
        fi
        fi
	    done #ifiles

        if [ ! -f  $ofile ]; then 
            #echo gdalwarp -multi "$options_gtiff" -srcnodata $nodata -dstnodata $nodata -overwrite $product.$var.h??v??.*.tif $ofile
	        gdalbuildvrt -srcnodata $nodata -vrtnodata $nodata -overwrite tmp.vrt $product.$var.h??v??.$year.tif
            gdal_translate $options_gtiff -a_nodata $nodata tmp.vrt $ofile
            rm -f tmp.vrt
            gdaladdo -ro -clean -r mode --config COMPRESS_OVERVIEW DEFLATE $ofile 2 4 8 16 32 64 128 256 &
        fi
 
       if [ ! -f  $ofile_wgs ]; then 
	        gdalwarp -of vrt -overwrite -s_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' -t_srs EPSG:4326 -tr $wgs_res $wgs_res $ofile tmp.vrt
            gdal_translate $options_gtiff $wgs_projwin tmp.vrt $ofile_wgs
            rm -f tmp.vrt
       fi
        
 ##       makemaplevels2.py $var $ofile_wgs $ofile_wgs_mosaic2

       wait 
        rm -f tmp.vrt

        rm -f $product.$var.h??v??.$year.tif*

    done #vars
    #fi

    #make ibis file from IGBP file
    var=INLAND
    #nodata=254  
    water_id=16
    ofile=MCD12Q1.INLAND.SA.$year.msin.tif
    ofile_wgs=MCD12Q1.INLAND.SA.$year.wgs84.tif
    ofile_nc=MCD12Q1.INLAND.SA.$year.wgs84.nc
	ofile_wgs_mode=MCD12Q1.INLAND.SA.$year.wgs84.dominant_05.tif
	ofile_wgs_mosaic=MCD12Q1.INLAND.SA.$year.wgs84.mosaic.tif
	ofile_wgs_mosaic2=MCD12Q1.INLAND.SA.$year.wgs84.mosaic_05.tif

    echo $ofile $ofile_wgs $ofile_wgs_mosaic2
    #replace values
#    if [ ! -f  $ofile ]; then 
#        val_repl_csv.py -csv_file /data/docs/research/project/data/igbp-inland.csv -in_id IGBP_ID -out_id INLAND_ID  $options_gtiff -a_nodata $nodata  MCD12Q1.IGBP.SA.$year.msin.tif $ofile
#        gdaladdo -ro -clean -r mode --config COMPRESS_OVERVIEW DEFLATE  $ofile 2 4 8 16 32 64 128 256 &
#    fi
    if [ ! -f  $ofile_wgs ]; then 
#        val_repl_csv.py -csv_file /data/docs/research/project/data/csv/igbp-inland.csv -in_id IGBP_ID -out_id INLAND_ID  $options_gtiff -a_nodata $nodata  MCD12Q1.IGBP.SA.$year.wgs84.tif $ofile_wgs
        val_repl_csv.py -csv_file /data/docs/research/project/data/csv/igbp-inland.csv -in_id IGBP_ID -out_id INLAND_ID  $options_gtiff MCD12Q1.IGBP.SA.$year.wgs84.tif $ofile_wgs
        gdaladdo -ro -clean -r mode --config COMPRESS_OVERVIEW DEFLATE  $ofile_wgs 2 4 8 16 32 64 128 256 &
    fi

    #make wgs file and map levels
#    if [ ! -f  $ofile_wgs ]; then 
#        rm -f tmp.vrt
#	    echo gdalwarp -of vrt -overwrite -s_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' -t_srs EPSG:4326 -tr $wgs_res $wgs_res $ofile tmp.vrt
#        echo gdal_translate $options_gtiff $wgs_projwin tmp.vrt $ofile_wgs
#        rm -f tmp.vrt
#    fi

    #gdalwarp -co COMPRESS=DEFLATE MCD12Q1.IGBP.SA.2002.wgs84.tif brazil_ibis_500m_wgs84.tif  sa_ibis_500m.tif
    #makemaplevels2.py INLAND sa_ibis_500m.tif sa_ibis_500m_mosaic2.tif

    #make map levels
    if [ ! -f  $ofile_wgs_mosaic2 ]; then 
        echo makemaplevels2.py $var $ofile_wgs $ofile_wgs_mosaic2
         #makemaplevels2.py $var $ofile_wgs $ofile_wgs_mosaic2
     fi
    wait

    rm -f tmp?.nc
    gdal_translate -co WRITE_BOTTOMUP=FALSE -of netcdf $ofile_wgs tmp1.nc
    nice -n 10 cdo -f nc -b I8 -f nc4 -z zip setname,vegtype tmp1.nc $ofile_nc
    rm -f tmp?.nc
    
done


