#! /bin/bash

#set -x 
source functions

if [[ $# -lt 2 ]]; then exit ; fi

#ifiles=`ls *.shp`
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

    ifile_base=`namename $ifile`
#    sql="SELECT \* FROM \"${ifile_base}\" WHERE GRIDCODE != 0"
    where="GRIDCODE != 0"
    echo $i/$num_ifiles $ifile  $where

    if [ ! -f $ofile ]; then
        ogr2ogr -f "esri shapefile" -where "$where" $ofile $ifile
    else
        ogr2ogr -f "esri shapefile" -update -append  -where "$where" $ofile $ifile -nln $ofile_base
    fi
    let "i += 1"
done