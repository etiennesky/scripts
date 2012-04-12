#!/bin/bash
source /data/docs/research/scripts/functions

#set -x 

function usage()
{
echo "Usage: `basename $0` idir odir"
}

if [ $# -ne 2 ];  then usage ; exit 1 ; fi

#PROC_LIMIT=6         # Total number of process to start
PROC_LIMIT=1         # Total number of process to start
PROC_CURRENT=0        # Number of concurrent threads (forks?)


#options_gtiff="-co COMPRESS=LZW" 
options_gtiff="-co COMPRESS=DEFLATE" 
options_jpeg="-co WORLDFILE=YES -co QUALITY=85" 
options_png="-co WORLDFILE=YES" 
export GDAL_PAM_ENABLED=NO


idir=$1
odir=$2
mkdir -p $odir/tmp_
mkdir -p $odir/jpg
mkdir -p $odir/tif

cd $odir/tmp_

#ifiles=`ls *BAND5.tif.zip`
ifiles="LT52250652010166CUB01.tar.gz LE72250662009187EDC00.tar.gz"
#ifiles="LT52250652010166CUB01.tar.gz"
#ifiles=`ls ../orig/*20110601*BAND5.tif.zip`
#ifiles=`ls *20100630*BAND5.tif.zip`

counter=0

function process_file()
{
    ifile=../../$idir/$1
	ofile_base=`namename $ifile`
    pathrow=${ofile_base:3:6}
    ofile_tif=${ofile_base:0:16}"RGB.tif"
    ofile_tif2=${ofile_base:0:16}"RGB2.tif"
	ofile_vrt=`namename $ofile_tif`".vrt"
	ofile_jpeg=`namename $ofile_tif`".jpg"
#	ofile_png=`namename $ofile_tif`".png"
#    tmpfile=../tmp_/$ofile_tif
#    tmpfile=../$odir/tmp_/$ofile_vrt
#    echo $ofile_tif -$ofile_jpeg-$ifiles_tif
    echo "==========" $ifile $ofile_tif
    
    if [ -f ../tif/$ofile_tif ]; then
        echo "skipping because file exists"
    else
        
        tar xzvf $ifile
        ifiles_tif=""
        for postfix in "_B50.TIF" "_B40.TIF" "_B30.TIF"; do 
            ifiles_tif=$ifiles_tif" "`ls *$postfix` 
        done

        echo $ifile $ofile_tif $pathrow $ifiles_tif

##    gdal_merge.py -separate $ifiles_tif  $options_gtiff -o rgb/$ofile_tif #TM_${i_date}tmp2.tif
#    rm -f $tmpfile ../$odir/$ofile_tif
        rm -f $ofile_vrt jpg/$ofile_jpg
##    echo nice ionice -c 3 gdal_merge.py -separate -o $tmpfile $ifiles_tif 
##    nice ionice -c 3 gdal_merge.py -separate -o $tmpfile $ifiles_tif 
        nice ionice -c 3 gdalbuildvrt -separate  $ofile_vrt $ifiles_tif 
        nice ionice -c 3 gdal_translate -a_nodata 0 -of gtiff $options_gtiff $ofile_vrt ../tif/$ofile_tif &
#        nice ionice -c 3 gdal_translate -a_nodata 0 -of jpeg $options_jpeg -outsize 25% 25% $ofile_vrt ../jpg/$ofile_jpeg
        nice ionice -c 3 gdalwarp -dstnodata 0 -dstalpha -of gtiff -t_srs EPSG:4326 $options_gtiff $ofile_vrt ../tif/$ofile_tif2 &
        wait
        rm -f *
    
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

cd ../..
pwd
rm -rf $odir/tmp_/
