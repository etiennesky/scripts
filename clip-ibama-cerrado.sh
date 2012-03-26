#!/bin/bash

shape_base="/data/research/data/gis/grids/wrs2_descending_cerrado_PRODES"
scenes=`dbfdump $shape_base.dbf | awk '{print($6)}' | grep -v PR_`
#scenes="22164 22165"

echo $scenes

mkdir -p out
for scene in $scenes ; do

    echo -- $scene
#    for prefix in ANTROPICO CORPO_DAGUA REMANESCENTE; do
    for prefix in CORPO_DAGUA; do
        echo ogr2ogr -skipfailure -clipsrc $shape_base.shp -clipsrcwhere PR_PRODES="'"$scene"'" out/${prefix}_C2009_$scene.shp ${prefix}_CERRADO_2009.shp &
        ogr2ogr -skipfailure -clipsrc $shape_base.shp -clipsrcwhere PR_PRODES="'"$scene"'" out/${prefix}_C2009_$scene.shp ${prefix}_CERRADO_2009.shp &
    done
    wait
 
done

