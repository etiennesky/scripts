#!/bin/bash
source /data/docs/research/scripts/functions

#set -x 
#process-trmm-3b42.sh 3B42_daily.2010.nc 3B42_daily.2010.*.gz
#cdo sellonlatbox,-85.25,-29.75,15.25,-50 3B43.1998-2010.nc 3B43.sam.1998-2010.nc

function usage()
{
echo "Usage: `basename $0` idir ifiles"
}

if [ $# -lt 2 ];  then usage ; exit 1 ; fi

ofile=$1
shift
ifiles="$@"

echo ofile: $ofile
echo ifiles: $ifiles

rm -rf tmp_
mkdir -p tmp_

for ifile in $ifiles; do
    echo $ifile
    gunzip -c $ifile > tmp_/`basename $ifile | sed "s/.gz$//"`
done

rm -f $ofile
cdo -f nc4 -z zip mergetime tmp_/*.nc $ofile

rm -rf tmp_

