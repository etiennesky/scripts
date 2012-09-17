#!/bin/bash
source /data/docs/research/scripts/functions

set -x 

function usage()
{
echo "Usage: `basename $0` idir odir"
}

if [ $# -ne 2 ];  then usage ; exit 1 ; fi

#PROC_LIMIT=6         # Total number of process to start
PROC_LIMIT=1         # Total number of process to start
PROC_CURRENT=0        # Number of concurrent threads (forks?)
clean=1

#options_gtiff="-co COMPRESS=LZW" 
#options_gtiff="-co COMPRESS=DEFLATE" 
options_gtiff="-co COMPRESS=JPEG -co JPEG_QUALITY=100 -co PHOTOMETRIC=YCBCR" 
options_gitf_ovr="--config COMPRESS_OVERVIEW JPEG --config PHOTOMETRIC_OVERVIEW YCBCR --config INTERLEAVE_OVERVIEW PIXEL --config JPEG_QUALITY_OVERVIEW 100"
options_gitf_ovr2="--config COMPRESS_OVERVIEW DEFLATE"
options_gtif_ovr_levels="2 4 8 16 32 64 128"
options_gtiff2="-co COMPRESS=DEFLATE" 
options_jpeg="-co WORLDFILE=YES -co QUALITY=90" 
options_png="-co WORLDFILE=YES" 
export GDAL_PAM_ENABLED=NO


idir=$1
odir=$2
mkdir -p $odir/tmp_
#mkdir -p $odir/jpg
#mkdir -p $odir/tif

cd $odir/tmp_

#ifiles=`ls *BAND5.tif.zip`
#ifiles="LT52250652010166CUB01.tar.gz LE72250662009187EDC00.tar.gz"
ifiles=`ls ../../$idir/*.tar.gz ../../$idir/*.zip`
#ifiles="LT52250652010166CUB01.tar.gz"
#ifiles=`ls ../orig/*20110601*BAND5.tif.zip`
#ifiles=`ls *20100630*BAND5.tif.zip`

counter=0

function process_file()
{
#    ifile=../../$idir/$1
    ifile=$1
	ofile_base=`namename $ifile`
    pathrow=${ofile_base:3:6}
    ofile_tif=${ofile_base:0:16}"_RGB_JPG.tif"
    ofile_tif2=${ofile_base:0:16}"_RGB_TIF.tif"
	ofile_vrt=`namename $ofile_tif`".vrt"
	ofile_jpeg=`namename $ofile_tif`".jpg"
    echo "==========" $ifile $ofile_tif
    
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
      
    if [ -f ../$ofile_tif ]; then
        echo "skipping because file exists"
        return
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
        nice ionice -c 3 gdalbuildvrt -separate  $ofile_vrt $ifiles_tif 
        nice ionice -c 3 gdal_translate -a_nodata 0 -of gtiff $options_gtiff $ofile_vrt ../$ofile_tif &
        nice ionice -c 3 gdal_translate -a_nodata 0 -of gtiff $options_gtiff2 $ofile_vrt ../$ofile_tif2
        wait
        cp ../$ofile_tif2 ../$ofile_tif3
        nice ionice -c 3 gdaladdo -clean -ro $options_gitf_ovr ../$ofile_tif $options_gtif_ovr_levels &
        nice ionice -c 3 gdaladdo -clean -ro $options_gitf_ovr2 ../$ofile_tif2 $options_gtif_ovr_levels
        wait
#        nice ionice -c 3 gdal_translate -a_nodata 0 -of gtiff -co COMPRESS=DEFLATE $ofile_vrt ../tif/$ofile_tif2

#        nice ionice -c 3 gdalwarp -dstnodata 0 -of vrt -t_srs EPSG:4326 -tr 120 120 $ofile_vrt $ofile_vrt2
##        nice ionice -c 3 gdal_translate -a_nodata 0 -of vrt -outsize 25% 25% $ofile_vrt $ofile_vrt2
##        nice ionice -c 3 gdalwarp -srcnodata 0 -dstnodata 0 -dstalpha -of vrt -t_srs "EPSG:4326" $ofile_vrt2 $ofile_vrt3
##        nice ionice -c 3 gdal_translate --debug on -a_nodata 0 -of jpeg $options_jpeg $ofile_vrt3 ../jpg/$ofile_jpeg
#        nice ionice -c 3 gdalwarp -dstnodata 0 -of jpeg $options_jpeg -t_srs EPSG:4326 -tr 120 120 $ofile_vrt ../jpg/$ofile_jpeg
##        nice ionice -c 3 gdal_translate -a_nodata 0 -of jpeg $options_jpeg -outsize 25% 25% $ofile_vrt ../jpg/$ofile_jpeg
##        nice ionice -c 3 gdalwarp -dstnodata 0 -dstalpha -of gtiff -t_srs EPSG:4326 $options_gtiff $ofile_vrt ../tif/$ofile_tif2 ##&
    wait

#        nice ionice -c 3 gdaladdo 
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