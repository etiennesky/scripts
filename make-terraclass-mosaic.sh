#!/bin/bash

#set -x 

ifiles=`ls ?????_2008_shp.zip`
#ifiles=`ls 2336?_2008_shp.zip`
#ifiles=23361_2008_shp.zip
csv_file=/data/docs/research/project/data/terraclass.csv
new_field_name1='INLAND_ID'
new_field_name2='TCLASS_ID'
old_field_name1='tcclasse'
old_field_name2='tcclasse'

nodata=100
res=0.00027027
co_opt="-co COMPRESS=DEFLATE"
field1=TCLASS_ID
field2=INLAND_ID

mkdir -p tmp
cd tmp

echo $ifiles

for ifile in $ifiles; do
    echo  "==============================================================="
    echo $ifile
    file_shp=`echo $ifile | sed "s/_shp.zip/.shp/"`
    file_tif1=`echo $file_shp | sed "s/.shp/_TCLASS.tif/"`
    file_tif2=`echo $file_shp | sed "s/.shp/_INLAND.tif/"`

    #rm -f tmp/tmp1.*
    if [ ! -f "${file_shp}" ]; then
        ogr2ogr ${file_shp} /vsizip/../$ifile
    fi

    ogr-replace-values.py ${file_shp} ${csv_file} $old_field_name1 $new_field_name1 $old_field_name2 $new_field_name2
    rm -f ${file_tif1} ${file_tif2}
    nice gdal_rasterize -a_nodata $nodata -init $nodata -tr $res $res -tap $co_opt -a $field1 ${file_shp} ${file_tif1} &
    nice gdal_rasterize -a_nodata $nodata -init $nodata -tr $res $res -tap $co_opt -a $field2 ${file_shp} ${file_tif2}
    wait
#    rm -f tmp/tmp1.*
done

rm -f TERRACLASS_TCLASS.vrt TERRACLASS_INLAND.vrt
gdalbuildvrt TERRACLASS_TCLASS.vrt *_TCLASS.tif
gdalbuildvrt  TERRACLASS_INLAND.vrt *_INLAND.tif

nice gdal_translate  -co COMPRESS=DEFLATE TERRACLASS_TCLASS.vrt TERRACLASS_TCLASS.tif
nice gdal_translate  -co COMPRESS=DEFLATE TERRACLASS_INLAND.vrt TERRACLASS_INLAND.tif

