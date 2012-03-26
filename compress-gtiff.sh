#! /bin/bash

function usage()
{
echo "Usage: `basename $0` <ifile>"
}

if [ $# -ne 1 ];  then usage ; exit 1 ; fi
if [ ! -e $1 ];  then  echo ifile $1 does not exist! ; exit 1 ; fi

ifile=`basename $1`
ofile=$ifile
idir=`dirname $1`
ifile_ext=${ifile##*.}

echo $idir/$ifile

rm -f $idir/tmp1.tif
if [ "$ifile_ext" = "gz" ] ; then 
    ifile_gtiff=`basename $ifile .gz`
    ifile_ext2=${ifile_gtiff##*.} 
#    echo "GZ $ifile_gtiff $ifile_ext2" 
    if [ "$ifile_ext2" != "tif" ] ; then 
	echo "ifile must be of extension .tif.gz" 
	exit 1
    fi
    rm -f $ifile_gtiff
    gunzip $idir/$ifile
    ifile=$ifile_gtiff
#    echo gunzip -c $idir/$ifile $idir/tmp1.tif
#elif [ "$ifile_ext" = "tif" ] ; then 

#    echo "TIFF"
#    echo mv $idir/$ifile $idir/tmp1.tif
#else
elif [ "$ifile_ext" != "tif" ] ; then 
    echo "ifile must be of extension .tif or .tif.gz" 
    exit 1
fi

mv $idir/$ifile $idir/tmp1.tif
gdal_translate -co COMPRESS=DEFLATE $idir/tmp1.tif $idir/$ifile
rm $idir/tmp1.tif

