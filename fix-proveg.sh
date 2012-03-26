#! /bin/bash

set -x 

ifile="Vegetacao_GRT.asc"
ofile="Vegetacao_lcp.asc"
nodata="-9999"
indexes_i="1 2 3 4 5 6 7 8 9"
indexes_i=( $indexes_i )
indexes_o="18 20 99 99 16 16 16 $nodata $nodata"
indexes_o=( $indexes_o )
indexes_n=9

rm -f tmp?.tif $ofile

#gdal_merge.py -ul_lr 288010.461 7782429.496 359080.461 7748499.496 -n -1 -init -1 -a_nodata -1  -o tmp1.tif $ifile
gdal_merge.py -ul_lr 288010.461 7782429.496 359080.461 7748499.496 -n $nodata -init $nodata -a_nodata $nodata  -o tmp1.tif $ifile
 
for (( i=0; i<$indexes_n; i++ )); 
do
    echo $i" - "${indexes_i[$i]}" - "${indexes_o[$i]}
    val_repl.py -innd ${indexes_i[$i]} -outnd ${indexes_o[$i]} -ot Int32 tmp1.tif tmp1.tif
done

gdal_translate -of AAIgrid -a_nodata $nodata -a_srs "EPSG:32723"  tmp1.tif $ofile

rm -f tmp?.tif
