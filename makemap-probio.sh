#!/bin/bash

# this script is to rasterize probio shapefiles and make a mosaic
# see 

set -x

source makemap-functions

function do_probio {
#csv_file=/data/docs/research/project/data/probio-vegtypes-detail.csv
    csv_file=/data/docs/research/project/data/csv/probio-inland.csv 
nodata=127
mprefix="PROBIO"

name1=( ID_INLAND )
name2=( INLAND )
#area=( amazonia cerrado )
area=( cerrado )
proj_s_srs="-s_srs EPSG:4618"
proj_t_srs="-t_srs EPSG:4326"
proj="_wgs84"
co_opt=( "-co compress=DEFLATE" "-co compress=DEFLATE" )
extent="-te -60.5041666211889 -25.0000000018021 -41.5041666211874 -2.0000000018003"
res1=( 0.00069444444444444 )
res2=( "80m" )


do_replace
do_reproject
do_rasterize
#do_rasterize2
#do_mosaic

res2=( "80m" "250m" "500m" )
outsize=( "9120 11040" "4560 5520")
addo_levs="3 6"

do_rasterize2


##do_replace_reproject=0
##do_rasterize=1
##do_make

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

#do_radam
do_probio
