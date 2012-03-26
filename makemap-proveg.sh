#!/bin/bash

source /home/tourigny/bin/makemap-functions

#set -x 

####makemap Mosaico_ProvegBrasil_GRT-ibis.spr ../grid_proveg tmp1.nc
#makemaplevels map2.nc map2-levs.nc
#cdo interpolate,/data/research/data/proveg/grid_proveg_05deg map2-levs.nc map2-levs-05deg.nc
#cdo interpolate,/data/research/data/proveg/grid_proveg_5min map2-levs.nc map2-levs-5min.nc

####gridproveg:
#gridtype = lonlat
#xsize = 5519
#ysize = 4926
#xfirst = -78.166667
#xinc = 0.009000
#yfirst = -36.158333
#yinc = 0.009000


#set -x 

#if [ $# -ne 3 ]
#then
#  echo "Usage: `basename $0` ifile gridfile ofile"
#  exit 1
#fi

####variables
ifile=Mosaico_ProvegBrasil_GRT.spr
#ifile_asc=Mosaico_ProvegBrasil_GRT.asc
#gridfile=/home/tourigny/bin/grid/grid_proveg
gridfile=/data/docs/research/bin/grid/grid_proveg
ofile_ibis=Mosaico_ProvegBrasil_GRT-ibis.nc
ofile_inland=Mosaico_ProvegBrasil_GRT_inland.tif
ofile_proveg=Mosaico_ProvegBrasil_GRT_proveg.nc
ofile_nc=Mosaico_ProvegBrasil_GRT_proveg.nc
ofile_tif=Mosaico_ProvegBrasil_GRT_proveg.tif

#ofilelevs=Mosaico_ProvegBrasil_GRT-ibis-levs.nc

function mymakemap {

#mydatatype="I16"
#mydatatype2="32"
#mylonlatbox="-75.007667,-33.994667,-34.007333,6.006667"
#mylonlatbox="-74.007667,-34.498667,-34.007333,5.006667"
mylonlatbox="-75.007667,-34.498667,-34.007333,5.006667"
#mylonlatbox="-75,-34.5,-34,5"
#mymissval="-1"
#mysetvals="0,-1,1,22,8,23,31,1,42,2,28,11,44,9,34,10,29,8,40,21,41,14,43,20"
mymissval="0"
#mysetvals="1,22,8,23,31,1,42,2,28,11,44,9,34,10,29,8,40,21,41,14,43,20"
myvarname="vegtype"
mytmpzaxisfile="/tmp/cdozaxis"

if [ ! -f $ifile.gz ]
    then
    echo "input file $ifile does not exist!"
    exit 1
fi

#rm -f tmp?.nc
echo -e "zaxistype = height\nsize = 1\nlevels = 1" > $mytmpzaxisfile

gunzip -c $ifile.gz>$ifile
####import data
linenum=`grep -n "INFO_END" $ifile | cut -f1 -d:`
let linenum=$linenum+1
tail -n +$linenum $ifile | cdo -f nc -b I8 -r input,$gridfile tmp1.nc
rm -f $ifile

####manipulate data
#cdo setname,$myvarname -setmissval,$mymissval -setvals,$mysetvals -invertlatdata -sellonlatbox,$mylonlatbox tmp1.nc tmp2.nc
#cdo setname,$myvarname -setmissval,$mymissval -setvals,$mysetvals -invertlatdata tmp1.nc tmp2.nc
#cdo setname,$myvarname -setmissval,$mymissval -invertlatdata tmp1.nc $ofile_proveg
#cdo setzaxis,$mytmpzaxisfile tmp2.nc tmp3.nc
cdo sellonlatbox,$mylonlatbox -invertlatdata tmp1.nc tmp2.nc
#cdo invertlatdata tmp1.nc tmp2.nc
cp -f tmp2.nc $ofile_nc

#perform datum shift SAD69->WGS84
#rm $ofile
gdalwarp -s_srs EPSG:4618 -t_srs EPSG:4326 -co COMPRESS=DEFLATE -dstnodata 0 -overwrite $ofile_nc $ofile_tif
val_repl_csv.py -csv_file /data/docs/research/project/data/proveg-inland.csv -in_id PROVEG_ID -out_id INLAND_ID -co COMPRESS=DEFLATE -a_nodata 100  $ofile_tif $ofile_inland

#mv tmp2.nc  $ofile
####finalize
#mv tmp2.nc $ofile
rm -f tmp?.nc 
rm -f $mytmpzaxisfile
#gzip $ofile
}


function mymakelevels {

mylevels="01 02 08 09 10 11 14 20 21 22 23"
cdo setzaxis,$mytmpzaxisfile ofile tmp1.nc
makemaplevels tmp1.nc $ofilelevs "$mylevels"
makemapregrid $ofilelevs /home/tourigny/bin/grid/grid_proveg_05deg 05deg  "-f nc"
makemapregrid $ofilelevs /home/tourigny/bin/grid/grid_proveg_5min 5min "-f nc4 -z zip"
rm -f $ofilelevs tmp1.nc
}

mymakemap
#mymakelevels
