#!/bin/sh

#set -x

#years=`seq 1996 2009`
#months=`seq -w 1 12`

prefix="GFED3.1_"
prefix_len=${#prefix}
suffix="_BA.txt.gz"
ofile_suffix="_BA.nc"
ifiles=`ls -d ${prefix}??????${suffix}`
#ifiles=`ls -d ${prefix}1996??${suffix}`
ofiles=""
grid="../grid_gfedv3"

#process each file
for ifile in $ifiles
do

  year=`expr substr $ifile $((${#prefix}+1)) 4`
  mon=`expr substr $ifile  $((${#prefix}+5)) 2`
  ofile=$prefix$year$mon$ofile_suffix
  ofiles=$ofiles" "$ofile
  echo "ifile: $ifile year: $year mon: $mon ofile:$ofile"
  
  zcat $ifile | cdo -f nc -r setdate,$year"-"$mon"-01" -invertlat -input,$grid $ofile

done

#merge into one file
cdo -r copy $ofiles $prefix"all"$ofile_suffix
rm -f $ofiles
