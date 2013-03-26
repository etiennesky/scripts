#!/bin/bash

#set -x 

source makemap-functions

#ifiles=`ls ?????_2008_shp.zip`
ifiles=""
#ifiles=`ls 2336?_2008_shp.zip`
#ifiles=22863_2008_shp.zip
csv_file=/data/docs/research/project/data/csv/terraclass-inland.csv
new_field_name1='INLAND_ID'
new_field_name2='TCLASS_ID'
old_field_name1='tcclasse'
old_field_name2='tcclasse'
field1=TCLASS_ID
field2=INLAND_ID

nodata=127
#res1=0.00027027
res1=0.00069444444444444
extent=""

co_opt="-co COMPRESS=DEFLATE"
nice_str="nice ionice -c 3"

mkdir -p tmp
cd tmp

do_rasterize=0
do_rasterize2=1
do_tclass=0

if [[ "$do_rasterize" == "1" ]]; then

echo $ifiles
tot=0
for ifile in $ifiles; do let "tot++" ; done

i=0
for ifile in $ifiles; do
    echo  "==============================================================="
    file_base=`echo $ifile | sed "s/_shp.zip//"`
    file_shp=${file_base}.shp
    file_tif1=`echo $file_shp | sed "s/.shp/_TCLASS.tif/"`
    file_tif2=`echo $file_shp | sed "s/.shp/_INLAND.tif/"`

    let "i++"
    echo $i/$tot $ifile $file_shp $file_tif1

    # reproject to wgs84
    if [ ! -f "${file_shp}" ]; then
        #ogr2ogr ${file_shp} /vsizip/../$ifile
        ${nice_str} ogr2ogr -t_srs EPSG:4326 ${file_shp} /vsizip/../$ifile
        ogrinfo -sql "CREATE SPATIAL INDEX ON ${file_base}" $file_shp
    fi


    ogr-replace-values.py ${file_shp} ${csv_file} $old_field_name1 $new_field_name1 $old_field_name2 $new_field_name2
    rm -f ${file_tif1} ${file_tif2}
    if [[ "$do_tclass" == "1" ]]; then
    ${nice_str} gdal_rasterize -a_nodata $nodata -init $nodata -tr $res1 $res1 -tap $co_opt -a $field1 $extent ${file_shp} ${file_tif1} &
    fi
    ${nice_str} gdal_rasterize -a_nodata $nodata -init $nodata -tr $res1 $res1 -tap $co_opt -a $field2 $extent ${file_shp} ${file_tif2}
    wait

done

set -x 
extent="-te -74.0031249545233 -33.9947916684695 -34.5034721767424 5.50486110931144"

if [[ "$do_tclass" == "1" ]]; then
echo "creating TERRACLASS_TCLASS mosaic"
rm -f TERRACLASS_TCLASS.vrt 
#gdalbuildvrt TERRACLASS_TCLASS_30m.vrt *_TCLASS.tif
#${nice_str} gdal_translate $co_opt TERRACLASS_TCLASS_30m.vrt TERRACLASS_TCLASS_30m.tif 
#gdalbuildvrt $extent -tr $res1 $res1 TERRACLASS_TCLASS_80m.vrt TERRACLASS_TCLASS_30m.tif
gdalbuildvrt $extent TERRACLASS_TCLASS_80m.vrt *_TCLASS.tif
${nice_str} gdal_translate $co_opt TERRACLASS_TCLASS_80m.vrt TERRACLASS_TCLASS_80m.tif
fi

echo "creating TERRACLASS_INLAND mosaic"
rm -f TERRACLASS_INLAND.vrt
#gdalbuildvrt $extent TERRACLASS_INLAND_30m.vrt *_INLAND.tif
#${nice_str} gdal_translate $co_opt TERRACLASS_INLAND_30m.vrt TERRACLASS_INLAND_30m.tif
#gdalbuildvrt $extent -tr $res2 $res2 TERRACLASS_INLAND_80m.vrt TERRACLASS_INLAND_30m.tif
gdalbuildvrt $extent TERRACLASS_INLAND_80m.vrt *_INLAND.tif
#gdalbuildvrt $extent TERRACLASS_INLAND_80m.vrt *_INLAND.tif
${nice_str} gdal_translate $co_opt TERRACLASS_INLAND_80m.vrt TERRACLASS_INLAND_80m-nodata.tif
${nice_str} gdal_translate -a_nodata none $co_opt TERRACLASS_INLAND_80m-nodata.tif TERRACLASS_INLAND_80m.tif

wait
rm -f *.vrt


fi

if [[ "$do_rasterize2" == "1" ]]; then

set -x 
echo "creating lower-resolution maps"

mprefix=""
co_opt=("-co compress=DEFLATE" "-co compress=DEFLATE"  "-co compress=DEFLATE" )
area=( TERRACLASS )
#name1=( TCLASS INLAND )
#name2=( TCLASS INLAND )
name1=( INLAND )
name2=( INLAND )

res1=( 0.00069444444444444 )
#res2=( "80m" "250m" "500m" )
#outsize=( "18960 18960" "9480 9480" )
#addo_levs="3 6"
res2=( "80m" "250m" )
outsize=( "18960 18960" )
addo_levs="3"

do_rasterize2

fi


# to make mosaic:
# gdalwarp -srcnodata 127 -dstnodata 127 -co COMPRESS=DEFLATE amalegal_completo_INLAND_250m_wgs84.tif TERRACLASS_INLAND_250m.tif amz_INLAND_250m.tif
# gdal_translate -co WRITE_BOTTOMUP=FALSE -co COMPRESS=DEFLATE -co FORMAT=NC4C -projwin -74.0031249545233 5.50486110931144 -43.998958288 -18.001388891 -of netcdf amz_INLAND_250m.tif tmp1.nc
# ncrename -v Band1,vegtype tmp1.nc amz_INLAND_250m.nc
