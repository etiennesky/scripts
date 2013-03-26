#!/bin/bash

set -x

source makemap-functions


function do_radam {
csv_file=/data/docs/research/project/data/csv/ibge-inland.csv 
nodata=127
mprefix="RADAM"

co_opt=("-co compress=DEFLATE" "-co compress=DEFLATE"  "-co compress=DEFLATE" )
name1=( ID_INLAND )
name2=( INLAND )
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
res1=( 0.00069444444444444 )
res2=( "80m" )


extent="-te -74.0031249545233 -33.9947916684695 -34.5034721767424 5.50486110931144"

do_replace2
do_reproject
do_rasterize
#do_rasterize2
do_mosaic

area=( amalegal_completo )

#res2=( "80m" "250m" "500m" )
#outsize=( "18960 18960" "9480 9480" )
#addo_levs="3 6"
res2=( "80m" "250m" )
outsize=( "18960 18960" )
addo_levs="3"

do_rasterize2


}

GDAL_CACHEMAX=2048
GDAL_WARPCACHEMAX=2048

do_radam
