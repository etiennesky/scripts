#!/bin/sh

set -x

#years=`seq 1996 2009`
#months=`seq -w 1 12`

prefix="GFED3.1_"
prefix_len=${#prefix}
suffix="_BA.hdf"
ofile_suffix="_BA.nc"
ifiles=`ls -d ${prefix}??????${suffix}`
#ifiles=`ls -d ${prefix}1996??${suffix}`
ofiles=""
grid=`dirname $0`"/grid/grid_gfedv3"
scale_factor="0.1"

#process each file
for ifile in $ifiles
do
  year=`expr substr $ifile $((${#prefix}+1)) 4`
  mon=`expr substr $ifile  $((${#prefix}+5)) 2`
  ifile1="HDF4_SDS:UNKNOWN:\""$ifile"\":0"
  ofile=$prefix$year$mon$ofile_suffix
  ofiles=$ofiles" "$ofile
  echo "===="
  echo "ifile: $ifile year: $year mon: $mon ofile:$ofile"
  
  #zcat $ifile | cdo -f nc -r setdate,$year"-"$mon"-01" -invertlat -input,$grid $ofile
  rm -f tmp?.nc $ofile
  gdal_translate -of netcdf $ifile1 tmp1.nc
  cdo -f nc -r setdate,$year"-"$mon"-01" -setgrid,${grid} -invertlat tmp1.nc $ofile

done

rm -f tmp?.nc

#merge into one file
cdo -O -r copy $ofiles tmp1.nc

#fix metadata
ncrename -v Band1,BurnedArea tmp1.nc
ncatted -a long_name,BurnedArea,m,c,"monthly burned area" tmp1.nc
ncatted -a units,BurnedArea,c,c,"km^2"  tmp1.nc 

#fix scale_factor, gdal HDF4 driver bug
#convert to km^2
cdo -r -f nc4c -z zip -b F32 divc,100 -mulc,${scale_factor} tmp1.nc tmp2.nc

ncatted -h -a ,global,d,, tmp2.nc

#rename file 
mv tmp2.nc $prefix"all"$ofile_suffix
rm -f $ofiles tmp?.nc


