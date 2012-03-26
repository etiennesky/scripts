#! /bin/bash

source functions

years1=( `seq 2000 2006` )
years2=( `seq 2001 2007` )

options_gtiff="COMPRESS=DEFLATE" 
nodata=0

for (( i=0; i<${#years1[@]}; i++ )); do
    year1=${years1[$i]}
    year2=${years2[$i]}

    ifile=`ls $year1*.zip`
    ifile_tif=`echo $ifile |  sed 's/.zip/.tif/'`
    ifile_txt=`echo $ifile |  sed 's/.zip/.txt/'`
    ofile1=L3JRC.burndate.world.$year1-$year2.wgs84.tif
    ofile2=L3JRC.burndate.sam.$year1-$year2.wgs84.tif
    ofile3=L3JRC.burndate.sam.$year1-$year2.utm23s.tif

    echo "===================================================="
    echo $i"-"$year1"-"$year2
    echo $ifile $ofile1 $ofile2 $ofile3

#make ofile1world file from zip if needed
    if [ ! -f $ofile1 ] ; then 
	file_exist=0
	if [ -f $ifile_tif ] ; then file_exist=1 ; fi
	if [ ! $file_exist -eq 1 ]; then unzip $ifile ; fi
	echo writing file $ofile1
	gdal_translate -co $options_gtiff -a_nodata $nodata $ifile_tif $ofile1
    #cleanup
	if [ ! $file_exist -eq 1 ]; then rm -f $ifile_tif $ifile_txt ; fi
    fi

#done
#exit

#rm -f $ofile2 $ofile3

echo writing file $ofile2
gdal_translate -co $options_gtiff -a_nodata $nodata -projwin -82.1 13.1 -33.9 -55.55 $ofile1 $ofile2
echo writing file $ofile3
gdalwarp  -co "$options_gtiff" -s_srs 'EPSG:4326' -t_srs 'EPSG:32723' -srcnodata $nodata -dstnodata $nodata -overwrite $ofile2 $ofile3

echo writing pnsc file
clip-pnsc-l3jrc $ofile3 

done
