#!/bin/bash
source /data/docs/research/bin/functions

set -x 

ifile=$1
ofile=$2
tmpfile1=tmp1.vrt
tmpfile2=tmp2.vrt

rm -f $tmpfile1 $tmpfile2

gdal_translate -b 5 -b 4 -b 3 -of vrt $ifile $tmpfile1 
gdalwarp -of vrt $tmpfile1 $tmpfile2
gdal_translate -of gtiff -co COMPRESS=DEFLATE $tmpfile2 $ofile

rm -f $tmpfile1 $tmpfile2
