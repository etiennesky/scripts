#!/bin/bash
source /data/docs/research/bin/functions

#set -x 

function usage()
{
echo "Usage: `basename $0` idir odir"
}

if [ $# -ne 2 ];  then usage ; exit 1 ; fi

PROC_LIMIT=6         # Total number of process to start
PROC_CURRENT=0        # Number of concurrent threads (forks?)

#echo $i_files
#exit

#i_dates="20030616 20030702 20030718 20030920 20031022 20040330 20040501 20040602 20040821"
#i_dates="20070408 20070424 20070611 20070627 20070713 20070729 20070814 20070830 20070915 20080512 20080528 20080613"
#i_dates=$@

#options_gtiff="-co COMPRESS=LZW" 
options_gtiff="-co COMPRESS=DEFLATE" 
options_jpeg="-co WORLDFILE=YES -co QUALITY=85" 
options_png="-co WORLDFILE=YES" 
export GDAL_PAM_ENABLED=NO

echo "i_dates: $i_dates"
#exit

idir=$1
odir=$2
mkdir -p $odir/tmp_
mkdir -p $odir/jpg

cd $idir

ifiles=`ls *BAND5.tif.zip`
#ifiles=`ls ../orig/*20110601*BAND5.tif.zip`
#ifiles=`ls *20100630*BAND5.tif.zip`

counter=0

function process_file()
{
    ifile5=$1
    ifiles_tif=""
	ofile_tif=`namename $ifile5 |  sed "s/BAND5/RGB345/"`
	ofile_vrt=`namename $ofile_tif`".vrt"
	ofile_jpeg=`namename $ofile_tif`".jpg"
	ofile_png=`namename $ofile_tif`".png"
#    tmpfile=../tmp_/$ofile_tif
    tmpfile=../$odir/tmp_/$ofile_vrt
#    echo $ofile_tif -$ofile_jpeg-$ifiles_tif
    echo "==========" $ofile_tif
    if [ -f ../$odir/$ofile_tif ]; then
        echo "skipping because file exists"
    else

    for i_band in BAND5 BAND4 BAND3
    do
#        echo $i_band
	    ifile_zip=`echo $ifile5 | sed "s/BAND5/${i_band}/"`
	    ifile_tif=`namename $ifile_zip`
#	    echo $ifile_zip $ifile_tif
#	    ifiles_tif=$ifiles_tif" "$ifile_tif
	    ifiles_tif=$ifiles_tif" /vsizip/"$ifile_zip"/"$ifile_tif
#        pwd
#        ls $ifile_zip
#        gdalinfo "/vsizip/"$ifile_zip"/"$ifile_tif
#	    rm -f $ifile_tif
#	    nice ionice -c 3 unzip -o $ifile_zip > /dev/null
    done

    echo $ofile_tif $ifiles_tif
#    gdal_merge.py -separate $ifiles_tif  $options_gtiff -o rgb/$ofile_tif #TM_${i_date}tmp2.tif
    rm -f $tmpfile ../$odir/$ofile_tif
#    echo nice ionice -c 3 gdal_merge.py -separate -o $tmpfile $ifiles_tif 
#    nice ionice -c 3 gdal_merge.py -separate -o $tmpfile $ifiles_tif 
    nice ionice -c 3 gdalbuildvrt -separate  $tmpfile $ifiles_tif 
    nice ionice -c 3 gdal_translate -a_nodata 0 -of gtiff $options_gtiff $tmpfile ../rgb/$ofile_tif
    nice ionice -c 3 gdal_translate -a_nodata 0 -of jpeg $options_jpeg -outsize 25% 25% $tmpfile ../rgb/jpg/$ofile_jpeg
    rm -f $tmpfile
    
    fi
    echo "----------" $ofile_tif

}

#echo $ifiles
#for i_date in $i_dates
for ifile in $ifiles
do

    let "PROC_CURRENT++"

#    echo $ifile $PROC_CURRENT

    echo "current: $PROC_CURRENT limit: $PROC_LIMIT"
    if [ $PROC_CURRENT -gt $PROC_LIMIT ] ; then
        echo "waiting..."
        wait
        echo "ok!"
    let "PROC_CURRENT=1"
    fi


#    sleep 2 &
     process_file $ifile & 

done

wait

cd ..
rm -rf $odir/tmp_/
