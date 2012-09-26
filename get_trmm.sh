#!/bin/bash

#wget --content-disposition -i /data/tmp/eec6fe5476b823a64cb531abdb9c1b4a_all_data.txt
#http://disc2.nascom.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fftp%2Fdata%2Fs4pa%2FTRMM_L3%2FTRMM_3B42_daily%2F2011%2F001%2F3B42_daily.2011.01.02.6.bin&FORMAT=L2d6aXA&LABEL=3B42_daily.2011.01.02.6.nc.gz&SHORTNAME=TRMM_3B42_daily&SERVICE=HDF_TO_NetCDF&VERSION=1.02&DATASET_VERSION=006
#http://disc2.nascom.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fftp%2Fdata%2Fs4pa%2FTRMM_L3%2FTRMM_3B42_daily%2F2011%2F001%2F3B42_daily.2011.01.02.6.bin&FORMAT=L2d6aXA&LABEL=3B42_daily.2011.01.02.6.nc.gz&SHORTNAME=TRMM_3B42_daily&SERVICE=HDF_TO_NetCDF&VERSION=1.02&DATASET_VERSION=006

#years=`seq 2002 2010`
#months=`seq -w 1 12`
#days=`seq -w 1 31`
years="2010"
months="01"
days="01"

base_url="http://disc2.nascom.nasa.gov/daac-bin/OTF/HTTP_services.cgi"

for year in $years ; do
for month in $months ; do
for day in $days ; do
echo "-----"$year"-"$month"-"$day
rfile=$base_url$year"."$month"."$day"//"AMSR_E_L3_DailyLand_V06_$year$month$day".hdf.gz"
rfile=$base_url?FILENAME=%2Fftp%2Fdata%2Fs4pa%2FTRMM_L3%2FTRMM_3B42_daily%2F2011%2F001%2F3B42_daily.2011.01.02.6.bin&FORMAT=L2d6aXA&LABEL=3B42_daily.2011.01.02.6.nc.gz&SHORTNAME=TRMM_3B42_daily&SERVICE=HDF_TO_NetCDF&VERSION=1.02&DATASET_VERSION=006

#echo $rfile
wget -c $rfile

done
done
done