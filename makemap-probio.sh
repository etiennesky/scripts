#!/bin/bash

# this script is to rasterize probio shapefiles and make a mosaic
# see 

set -x

function do_make {
    if [[ "$do_replace" == "1" ]]; then
        do_replace
    fi
    if [[ "$do_reproject" == "1" ]]; then
        do_reproject
    fi
    if [[ "$do_rasterize" == "1" ]]; then
        do_rasterize
    fi
    if [[ "$do_rasterize2" == "1" ]]; then
        do_rasterize2
    fi
    if [[ "$do_mosaic" == "1" ]]; then
        do_mosaic
    fi
}

function do_replace {
    echo "do_replace" ${#area[*]}  ${#res1[*]}   ${#name1[*]}
    for (( i_area = 0 ; i_area < ${#area[*]} ; i_area++ )) ; do      
        echo "=== area: " ${area[$i_area]}
        ogr-replace-values2.py  ${area[$i_area]}.shp ${csv_file}
    done
}        

function do_reproject {
    echo "do_reproject" ${#area[*]}  ${#res1[*]}   ${#name1[*]}
    for (( i_area = 0 ; i_area < ${#area[*]} ; i_area++ )) ; do
        echo "=== area: " ${area[$i_area]}
        rm -f ${area[$i_area]}${proj}.*
        echo ogr2ogr $proj_s_srs $proj_t_srs ${area[$i_area]}${proj}.shp ${area[$i_area]}.shp ${area[$i_area]}
        ogr2ogr $proj_s_srs $proj_t_srs ${area[$i_area]}${proj}.shp ${area[$i_area]}.shp ${area[$i_area]}
        
    done
}        

function do_rasterize {
    echo "do_rasterize" ${#area[*]}  ${#res1[*]}   ${#name1[*]}
    for (( i_area = 0 ; i_area < ${#area[*]} ; i_area++ )) ; do
        echo "=== area: " ${area[$i_area]}
        echo $name1
        echo $res1
        for (( i_name = 0 ; i_name < ${#name1[*]} ; i_name++ )) ; do
            
            #ofile=${area[$i_area]}_${name2[$i_name]}_${res0}.tif
            #echo nice gdal_rasterize -a_nodata $nodata -init $nodata -tr $res0 $res0 -tap -co compress=DEFLATE -a ${name1[$i_name]} -l ${area[$i_area]} ${area[$i_area]}.shp $ofile 
            #nice gdal_rasterize -a_nodata $nodata -init $nodata -tr $res0 $res0 -tap -co compress=DEFLATE -a ${name1[$i_name]} -l ${area[$i_area]} ${area[$i_area]}.shp $ofile &
                
            for (( i_res = 0 ; i_res < ${#res1[*]} ; i_res++ )) ; do
#        echo $i_res -  ${#res1[*]}  ${#area[*]}  ${#name1[*]}
#            echo res: $i_res name: $i_name area: $i_area
                    ofile=${area[$i_area]}_${name2[$i_name]}_${res2[$i_res]}${proj}.tif
                    rm -f $ofile* #tmp-$ofile
#                    echo gdal_rasterize -ot Byte -a_nodata $nodata -init $nodata -tr ${res1[$i_res]} ${res1[$i_res]} -tap -a ${name1[$i_name]} -l ${area[$i_area]}${proj} ${area[$i_area]}${proj}.shp $ofile
#                    time nice gdal_rasterize -ot Byte -a_nodata $nodata -init $nodata -tr ${res1[$i_res]} ${res1[$i_res]} -tap -a ${name1[$i_name]} -l ${area[$i_area]}${proj} ${area[$i_area]}${proj}.shp tmp-$ofile 
                    echo time nice gdal_rasterize ${co_opt[$i_res]} -ot Byte -a_nodata $nodata -init $nodata -tr ${res1[$i_res]} ${res1[$i_res]} -te $extent -a ${name1[$i_name]} -l ${area[$i_area]}${proj} ${area[$i_area]}${proj}.shp $ofile
                    time nice gdal_rasterize ${co_opt[$i_res]} -ot Byte -a_nodata $nodata -init $nodata -tr ${res1[$i_res]} ${res1[$i_res]} -te $extent -a ${name1[$i_name]} -l ${area[$i_area]}${proj} ${area[$i_area]}${proj}.shp $ofile
#                    nice gdal_translate ${co_opt[$i_res]} tmp-$ofile $ofile
#                    rm tmp-$ofile
#            gdal_rasterize -a_nodata 0 -init 0 -tr ${res1[$i_res]} ${res1[$i_res]} ${co_opt[$i_res]} -a ${name1[$i_name]} -l ${area[$i_area]} ${area[$i_area]}.shp $ofile 
            done
            
        done
        echo "done ==" 
    done
        wait
}
    
function do_rasterize2 {
    echo "do_rasterize2" ${#area[*]}  ${#res1[*]}   ${#name1[*]}
    for (( i_area = 0 ; i_area < ${#area[*]} ; i_area++ )) ; do
        echo "=== area: " ${area[$i_area]}
        echo $name1
        echo $res1
        for (( i_name = 0 ; i_name < ${#name1[*]} ; i_name++ )) ; do
            
            #ofile=${area[$i_area]}_${name2[$i_name]}_${res0}.tif
            #echo nice gdal_rasterize -a_nodata $nodata -init $nodata -tr $res0 $res0 -tap -co compress=DEFLATE -a ${name1[$i_name]} -l ${area[$i_area]} ${area[$i_area]}.shp $ofile 
            #nice gdal_rasterize -a_nodata $nodata -init $nodata -tr $res0 $res0 -tap -co compress=DEFLATE -a ${name1[$i_name]} -l ${area[$i_area]} ${area[$i_area]}.shp $ofile &
                
            if (( ${#res2[*]} > 1 )); then
                rm -f ${area[$i_area]}_${name2[$i_name]}_${res2[$i_res]}${proj}.tif.*
                gdaladdo -ro -clean -r mode --config COMPRESS_OVERVIEW DEFLATE ${area[$i_area]}_${name2[$i_name]}_${res2[$i_res]}${proj}.tif $addo_levs
                rm -f ${area[$i_area]}_${name2[$i_name]}_${res2[1]}${proj}.tif* 
                gdal_translate ${co_opt[1]} -outsize ${outsize[0]} ${area[$i_area]}_${name2[$i_name]}_${res2[0]}${proj}.tif ${area[$i_area]}_${name2[$i_name]}_${res2[1]}${proj}.tif 
            fi
            if (( ${#res2[*]} > 2 )); then
                rm -f ${area[$i_area]}_${name2[$i_name]}_${res2[2]}${proj}.tif* 
                gdal_translate ${co_opt[1]}  -outsize ${outsize[1]} ${area[$i_area]}_${name2[$i_name]}_${res2[0]}${proj}.tif ${area[$i_area]}_${name2[$i_name]}_${res2[2]}${proj}.tif 
            fi
        done
        echo "done ==" 
        wait
    done
}
    
#what does this do again?
function do_mosaic1 {
    echo "do_mosaic" ${#area[*]}  ${#res1[*]}   ${#name1[*]}
    for (( i_area = 0 ; i_area < ${#area[*]} ; i_area++ )) ; do
        echo "=== area: " ${area[$i_area]}
        for (( i_name = 0 ; i_name < ${#name1[*]} ; i_name++ )) ; do
            for (( i_res = 0 ; i_res < ${#res1[*]} ; i_res++ )) ; do
                mfile=${mprefix}_${name2[$i_name]}_${res2[$i_res]}${proj}.tif
                vrtfile=${mprefix}_${name2[$i_name]}_${res2[$i_res]}${proj}.vrt
                echo "making mosaic for name "${name2[$i_name]}" res "${res2[$i_res]}" - "$mfile
                rm -f $mfile $vrtfile
#                echo gdalwarp -co compress=DEFLATE -dstnodata $nodata *_${name2[$i_name]}_${res2[$i_res]}${proj}.tif $mfile
#                gdalwarp -co compress=DEFLATE -dstnodata $nodata *_${name2[$i_name]}_${res2[$i_res]}${proj}.tif $mfile 
                gdalbuildvrt $vrtfile *_${name2[$i_name]}_${res2[$i_res]}${proj}.tifclip*_${name2[0]}_${res2[0]}${proj}.tif
    gdal_translate -co compress=DEFLATE -ot Byte tmp1.vrt ${area[0]}_${name2[0]}_${res2[0]}${proj}.tif
    rm -f tmp1.vrt
           done
        done
        wait
    done
}

function do_mosaic {
    echo "do_mosaic" ${#area[*]}  ${#res1[*]}   ${#name1[*]}
#    for (( i_area = 0 ; i_area < ${#area[*]} ; i_area++ )) ; do
#        echo "=== area: " ${area[$i_area]}
        for (( i_name = 0 ; i_name < ${#name1[*]} ; i_name++ )) ; do
            for (( i_res = 0 ; i_res < ${#res1[*]} ; i_res++ )) ; do
                mfile=${mprefix}_${name2[$i_name]}_${res2[$i_res]}${proj}.tif
                vrtfile=${mprefix}_${name2[$i_name]}_${res2[$i_res]}${proj}.vrt
                ifiles=""
                for (( i_area = 0 ; i_area < ${#area[*]} ; i_area++ )) ; do
                    ifiles=$ifiles" "${area[$i_area]}_${name2[$i_name]}_${res2[$i_res]}${proj}.tif
                done
                echo "making mosaic for name "${name2[$i_name]}" res "${res2[$i_res]}" - "$mfile" from "$ifiles
                rm -f $mfile $vrtfile
#                echo gdalwarp -co compress=DEFLATE -dstnodata $nodata *_${name2[$i_name]}_${res2[$i_res]}${proj}.tif $mfile
#                gdalwarp -co compress=DEFLATE -dstnodata $nodata *_${name2[$i_name]}_${res2[$i_res]}${proj}.tif $mfile 
                gdalbuildvrt $vrtfile $ifiles
                gdal_translate -co compress=DEFLATE -ot Byte $vrtfile $mfile
                rm -f $vrtfile
           done
        done
        wait
#    done
}


#replace values
##ogr-replace-values.py amazonia.shp probio_vegtypes_detail.csv 
##ogr-replace-values.py cerrado.shp probio_vegtypes_detail.csv 

#reproject to wgs84 and sinusoidal
#ogr2ogr -s_srs EPSG:4618 -t_srs EPSG:4326 cerrado_wgs84.shp cerrado.shp cerrado
#ogr2ogr -s_srs EPSG:4618 -t_srs  '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' cerrado_msin.shp cerrado.shp cerrado
#ogr2ogr -s_srs EPSG:4618 -t_srs EPSG:4326 amazonia_wgs84.shp amazonia.shp amazonia
#ogr2ogr -s_srs EPSG:4618 -t_srs  '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext' amazonia_msin.shp amazonia.shp amazonia


#pg_con=PG:"dbname='gisdb' host='localhost' port='5432' user='gis' password='mypassword'" 


function do_radam {
csv_file=/data/docs/research/project/data/radam-inland.csv 
nodata=100
mprefix="RADAM"

#res1=( "0.1" )
#res2=( "0p1d" )
#co_opt=("-co compress=DEFLATE" )
##res0=1
#res1=( "0.01" )
#res2=( "0p01d" )
#res1=( "0.00416666666666667" )
#res2=( "500m" )
#res1=( "0.001041667" "0.0041666667" )
##res1=( "0.001041667" )
##res2=( "125m" "250m" "500m" )
#res1=( "0.0041666667" )
#res2=( "500m" )

co_opt=("-co compress=DEFLATE" "-co compress=DEFLATE"  "-co compress=DEFLATE" )
name1=( ID_INLAND )
name2=( INLAND )
#name1=( ID_DOMI )
#name2=( AMALEGAL )
#area=( amalegal_completo )
##area=( clip1 clip2 clip3 clip4 )
#area=( clip1 )
#area=( amalegal_antropicas amalegal_vegetacao Tensao_vegetacao )
#proj=wgs84
proj="_wgs84"
#proj=""
#proj_s_srs="-s_srs EPSG:4618"
proj_s_srs=""
proj_t_srs="-t_srs EPSG:4326"

#ogr2ogr -clipsrc -73.991548  -18.041912 -59  -6  clip1.shp ../amalegal_completo_wgs84.shp amalegal_completo_wgs84 &
#ogr2ogr -clipsrc -59  -18.041912 -44.000350  -6  clip2.shp ../amalegal_completo_wgs84.shp amalegal_completo_wgs84
#ogr2ogr -clipsrc -73.991548  -6 -59   5.271810  clip3.shp ../amalegal_completo_wgs84.shp amalegal_completo_wgs84 &
#ogr2ogr -clipsrc -59  -6 -44.000350   5.271810  clip4.shp ../amalegal_completo_wgs84.shp amalegal_completo_wgs84
# rm large1.tif ; gdal_translate -co COMPRESS=DEFLATE -a_nodata 100 -projwin -73.991690344000006 5.269793353 -44.000014080000000 -18.042714107000002   amalegal_completo_INLAND_125m_wgs84.tif large1.tif

# 500m = 0.00416666666666667
# 250m = 0.00208333333333333
# 125m = 0.00104166666666667
#  80m = 0.000694444444444445

mprefix="amalegal_completo"
area=( clip1 clip2 clip3 clip4 )
#area=( clip2 clip3 clip4 )
#area=( clip1 )
#res1=( 0.00104166666666667 )
#res2=( "125m" "250m" "500m" )
#extent="-74.0031249545233 -33.9947916684695 -34.5041666211868 5.504166664867"
res1=( 0.00069444444444444 )
res2=( "80m" )
extent="-74.0031249545233 -33.9947916684695 -34.5034721767424 5.50486110931144"

#extent="-74.00416662119 -34.0000000018028 -34.499999954523865 5.49999999820033"
#extent="-74.00416662119 -33.9958333351362 -34.5041666211868 5.504166664867"
##extent="-74.0031249545233 -33.9947916684695 -34.5041666211868 5.504166664867"

#res2=( "125m" "500m" )
#outsize=( "25% 25%" )
#addo_levs="4"
#res1=( "0.0002604167" )
#res2=( "30m" "250m" "500m" )
#outsize=( "12.5% 12.5%" "6.25% 6.25%" )
#addo_levs="2 4 8 16"
#do_replace=0
#do_reproject=0
#do_rasterize=1
#do_rasterize2=0
#do_mosaic=1
#do_make
##do_mosaic

do_rasterize
#do_rasterize2
do_mosaic

area=( amalegal_completo )
#area=( "RADAM" )

#res1=( 0.00104166666666667 )
#res2=( "125m" "250m" "500m" )
#outsize=( "50% 50%" "25% 25%" )
#addo_levs="2 4"

res2=( "80m" "250m-3" "500m-3" )
#outsize=( "33.3333333333333% 33.3333333333333%" "16.66666666667% 16.66666666667%" )
#outsize=( "0.00208333333333333 0.00208333333333333" "0.00416666666666667 0.00416666666666667" )
outsize=( "18960 18960" "9480 9480" )
addo_levs="3 6"

#do_replace=0
#do_reproject=0
#do_rasterize=0
#do_rasterize2=1
##do_rasterize2=0
##do_combine=0
#do_mosaic=0

do_rasterize2

#if [[ "$do_combine" == "1" ]]; then
#    rm -f tmp1.vrt ${area[0]}_${name2[0]}_${res2[0]}${proj}.tif
#    gdalbuildvrt tmp1.vrt clip*_${name2[0]}_${res2[0]}${proj}.tif
#    gdal_translate -co compress=DEFLATE -ot Byte tmp1.vrt ${area[0]}_${name2[0]}_${res2[0]}${proj}.tif
#    rm -f tmp1.vrt
#fi
##do_make

}


function do_prodes {
csv_file=/data/docs/research/project/data/prodes-inland.csv 
nodata=100
mprefix="PRODES"

res1=( "0.1" )
res2=( "0p1d" )
#co_opt=("-co compress=DEFLATE" )
##res0=1
#res1=( "0.01" )
#res2=( "0p01d" )
#res1=( "0.00416666666666667" )
#res2=( "500m" )
#res1=( "0.001041667" "0.0041666667" )
#res1=( "0.001041667" "0.002083333" "0.0041666667" )
#res2=( "125m" "250m" "500m" )
co_opt=("-co compress=DEFLATE" "-co compress=DEFLATE"  "-co compress=DEFLATE" )
name1=( ID_INLAND )
name2=( INLAND )
#name1=( ID_DOMI )
#name2=( AMALEGAL )
area=( amalegal_completo )
#area=( amalegal_antropicas amalegal_vegetacao Tensao_vegetacao )
#proj=wgs84
proj="_wgs84"
#proj=""
#proj_s_srs="-s_srs EPSG:4618"
proj_s_srs=""
proj_t_srs="-t_srs EPSG:4326"

# merge all shapes into 1
ifiles=`for f in PDigital2000_2011_??_shp.zip; do echo -n /vsizip/$f" "; done`
rm -f tmp/PDigital2000_20011_AMZ2.*
ogr-merge tmp/PDigital2000_20011_AMZ2.shp $ifiles
do_replace=0
do_reproject=0
do_rasterize=1
do_mosaic=0
#do_make
}

function do_probio {
#csv_file=/data/docs/research/project/data/probio-vegtypes-detail.csv
    csv_file=/data/docs/research/project/data/probio-inland.csv 
nodata=100
mprefix="PROBIO"

#make low-res maps
#res1=( "0.1" "0.01" )
#res2=( "0p1d" "0p01d" )
#res1=( "0.1" "0.00416666666666667" )
#res2=( "0p1d" "500m" )
res1=( "0.00416666666666667" )
res2=( "500m" )

#res1=( "0.00027027" )
#res2=( "30m" )
#res1=( "0.1" )
#res2=( "0p1d" )
co_opt=( " " "-co compress=DEFLATE" )
#res1=( 0.002 )
#res2=( 0002 )
#co_opt=( "-co compress=DEFLATE" )
#res1=( 0.1 0.01 0.002 )
#res2=( 01 001 0002 )
#co_opt=( " " "-co compress=DEFLATE" "-co compress=DEFLATE" )
#name1=( ID_INLAND ID_FORMACA )
#name2=( INLAND PROBIO )
name1=( ID_INLAND )
name2=( INLAND )
area=( amazonia cerrado )
#area=( pampa pantanal caatinga amazonia cerrado  mata_atlantica )
#area=( pampa )
#area=( mata_atlantica )
#proj=( wgs84 msin )
#proj=( _wgs84 _msin )
#proj=wgs84
#proj="_wgs84"
proj=""
proj_s_srs="-s_srs EPSG:4618"
proj_t_srs="-t_srs EPSG:4326"

do_replace_reproject=0
do_rasterize=1
do_make

}

#function do_sin {
#        res1=( 10000 1000 )
#        res2=( 10km 1km )
##res1=( 231.656358264 )
##res2=( 250M )
#        co_opt=( " " "-co compress=DEFLATE" )
#        co_opt_merge="-co compress=DEFLATE"
#        proj=msin
#
#        #proj_srs="-t_srs '+proj=sinu +R=6371007.181 +nadgrids=@null +wktext'"
#        #echo "res1: "${res1[*]} ${#res1[*]}
##do_make_probio
#}

#            echo ${res1[$i_res]}-${res2[$i_res]}
#            echo ${name1[$i_name]}-${name2[$i_name]}
#            echo ${area[$i_area]}
#            echo gdal_rasterize -tr 0.1 0.1 -l amazonia -a ID_IBIS -a_nodata 0 -init 0 amazonia.shp amazonia_ibis_01.tif


GDAL_CACHEMAX=2048
GDAL_WARPCACHEMAX=2048

do_radam
