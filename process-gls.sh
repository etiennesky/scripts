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
clean=1
#clean=0

#options_gtiff="-co COMPRESS=LZW" 
#options_gtiff="-co COMPRESS=DEFLATE" 
options_addo="-clean -ro -r average"
options_addo2="-clean -ro -r average"
options_gtiff="-co COMPRESS=JPEG -co JPEG_QUALITY=100 -co PHOTOMETRIC=YCBCR -co TILED=yes" 
options_gtiff2="-co COMPRESS=DEFLATE" 
options_gitf_ovr="--config COMPRESS_OVERVIEW JPEG --config PHOTOMETRIC_OVERVIEW YCBCR --config INTERLEAVE_OVERVIEW PIXEL --config JPEG_QUALITY_OVERVIEW 100"
options_gitf_ovr2="--config COMPRESS_OVERVIEW DEFLATE"
#options_gtif_ovr_levels="2 4 8 16 32 64 128"
options_gtif_ovr_levels="2 4 8"
options_jpeg="-co WORLDFILE=YES -co QUALITY=90" 
options_png="-co WORLDFILE=YES" 
wrs2_file="/data/research/data/gis/satellite/landsat/wrs2_descending.shp"

export GDAL_PAM_ENABLED=NO


idir=$1
odir=$2
mkdir -p $odir/tmp_
#mkdir -p $odir/jpg
#mkdir -p $odir/tif

cd $odir/tmp_

ifiles=`ls ../../$idir/*.tar.gz ../../$idir/*.zip`

counter=0

function process_file()
{
#    ifile=../../$idir/$1
    ifile=$1
    ofile_base=`namename $ifile`
    pathrow=${ofile_base:3:6}
    ofile_tif=${ofile_base:0:16}"_RGB_JPG.tif"
    ofile_tif2=${ofile_base:0:16}"_RGB_TIF.tif"
    ofile_tif3=${ofile_base:0:16}"_RGB_TIF2.tif"
    ofile_fin=${ofile_base:0:16}"_RGB.tif"
    ofile_vrt=`namename $ofile_tif`".vrt"
    ofile_vrt1=`namename $ofile_tif`"1.vrt"
    ofile_vrt2=`namename $ofile_tif`"2.vrt"
    ofile_jpeg=`namename $ofile_tif`".jpg"
    echo "==========" $ifile $ofile_tif

    # check for existing output file
    if [ -f ../$ofile_fin ]; then
        echo "skipping because file exists"
        return
    fi

    # check for tgz vs zip files
    if [[ "`ext $ifile`" = ".gz" ]]; then
        ifile_zip=../../$idir/`basename $ifile .tar.gz`.zip
        if [ -f $ifile_zip ]; then
            echo "skipping $ifile because $ifile_zip exists"
            return
        else
            rm -f *
            tar xzvf $ifile
            ##zip -r $ifile_zip *
            ##mv $ifile_zip ../../$idir
            ##ifile=../../$idir/$ifile_zip
            ##return
        fi
    fi
      
        #if [[ "$clean" == "1" ]]; then
        #    #tar xzvf $ifile
        #    tar xzvf $ifile --wildcards --no-anchored '*_B50.TIF' '*_B40.TIF' '*_B30.TIF'
        #fi
    ifiles_tif=""
    filelist=`tar tzvf $ifile`
    echo filelist: $filelist[*]
    for postfix in "_B50.TIF" "_B40.TIF" "_B30.TIF"; do 
        ifiles_tif=$ifiles_tif" "`ls *$postfix` 
    done
    
    echo $ifile $ofile_tif $pathrow $ifiles_tif
    
    rm -f ../$ofile_tif ../$ofile_tif2 # jpg/$ofile_jpg
    rm -f $ofile_vrt $ofile_vrt2 $ofile_vrt3

    # fill nodata in each band
    for ifile_tif in $ifiles_tif; do
	gdal_translate -a_nodata 0 $ifile_tif tmp1.tif
	gdal_fillnodata.py -md 2 tmp1.tif $ifile_tif
	rm tmp1.tif
    done

    nice ionice -c 3 gdalbuildvrt -separate  $ofile_vrt $ifiles_tif 
    nice ionice -c 3 gdalwarp -of vrt -dstnodata 0 -t_srs EPSG:4326 -cutline $wrs2_file -cwhere PR=$pathrow $ofile_vrt $ofile_vrt1
    nice ionice -c 3 gdal_translate -of gtiff $options_gtiff $ofile_vrt1 ../$ofile_tif
    nice ionice -c 3 gdal_translate -of gtiff $options_gtiff2 $ofile_vrt1 ../$ofile_tif2 &
    wait   
    #cp ../$ofile_tif2 ../$ofile_tif3
    #nice ionice -c 3 gdaladdo $options_addo $options_gitf_ovr ../$ofile_tif $options_gtif_ovr_levels
    nice ionice -c 3 gdaladdo $options_addo $options_gitf_ovr2 ../$ofile_tif2 $options_gtif_ovr_levels

    # just keep the jpg-compressed files with deflate-compressed overviews.
    #mv ../$ofile_tif2.ovr ../$ofile_tif.vr
    #rm ../$ofile_tif2.ovr
    mv ../${ofile_base:0:16}"_RGB_JPG.tif" ../${ofile_base:0:16}"_RGB.tif"
    mv ../${ofile_base:0:16}"_RGB_TIF.tif.ovr" ../${ofile_base:0:16}"_RGB.tif.ovr"
    pwd
    ls ..
    rm ../${ofile_base:0:16}"_RGB_"*

    if [[ "$clean" == "1" ]]; then
        rm -f *
    fi

    echo "----------" $ofile_tif

}

for ifile in $ifiles ; do
    process_file $ifile
done

cd ../..
pwd
if [[ "$clean" == "1" ]]; then
rm -rf $odir/tmp_/
fi










#old...

##ifiles="../../$idir/LT52250652010166CUB01.tar.gz ../../$idir/LE72250662009187EDC00.tar.gz"

#ifiles=`ls *BAND5.tif.zip`
#ifiles="LT52250652010166CUB01.tar.gz LE72250662009187EDC00.tar.gz"
#ifiles="LT52250652010166CUB01.tar.gz"
#ifiles=`ls ../orig/*20110601*BAND5.tif.zip`
#ifiles=`ls *20100630*BAND5.tif.zip`

#        nice ionice -c 3 gdalbuildvrt -separate  $ofile_vrt1 $ifiles_tif 
#        nice ionice -c 3 gdalwarp -of vrt -dstnodata 0 -t_srs EPSG:4326 -cutline $wrs2_file -cwhere PR=$pathrow $ofile_vrt1 $ofile_vrt
#        nice ionice -c 3 gdal_translate -a_nodata 0 -of gtiff $options_gtiff $ofile_vrt ../$ofile_tif &
#        nice ionice -c 3 gdal_translate -a_nodata 0 -of gtiff $options_gtiff2 $ofile_vrt ../$ofile_tif2

#keep
#        nice ionice -c 3 gdalbuildvrt -separate  $ofile_vrt $ifiles_tif 
#        nice ionice -c 3 gdalwarp -of vrt -dstnodata 0  $ofile_vrt1 $ofile_vrt
#        nice ionice -c 3 gdalwarp -dstnodata 0 -of gtiff -t_srs EPSG:4326 -cutline $wrs2_file -cwhere PR=$pathrow $options_gtiff $ofile_vrt ../$ofile_tif &
#        nice ionice -c 3 gdalwarp -dstnodata 0 -of gtiff -t_srs EPSG:4326 -cutline $wrs2_file -cwhere PR=$pathrow $options_gtiff2 $ofile_vrt ../$ofile_tif2
#        wait
#        cp ../$ofile_tif2 ../$ofile_tif3
#        nice ionice -c 3 gdaladdo $options_addo $options_gitf_ovr ../$ofile_tif $options_gtif_ovr_levels &
#        nice ionice -c 3 gdaladdo $options_addo $options_gitf_ovr2 ../$ofile_tif2 $options_gtif_ovr_levels
#        wait
#keep

#        nice ionice -c 3 gdal_translate -a_nodata 0 -of gtiff -co COMPRESS=DEFLATE $ofile_vrt ../tif/$ofile_tif2

#        nice ionice -c 3 gdalwarp -dstnodata 0 -of vrt -t_srs EPSG:4326 -tr 120 120 $ofile_vrt $ofile_vrt2
##        nice ionice -c 3 gdal_translate -a_nodata 0 -of vrt -outsize 25% 25% $ofile_vrt $ofile_vrt2
##        nice ionice -c 3 gdalwarp -srcnodata 0 -dstnodata 0 -dstalpha -of vrt -t_srs "EPSG:4326" $ofile_vrt2 $ofile_vrt3
##        nice ionice -c 3 gdal_translate --debug on -a_nodata 0 -of jpeg $options_jpeg $ofile_vrt3 ../jpg/$ofile_jpeg
#        nice ionice -c 3 gdalwarp -dstnodata 0 -of jpeg $options_jpeg -t_srs EPSG:4326 -tr 120 120 $ofile_vrt ../jpg/$ofile_jpeg
##        nice ionice -c 3 gdal_translate -a_nodata 0 -of jpeg $options_jpeg -outsize 25% 25% $ofile_vrt ../jpg/$ofile_jpeg
##        nice ionice -c 3 gdalwarp -dstnodata 0 -dstalpha -of gtiff -t_srs EPSG:4326 $options_gtiff $ofile_vrt ../tif/$ofile_tif2 ##&
