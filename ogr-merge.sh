#! /bin/bash

#set -x 

if [[ $# -lt 3 ]]; then exit ; fi

source functions

ofile=$1
ofile_base=`namename $ofile`
ifiles=$
echo $#
ifiles=${@:2:$#}
let "num_ifiles=$# - 1"
echo $ofile $ofile_base $num_ifiles
echo $ifiles

rm -f $ofile_base.*

i=1
#mkdir merged
for ifile in $ifiles ; do
echo $i/$num_ifiles $ifile 
if [ ! -f $ofile ]; then
ogr2ogr -f "esri shapefile" $ofile $ifile
else
ogr2ogr -f "esri shapefile" -update -append $ofile $ifile -nln $ofile_base
fi
let "i += 1"
done