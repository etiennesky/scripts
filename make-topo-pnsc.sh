#!/bin/bash

set -x

function maketopomap {

echo "function maketopomap ( " $* " )"

    if [ $# -ne 3 ]
    then
	echo "Usage: $0 ifile ofile levels"
	exit 1
    fi

    rm -f tmp1.tif tmp2.tif $1".tif" $2".tif" $3*
    unzip $1"_tf.zip"
    unzip $2"_tf.zip"
    
    gdal_merge.py -o tmp1.tif $1".tif" $2".tif" 

    gdalwarp -t_srs "EPSG:32723" -s_srs "EPSG:4326" -tr $_tr -r bilinear -overwrite  tmp1.tif tmp2.tif

    gdal_merge.py -o $3".tif" -ul_lr $_crop tmp2.tif

#    gdalwarp -s_srs "+proj=utm +zone=23 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs" -t_srs "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs" tmp2.tif tmp3.tif


    gdal_translate -of AAIGrid $3".tif" $3".asc"
    gdal_translate -of AAIGrid -ot UInt16 $3".tif" $3"2.asc"
 
   rm -f tmp1.tif tmp2.tif $1".tif" $2".tif"
}


#_crop="-47.05 -20.0 -46.35 -20.5"
#_crop="-47.025 -20.05 -46.35 -20.35"
#_crop="288207.419 7782415.368 359078.863 7748489.733"
#modified to conform to "vegetacao"
_crop="288010.461 7782429.496 359080.461 7748499.496"
#_tr=" 0.000284526229472 0.000284526229472"
_tr="30 30"

maketopomap "20_465ON" "20_48_ON" "pnsc_topo_on"
maketopomap "20_465SN" "20_48_SN" "pnsc_topo_sn"
maketopomap "20_465ZN" "20_48_ZN" "pnsc_topo_zn"

#gdal_translate -of AAIGrid pnsc_topo_on.tif pnsc_topo_on.asc
#gdal_translate -of AAIGrid pnsc_topo_sn.tif pnsc_topo_sn.asc
#gdal_translate -of AAIGrid pnsc_topo_zn.tif pnsc_topo_zn.asc

gdal_translate -of AAIGrid -ot Int32 pnsc_topo_on.tif pnsc_topo_on2.asc
gdal_translate -of AAIGrid -ot Int32 pnsc_topo_sn.tif pnsc_topo_sn2.asc
gdal_translate -of AAIGrid -ot Int32 pnsc_topo_zn.tif pnsc_topo_zn2.asc
