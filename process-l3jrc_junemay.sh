#! /bin/bash

source functions

years1=( `seq 2000 2006` )
years2=( `seq 2001 2007` )
#years1=2001
#years2=2002

options_gtiff="COMPRESS=DEFLATE" 

echo "years1: $years1"
echo "years2: $years2"


for (( i=0; i<${#years1[@]}; i++ )); do
    year1=${years1[$i]}
    year2=${years2[$i]}
    echo "===================================================="
    echo $i"-"$year1"-"$year2

    ifile1=L3JRC.burndate.sam.$year1.wgs84.tif
    ifile2=L3JRC.burndate.sam.$year2.wgs84.tif
    ofile=L3JRC.burndate.sam.$year1-$year2.wgs84.tif
    if [ "$year1" = "2006" ]; then
	ifile2=""
#l3jrc.burndate.sam.2006.wgs84.tif
#	ofile=L3JRC.burndate.sam.jun2006-dec2006.wgs84.tif
    fi

    ofile2=`echo $ofile |  sed 's/.wgs84./.utm23s./'`

#    rm -f tmp?.tif* $ofile $ofile2

#    echo $ifile1 $ifile2 $ofile
    echo writing file $ofile
    l3jrc-split $ofile $ifile1 $ifile2

    echo writing file $ofile2
    gdalwarp  -co "$options_gtiff" -s_srs 'EPSG:4326' -t_srs 'EPSG:32723' -srcnodata $nodata -dstnodata $nodata -overwrite $ofile $ofile2





done