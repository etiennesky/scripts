#!/bin/bash

# this script is to rasterize probio shapefiles and make a mosaic
# see 

set -x

source makemap-functions

function do_ibama {
#csv_file=/data/docs/research/project/data/probio-vegtypes-detail.csv
    csv_file=/data/docs/research/project/data/csv/ibama_anthropico_cerrado.csv
nodata=254
mprefix="IBAMA"

name1=( ID_DES )
name2=( ANODES )
area=( ANTROPICO_CERRADO_2009 )
proj="_wgs84"
proj_s_srs="-s_srs EPSG:4618"
proj_t_srs="-t_srs EPSG:4326"
co_opt=( "-co compress=DEFLATE" "-co compress=DEFLATE" )
extent="-te -60.5041666211889 -25.0000000018021 -41.5041666211874 -2.0000000018003"
res1=( 0.00069444444444444 )
res2=( "80m" )
#do_replace
##ogr-replace-value.py  ${area[0]}.shp ${csv_file} ANO_DES ID_DES
##do_reproject
##do_rasterize
#do_rasterize2
#do_mosaic

res2=( "80m" "250m" "500m" )
outsize=( "9120 11040" "4560 5520")
addo_levs="3 6"
do_rasterize2

}

function do_ibama_cerrado_water {
#csv_file=/data/docs/research/project/data/probio-vegtypes-detail.csv
    csv_file=""
nodata=254
mprefix="IBAMA"

name1=( ID_WATER )
name2=( WATER )
area=( CORPO_DAGUA_CERRADO_2009 )
proj="_wgs84"
proj_s_srs="-s_srs EPSG:4618"
proj_t_srs="-t_srs EPSG:4326"
co_opt=( "-co compress=DEFLATE" "-co compress=DEFLATE" )
extent="-te -60.5041666211889 -25.0000000018021 -41.5041666211874 -2.0000000018003"
res1=( 0.00069444444444444 )
res2=( "80m" )

rm -f CORPO_DAGUA_CERRADO_2009.{shp,shx,prj,dbf}
ogr2ogr -sql "SELECT *, 16 AS ID_WATER FROM CORPO_DAGUA_CERRADO_2009" CORPO_DAGUA_CERRADO_2009.shp /vsizip/CORPO_DAGUA_CERRADO_2009.zip
do_reproject
do_rasterize
#do_rasterize2
#do_mosaic

res2=( "80m" "250m" "500m" )
outsize=( "9120 11040" "4560 5520")
addo_levs="3 6"
do_rasterize2

}


function do_siad {
csv_file=/data/docs/research/project/data/siad_cerrado.csv
nodata=100
mprefix="SIAD"

name1=( ID_DES )
name2=( ANODES )
area=( ANTROPICO_CERRADO_2010 )
proj_s_srs="-s_srs EPSG:4618"
proj_t_srs="-t_srs EPSG:4326"
co_opt=( "-co compress=DEFLATE" "-co compress=DEFLATE" )
extent="-te -60.5041666211889 -25.0000000018021 -41.5041666211874 -2.0000000018003"
#res1=( 0.00069444444444444 )
#res2=( "80m" )
res1=( 0.000520833333333 )
res2=( "60m" )
#res1=( 0.000260416666666667 )
#res2=( "30m" )

#do_rasterize
#do_rasterize2
#do_mosaic

#res2=( "80m" "250m-80" "500m-80" )
#outsize=( "9120 11040" "4560 5520")
#addo_levs="3 6"
res2=( "60m" "250m-60" "500m-60" )
outsize=( "9120 11040" "4560 5520")
addo_levs="4 8"
#res2=( "30m" "250m-30" "500m-30" )
#outsize=( "9120 11040" "4560 5520")
#addo_levs="8 16"

do_rasterize2



}


GDAL_CACHEMAX=2048
GDAL_WARPCACHEMAX=2048


do_ibama_cerrado_water
