#!/bin/bash

#script for retrieval of amsr-e data
#ftp://n4ftl01u.ecs.nasa.gov//DP1/AMSA/AE_Land3.002/2002.12.03/
#ftp://n4ftl01u.ecs.nasa.gov//DP1/AMSA/AE_Land3.002/2002.12.02//AMSR_E_L3_DailyLand_V06_20021202.hdf.gz

years=`seq 2002 2010`
#years=`seq 2002 2003`
months=`seq -w 1 12`
days=`seq -w 1 31`

base_url="ftp://n4ftl01u.ecs.nasa.gov//DP1/AMSA/AE_Land3.002/"


for year in $years ; do
for month in $months ; do
for day in $days ; do
if [[ "$year" -eq "2002" && "$month" < "06" ]]; then continue; fi
if [[ "$year" -eq "2002" && "$month" == "06" && "$day" < "19" ]]; then continue; fi
echo "-----"$year"-"$month"-"$day
rfile=$base_url$year"."$month"."$day"//"AMSR_E_L3_DailyLand_V06_$year$month$day".hdf.gz"
#echo $rfile
wget -c $rfile
done #days
done #months
done #years