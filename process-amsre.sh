#!/bin/bash

#set -x

#ftp://n4ftl01u.ecs.nasa.gov//DP1/AMSA/AE_Land3.002/2002.12.02//AMSR_E_L3_DailyLand_V06_20021202.hdf.gz
#The first factor is aided by using
#nighttime ( 1:30 A.M., descending pass) measurements when
#the temperature and moisture profiles are reasonably uniform.
#Daytime ( 1:30 P.M., ascending pass) soil moisture estimates
#may reflect the effects of diurnal surface layer ( 0–1 cm)
#drying that decorrelate these estimates from the deeper layer
#soil moisture.

#base_dir="../data"
base_dir="/data/research/data/amsre/data/"
ifile_base="AMSR_E_L3_DailyLand_V06_"
ifile_base7="AMSR_E_L3_DailyLand_V07_"
#ofile_base="AMSR_E_L3_DailyLand_"
ofile_base=AMSRE_smoist_night
ofile_base1=AMSRE_smoist_day
ofile_base2=AMSRE_smoist_night
ifile_suffix=Descending_Land_Grid:D_Soil_Moisture
varname="smoist"
grid_file=AMSR_E_L3_Land_Grid.tif
i_i="1 2"
years=`seq 2002 2010`
#years=`seq 2004 2009`
months=`seq -w 1 12`
days=`seq -w 1 31`

#tmp
#base_dir="../data"
#years=2011
#months="01 02 03 04"
#days="29 30"
#days="01 02"
i_i=1


function fix_metadata()
{
#fix metadata
ncrename -v Band1,$varname $1
ncatted -a long_name,$varname,m,c,"Surface Soil Moisture" $1
ncatted -a units,$varname,c,c,"g/cm3" $1
}

#function fix_cs()
#{

#}
function warp_file() #warp_file ifile ofile r_method
{
echo function warp_file $1 $2 $3 $4
rm -f tmpw?.*
#gdalwarp -t_srs EPSG:4326 -tr 0.25 0.25 -tap -r $3 $1 tmpw1.tif
gdalwarp -t_srs EPSG:4326 -tr $4 $4 -tap -r $3 $1 tmpw1.tif
gdalcopymetadata.py $1 tmpw1.tif
gdal_translate -of netCDF tmpw1.tif tmpw1.nc
cdo -s -O setcalendar,standard -settaxis,${year}-${month}-01,${ofile_time} tmpw1.nc tmpw2.nc
#fix_metadata tmp3.nc
mv tmpw2.nc $2
rm -f tmpw?.*
}

function set_i_vars()
{
    #ascending/day or descending/night
    if [ $1 == "1" ]; then
        ifile_suffix="Ascending_Land_Grid:A_Soil_Moisture"
        ofile_base="AMSRE_smoist_day"
        ofile_time="13:30:00"
    elif [ $1 == "2" ]; then
        ifile_suffix="Descending_Land_Grid:D_Soil_Moisture"
        ofile_base="AMSRE_smoist_night"
        ofile_time="01:30:00"
    fi
}

for year in $years ; do
for month in $months ; do
if [[ "$year" -eq "2002" && "$month" < "06" ]]; then continue; fi
if [[ "$year" -eq "2011" && "$month" > "04" ]]; then continue; fi
for day in $days ; do
if [[ "$year" -eq "2002" && "$month" == "06" && "$day" < "19" ]]; then continue; fi
echo "-----"$year"-"$month"-"$day


ifile_ymd=${year}${month}${day}
#ofile=${ofile_base}_${ifile_ymd}.nc

ifile_hdf=${ifile_base}${ifile_ymd}.hdf
ifile_gz=${ifile_hdf}".gz"
if [ ! -f $base_dir/$ifile_gz ]; then
ifile_hdf=${ifile_base7}${ifile_ymd}.hdf
ifile_gz=${ifile_hdf}".gz"
fi


echo $ifile_hdf $ifile_gz

if [ -f $base_dir/$ifile_gz ]; then

rm -f $ifile_hdf tmp?.nc
#rm -f tmp?.nc

gunzip -c $base_dir/$ifile_gz > $ifile_hdf

#for ofile_base in AMSRE_smoist_night
#for i in 1 2; do
for i in $i_i; do
    set_i_vars $i

ofile=${ofile_base}_${ifile_ymd}.nc
echo $i / $ifile_suffix / $ofile_base / $ofile_time / $ofile

#gdal_translate -of netCDF HDF4_EOS:EOS_GRID:"${ifile_hdf}":Ascending_Land_Grid:A_Soil_Moisture tmp1.nc
#gdal_translate -of netCDF HDF4_EOS:EOS_GRID:"${ifile_hdf}":${ifile_suffix} tmp1.nc
gdal_translate -of netCDF -a_srs EPSG:3410 HDF4_EOS:EOS_GRID:"${ifile_hdf}":${ifile_suffix} tmp1.nc

#cdo -s -O setctomiss,-9999 -invertlat -setcalendar,standard -settaxis,${year}-${month}-${day},${ofile_time} tmp1.nc tmp2.nc
#cdo -s -O setcalendar,standard -settaxis,${year}-${month}-${day},${ofile_time} tmp1.nc tmp2.nc
#cdo -s -O setctomiss,-9999 tmp1.nc tmp2.nc
cdo -s -O setctomiss,-9999 -setcalendar,standard -settaxis,${year}-${month}-${day},${ofile_time} tmp1.nc tmp2.nc
#fix_metadata tmp2.nc

mv tmp2.nc $ofile
rm -f tmp?.nc tmp??.nc *.aux.xml

done #i

rm -f $ifile_hdf 

fi

done #days

#for ofile_base in $ofile_base1 $ofile_base2 ; do 
#for i in 1 2; do
for i in $i_i; do
    set_i_vars $i

#cdo -s -O mergetime ${ofile_base}_${year}${month}[0-9][0-9].nc ${ofile_base}_${year}${month}xx.nc
cdo -s -O mergetime ${ofile_base}_${year}${month}[0-9][0-9].nc tmpa.nc
#cdo -s -O invertlat tmpa.nc ${ofile_base}_${year}${month}bb.nc 
cdo -s -O monmean tmpa.nc tmp1.nc
#cdo -s -O invertlat tmp1.nc ${ofile_base}_${year}${month}bb.nc 
cp tmp1.nc ${ofile_base}_${year}${month}xx.nc 
gdal_translate ${ofile_base}_${year}${month}xx.nc ${ofile_base}_${year}${month}xx.tif
gdalcopyproj.py $base_dir/$grid_file ${ofile_base}_${year}${month}xx.tif

#rm -f ${ofile_base}_${year}${month}[0-9][0-9].nc ${ofile_base}_${year}${month}xx.nc
rm -f ${ofile_base}_${year}${month}[0-9][0-9].nc

gdal_translate tmp1.nc tmp1.tif
gdalcopyproj.py $base_dir/$grid_file tmp1.tif

#warp_file  tmp1.tif  ${ofile_base}_${year}${month}nn.nc near 
#warp_file  tmp1.tif  ${ofile_base}_${year}${month}bb.nc bilinear 
warp_file  tmp1.tif  ${ofile_base}_${year}${month}bb.nc bilinear 0.25
#warp_file  tmp1.tif  ${ofile_base}_${year}${month}b5.nc bilinear 0.05
#warp_file  tmp1.tif  ${ofile_base}_${year}${month}cc.nc cubic 

fix_metadata ${ofile_base}_${year}${month}bb.nc
fix_metadata ${ofile_base}_${year}${month}xx.nc
#fix_metadata ${ofile_base}_${year}${month}nn.nc

rm -f tmp?.nc* tmp?.tif*
done

done #months

#for ofile_base in $ofile_base1 $ofile_base2 ; do 
for i in $i_i; do
    set_i_vars $i
##cdo -s -O mergetime ${ofile_base}_${year}[0-9][0-9]xx.nc ${ofile_base}_${year}xxxx.nc
##cdo -s -O monmean ${ofile_base}_${year}xxxx.nc ${ofile_base}_${year}xx.nc
cdo -s -O mergetime ${ofile_base}_${year}[0-9][0-9]bb.nc ${ofile_base}_${year}bb.nc
#cdo -s -O mergetime ${ofile_base}_${year}[0-9][0-9]b5.nc ${ofile_base}_${year}b5.nc
cdo -s -O mergetime ${ofile_base}_${year}[0-9][0-9]xx.nc ${ofile_base}_${year}xx.nc
#cdo -s -O mergetime ${ofile_base}_${year}[0-9][0-9]nn.nc ${ofile_base}_${year}nn.nc
#rm -f ${ofile_base}_${year}[0-9][0-9]bb.nc
#rm -f ${ofile_base}_${year}[0-9][0-9]xx.nc
#fix_metadata ${ofile_base}_${year}bb.nc
#fix_metadata ${ofile_base}_${year}xx.nc
#fix_metadata ${ofile_base}_${year}nn.nc

##gzip -f ${ofile_base}_${year}xxxx.nc &
done

done #years

