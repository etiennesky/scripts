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

#MOD09GA.A2010277.h11v10.005.2010279153815.hdf
#ifiles=`ls MOD09GA*.hdf`
ifiles="MOD09GA.A2010278.h11v10.005.2010280101846.hdf MOD09GA.A2010278.h11v09.005.2010280102154.hdf"
#ifiles=MOD09GA.A2010277.h11v09.005.2010279151539.hdf
#ifiles=`ls ../orig/*20110601*BAND5.tif.zip`
#ifiles=`ls *20100630*BAND5.tif.zip`

counter=0

function process_file()
{
    echo "process_file"
	ofile_vrt=`namename $ofile_tif`".vrt"
	ofile_jpeg=`namename $ofile_tif`".jpg"
	ofile_png=`namename $ofile_tif`".png"
    tmpfile=../$odir/tmp_/$ofile_vrt
    echo "==========" $ifile $ofile_tif
    if [ -f ../$odir/$ofile_tif ]; then
        echo "skipping because file exists"
    else
    pwd
    echo $ofile_tif $ifiles
    rm -f $tmpfile ../$odir/$ofile_tif
    nice ionice -c 3 gdalbuildvrt -separate  $tmpfile $ifiles
    nice ionice -c 3 gdal_translate -of gtiff $options_gtiff $tmpfile ../rgb/$ofile_tif
    if [ $make_jpeg -eq 1 ];  then nice ionice -c 3 gdal_translate -of jpeg $options_jpeg -outsize 25% 25% $tmpfile ../rgb/jpg/$ofile_jpeg ; fi

    rm -f $tmpfile
    
    fi
    echo "----------" $ofile_tif

}

function process_files()
{
    #MOD09GA.A2010277.h11v09.005.2010279151539.hdf
    ifile=$1
    date_tile=${ifile:8:15}
    ifiles_tc=""
    ifiles_fc=""
    ifiles_17=""

    for i_band in sur_refl_b01_1 sur_refl_b02_1 sur_refl_b03_1 sur_refl_b04_1 sur_refl_b05_1 sur_refl_b06_1 sur_refl_b07_1
    do
	    ifile_17=HDF4_EOS:EOS_GRID:'"'$ifile'"':MODIS_Grid_500m_2D:$i_band
	    ifiles_17=$ifiles_17" "$ifile_17
    done
	ofile_tif=${ifile:0:23}.b1-7.tif
    ifiles=$ifiles_17
    echo $ofile_tif $ifiles
    make_jpeg=0
#    process_file

    for i_band in sur_refl_b01_1 sur_refl_b04_1 sur_refl_b03_1
    do
	    ifile_tc=HDF4_EOS:EOS_GRID:'"'$ifile'"':MODIS_Grid_500m_2D:$i_band
	    ifiles_tc=$ifiles_tc" "$ifile_tc
    done
	ofile_tif=${ifile:0:23}.tc-b143.tif
    ifiles=$ifiles_tc
    echo $ofile_tif $ifiles
    make_jpeg=1
    process_file


    for i_band in sur_refl_b01_1 sur_refl_b02_1 sur_refl_b06_1
    do
	    ifile_fc=HDF4_EOS:EOS_GRID:'"'$ifile'"':MODIS_Grid_500m_2D:$i_band
	    ifiles_fc=$ifiles_fc" "$ifile_fc
    done
	ofile_tif=${ifile:0:23}.fc-b126.tif
    ifiles=$ifiles_fc
    echo $ofile_tif $ifiles
    make_jpeg=1
    process_file

    ifile2=`ls MOD09GQ.$date_tile.*.hdf`
    if [ -f $ifile2 ]; then
	    ofile_tif=${ifile2:0:23}.fc-b126.tif
	    ifile_b6=HDF4_EOS:EOS_GRID:'"'$ifile'"':MODIS_Grid_500m_2D:sur_refl_b06_1
#        ofile_b6=../$odir/tmp_/`basename $ifile`-b06.vrt
        ofile_b6=`basename $ifile`-b06.vrt
        echo "--" $ifile $ifile2 $ofile_tif
        gdal_translate -of vrt -outsize 200% 200%  $ifile_b6 $ofile_b6
        ifiles=HDF4_EOS:EOS_GRID:'"'$ifile2'"':MODIS_Grid_2D:sur_refl_b01_1
        ifiles=$ifiles" "HDF4_EOS:EOS_GRID:'"'$ifile2'"':MODIS_Grid_2D:sur_refl_b02_1
        ifiles=$ifiles" "$ofile_b6
        echo $ifiles
        make_jpeg=1
        process_file
        rm $ofile_b6
    fi

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
     process_files $ifile & 

done

wait

cd ..
#rm -rf $odir/tmp_/
