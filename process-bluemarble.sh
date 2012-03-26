#! /bin/bash

years="2004"
#months="01 07"
months="01"
#gdal_string='gdal_translate -of GTiff -co COMPRESS=DEFLATE -a_srs "+proj=latlong +datum=WGS84"'
gdal_string='gdal_translate -of GTiff -co COMPRESS=DEFLATE -co TILED=yes -a_srs EPSG:4326'
ifile_prefix="world.topo"

function process_it()
{
    for year in $years ; do
	for month in $months ; do
	    echo $gdal_string -a_ullr -180 90 -90   0 world.topo.$year$month.3x21600x21600.A1.jpg A1.tif
	    echo $gdal_string -a_ullr -90  90   0   0 world.topo.$year$month.3x21600x21600.B1.jpg B1.tif
	    echo $gdal_string -a_ullr   0  90  90   0 world.topo.$year$month.3x21600x21600.C1.jpg C1.tif
	    echo $gdal_string -a_ullr  90  90 180   0 world.topo.$year$month.3x21600x21600.D1.jpg D1.tif
	    echo $gdal_string -a_ullr -180  0 -90 -90 world.topo.$year$month.3x21600x21600.A2.jpg A2.tif
	    echo $gdal_string -a_ullr  -90  0   0 -90 world.topo.$year$month.3x21600x21600.B2.jpg B2.tif
	    echo $gdal_string -a_ullr    0  0  90 -90 world.topo.$year$month.3x21600x21600.C2.jpg C2.tif
	    echo $gdal_string -a_ullr   90  0 180 -90 world.topo.$year$month.3x21600x21600.D2.jpg D2.tif
	done
    done
}


#http://ian01.geog.psu.edu/geoserver_docs/data/bluemarble/bluemarble.html
function process_it2()
{
for year in $years ; do
for month in $months ; do

left=-180

for i in A B C D
do 
	right=`expr $left + 90`	
	top=90
	for k in 1 2
	do
		bot=`expr $top - 90`
		ifile=$ifile_prefix.$year$month.3x21600x21600.${i}${k}.png 
#		ifile=$ifile_prefix.$year$month.3x21600x21600.${i}${k}.jpg 
		ofile=$ifile_prefix.$year$month.3x21600x21600.${i}${k}.tif 
		if [ ! -e $ifile ] ; then
			echo $ifile does not exists
			continue
		fi
		if [ -e $ofile ] ; then
			echo $ofile exists
		else
		    $gdal_string -a_ullr $left $top $right $bot $ifile $ofile
		fi
		top=0
	done
	left=`expr $left + 90`
done

done
done
}

process_it2

