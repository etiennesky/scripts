#!/bin/bash

if [[ $# -lt 1 ]]; then exit ; fi

years_2000=`seq --separator="," 2000 2009`
years_1990=`seq --separator="," 1990 1999`
ifiles=$*

for ifile in $ifiles ; do
#ifile=$1

#cru_ts_3_10.1901.2009.pre.dat.nc.gz
file_base_nc=`echo $ifile |  sed 's/.gz//'`
#ifile_base=`echo $ifile |  sed 's/.nc.gz//'`
file_2000=`echo $file_base_nc |  sed 's/1901\.2009/2000\.2009/'`
file_1990=`echo $file_base_nc |  sed 's/1901\.2009/1990\.1999/'`
file_SA_2000=`echo $file_2000 |  sed 's/cru_ts_3_10/cruts310_SA/'`
file_SA_1990=`echo $file_1990 |  sed 's/cru_ts_3_10/cruts310_SA/'`
file_base_nc_exist=0

echo "================================================"
echo $ifile $file_base_nc $file_2000 $file_SA_2000
#echo $years_2000

if [ -f $file_base_nc ] ; then file_base_nc_exist=1 ; fi

#gunzip if necessary
if [ ! $file_base_nc_exist -eq 1 ]; then gunzip -c $ifile > $file_base_nc ; fi

#process files
cdo selyear,$years_2000 $file_base_nc $file_2000
cdo selyear,$years_1990 $file_base_nc $file_1990
cdo sellonlatbox,-85.25,-29.75,15.25,-60.25 $file_2000 $file_SA_2000
cdo sellonlatbox,-85.25,-29.75,15.25,-60.25 $file_1990 $file_SA_1990

#trmm
#cdo sellonlatbox,-85.25,-29.75,15.25,-50 3B43.000101.6.nc tmp1.nc 

#gzip result files
for f in $file_2000 $file_SA_2000 $file_1990 $file_SA_1990 ; do
    gzip -f $f
done

#cleanup
if [ ! $file_base_nc_exist -eq 1 ]; then rm -f $file_base_nc ; fi

done