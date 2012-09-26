#!/bin/bash

set -x 

source makemap-functions

#ifiles=`ls ?????_2008_shp.zip`
ifiles=""
#ifiles=`ls 2336?_2008_shp.zip`
#ifiles=23361_2008_shp.zip
csv_file=/data/docs/research/project/data/csv/terraclass-inland.csv
new_field_name1='INLAND_ID'
new_field_name2='TCLASS_ID'
old_field_name1='tcclasse'
old_field_name2='tcclasse'

nodata=254
res1=0.00027027
extent=""

co_opt="-co COMPRESS=DEFLATE"
field1=TCLASS_ID
field2=INLAND_ID


mkdir -p tmp
cd tmp

echo $ifiles

do_rasterize=0

if [[ "$do_rasterize" == "1" ]]; then

for ifile in $ifiles; do
    echo  "==============================================================="
    file_shp=`echo $ifile | sed "s/_shp.zip/.shp/"`
    file_tif1=`echo $file_shp | sed "s/.shp/_TCLASS.tif/"`
    file_tif2=`echo $file_shp | sed "s/.shp/_INLAND.tif/"`

    echo $ifile $file_shp $file_tif1

    #rm -f tmp/tmp1.*
    if [ ! -f "${file_shp}" ]; then
        ogr2ogr ${file_shp} /vsizip/../$ifile
    fi

    ogr-replace-values.py ${file_shp} ${csv_file} $old_field_name1 $new_field_name1 $old_field_name2 $new_field_name2
    rm -f ${file_tif1} ${file_tif2}
    nice gdal_rasterize -a_nodata $nodata -init $nodata -tr $res1 $res1 -tap $co_opt -a $field1 $extent ${file_shp} ${file_tif1}
    nice gdal_rasterize -a_nodata $nodata -init $nodata -tr $res1 $res1 -tap $co_opt -a $field2 $extent ${file_shp} ${file_tif2}
    wait
#    rm -f tmp/tmp1.*
done


extent="-te -74.0031249545233 -33.9947916684695 -34.5034721767424 5.50486110931144"

rm -f TERRACLASS_TCLASS.vrt 
gdalbuildvrt TERRACLASS_TCLASS_30m.vrt *_TCLASS.tif
nice gdal_translate $co_opt TERRACLASS_TCLASS_30m.vrt TERRACLASS_TCLASS_30m.tif
gdalbuildvrt $extent -tr $res1 $res1 TERRACLASS_TCLASS_80m.vrt TERRACLASS_TCLASS_30m.tif
nice gdal_translate $co_opt TERRACLASS_TCLASS_80m.vrt TERRACLASS_TCLASS_80m.tif
rm -f *.vrt

#rm -f TERRACLASS_INLAND.vrt
#gdalbuildvrt TERRACLASS_INLAND_30m.vrt *_INLAND.tif
#nice gdal_translate $co_opt TERRACLASS_INLAND_30m.vrt TERRACLASS_INLAND_30m.tif
#gdalbuildvrt $extent -tr $res1 $res1 TERRACLASS_INLAND_80m.vrt TERRACLASS_INLAND_30m.tif
#nice gdal_translate $co_opt TERRACLASS_INLAND_80m.vrt TERRACLASS_INLAND_80m.tif
#rm -f *.vrt


fi


mprefix=""
co_opt=("-co compress=DEFLATE" "-co compress=DEFLATE"  "-co compress=DEFLATE" )
area=( TERRACLASS )
#name1=( TCLASS INLAND )
#name2=( TCLASS INLAND )
name1=( TCLASS INLAND )
name2=( TCLASS INLAND )

res1=( 0.00069444444444444 )
res2=( "80m" "250m" "500m" )
outsize=( "18960 18960" "9480 9480" )
addo_levs="3 6"

do_rasterize2

