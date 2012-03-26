#!/bin/bash

#script for retrieval of modis data
#ftp://e4ftl01.cr.usgs.gov/MOTA/MCD45A1.005/2002.01.01/MCD45A1.A2002001.h13v11.005.2007133230004.hdf

years=`seq 2002 2010`
#years="2001 2010"
months=`seq -w 1 12`
indexes_hv="h13v09 h13v10 h13v11 h12v10 h12v11"
# *h13v09* *h13v10* *h13v11* *h12v10* *h12v11*

base_url="ftp://e4ftl01.cr.usgs.gov/MOTA/MCD45A1.005/"


for year in $years ; do
mkdir $year
cd $year
for month in $months ; do
echo $year"-"$month
for index_hv in $indexes_hv ; do
echo $index_hv
rfile=$base_url$year"."$month".01/MCD45A1.A"$year"???."$index_hv".005.*.hdf*"
echo $rfile
#	file="srtm_"${index_i}"_"${index_j}".zip"
#	file_mask="srtm_mk_"${index_i}"_"${index_j}".zip"
#	echo $index_i'-'$index_j' '$file_data
#	sleep 3s
#	wget -c ${base_mask}${file_mask}
echo wget -nc -c $rfile
done
done #months
cd ..
done #years