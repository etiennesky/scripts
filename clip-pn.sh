#! /bin/bash

#set -x 
source functions

#usage: clip-pn <dstype> <pnname> <ifiles> 
#eg: clip-pn L3JRC pnsc L3JRC*burndate*utm23s*
#for region in PNA PNE PNB PNSca PNCG PNCV PNSCi; do echo $region; clip-pn MCD45 $region MCD45.burndate.cerrado.jun2010-dec2010.sin.tif ; done
#for region in PNA PNE PNB PNSca PNCG PNCV PNSCi; do echo $region; clip-pn MCD45 $region MCD45.burndate.cerrado.jun2005-may2006.sin.tif ; done
#for region in PNA PNE PNB PNSca PNCG PNCV PNSCi; do echo $region; clip-pn L3JRC $region L3JRC.burndate.sam.2005-2006.wgs84.tif ; done

function usage()
{
    echo "Usage: `basename $0` <dstype> <pnname> <ifiles>"
}

function do-clip-pn
{

if [ $# -lt 3 ]
then
    usage
    exit 1
fi

dst_name=$1
pn_name=$2
ifiles=${@:3:$#}


#id name lat lon lat1 lon1 lat2 lon2 EPSG utm??s burncode noburncode
declare -a pn_data_pna=("PNA" "Parque Nacional de Araguaia" -10.50 -50.10 -11.2 -50.5 -9.8 -49.9 "EPSG:32722" "utm22s" 1 0)
declare -a pn_data_pne=("PNE" "Parque Nacional das Emas" -18.14 -52.75 -18.4 -53.15 -17.8 -52.7 "EPSG:32722" "utm22s" 3 0)
declare -a pn_data_pnb=("PNB" "Parque Nacional de Brasilia" -15.69 -48.00 -15.8 -48.2 -15.4 -47.8 "EPSG:32723" "utm23s" 1 3)
declare -a pn_data_pnsca=("PNSCa" "Parque Nacional da Serra da Canastra" -20.10 -46.65 -20.35 -47 -20 -46.35 "EPSG:32723" "utm23s" 1 0)
declare -a pn_data_pncg=("PNCG" "Parque Nacional Chapada dos Guimaraes" -15.45 -55.74 -15.5 -56 -15.15 -55.7 "EPSG:32721" "utm21s" 1 3)
declare -a pn_data_pncv=("PNCV" "Parque Nacional Chapada dos Veadeiros" -13.97 -47.69 -14.2 -48 -13.85 -47.4 "EPSG:32723" "utm23s" 2 1)
declare -a pn_data_pnsci=("PNSCi" "Parque Nacional da Serra do Cipo" -19.32 -43.63 -19.55 -43.7 -19.2 -43.4 "EPSG:32723" "utm23s" 1 0)
#Emas: 2010=(3/0) others=(1,3+,2)

pnname_pna=0
pnname_pnb=0
pnname_pne=0
pnname_pncg=0
pnname_pncv=0
pnname_pnsca=0
pnname_pnsci=0

case "$pn_name" in
    PNA)
	pnname_pna=1
	declare -a pn_data=( "${pn_data_pna[@]}" )
	;;
    PNB)
	pnname_pnb=1
	declare -a pn_data=( "${pn_data_pnb[@]}" )
	;;
    PNE)
	pnname_pne=1
	declare -a pn_data=( "${pn_data_pne[@]}" )
	;;
    PNSCa)
	pnname_pnsca=1
	declare -a pn_data=( "${pn_data_pnsca[@]}" )
	;;
    PNCG)
	pnname_pncg=1
	declare -a pn_data=( "${pn_data_pncg[@]}" )
	;;
    PNCV)
	pnname_pncv=1
	declare -a pn_data=( "${pn_data_pncv[@]}" )
	;;
    PNSCi)
	pnname_pnsci=1
	declare -a pn_data=( "${pn_data_pnsci[@]}" )
	;;
    *)
	usage
	echo ERROR: pn_name $pn_name is not valid
	exit 1

esac

echo ${pn_data[@]}

declare -a dst_data_tm=("TM" "EPSG:32722" "-" "-")
declare -a dst_data_l3jrc=("L3JRC" "EPSG:4326" "sam" "wgs84")
#declare -a dst_data_mcd45=("MCD45" "+proj=sinu +R=6371007.181 +nadgrids=@null +wktext")
declare -a dst_data_mcd45=("MCD45" "+proj=sinu +R=6371007.181 +nadgrids=@null +wktext" "cerrado" "sin")
declare -a dst_data_mcd64=("MCD64" "+proj=sinu +R=6371007.181 +nadgrids=@null +wktext" "cerrado" "sin")

dst_mcd45=0
dst_mcd64=0
dst_tm=0
dst_l3jrc=0
dst_proj=""

case "$dst_name" in
    TM)
	dst_tm=1
	declare -a dst_data=( "${dst_data_tm[@]}" )
	;;
    L3JRC)
	dst_l3jrc=1
	declare -a dst_data=( "${dst_data_l3jrc[@]}" )
	;;
    MCD45)
	dst_mcd45=1
	declare -a dst_data=( "${dst_data_mcd45[@]}" )
	;;
    MCD64)
	dst_mcd64=1
	declare -a dst_data=( "${dst_data_mcd64[@]}" )
	;;
    *)
	usage
	echo "ERROR: <dstype> must be one of: MCD45 MCD64 TM l3JRC"
	exit 1

esac

echo ${dst_data[@]}

arg_s_srs=""
if [ "$dstype_proj" != "" ]; then arg_s_srs="-s_srs '"$dstype_proj"'"; fi


options_gtiff="-co COMPRESS=DEFLATE" 
#options_gtiff="-co COMPRESS=LZW" 
##options_gtiff=" " 
option_tr="-tr 30 30"
##option_tr=" "
#file_shp="/data/research/work/pnsc/Limites_pol_srs.shp"
#file_shp_dir="/data/research/work/allpn/tmp"
file_shp_dir="/data/research/work/allpn/Dados_UC/shapes/PN-Etienne"
nodata=0

##file_shp_base=`basename $file_shp .shp`
#from http://linfiniti.com/2009/09/clipping-rasters-with-gdal-using-polygons/
#pad=120
##tmppad=10
##extent=`ogrinfo -so $file_shp $file_shp_base | grep Extent \
##| sed 's/Extent: //g' | sed 's/(//g' | sed 's/)//g' \
##| sed 's/ - /, /g'`
##extent=`echo $extent | awk -F ',' '{print $1-150 " " $2-150 " " $3+150 " " $4+150}'`
##ifile_region="sam"
###ifile_proj="wgs84"
##ifile_proj="utm23s"

for ifile in $ifiles ; do

    echo =====================
#    echo ifile: $ifile
 
    ifile1=`basename $ifile`
    ifile_region=${dst_data[2]}
    ifile_proj=${dst_data[3]}
    ofile_region=${pn_data[0]}
###ifile_proj="wgs84"
##ifile_proj="utm23s"

    if [ $dst_tm -eq 1 ] ; then
	ofile1="bla1.tif"
	ofile2="bla2.tif"
	ofile3="bla3.tif"

	if [ $pnname_pne -eq 1 -o $pnname_pnsca -eq 1 ] ; then
	    echo "EMAS or Canastra!"
	    year1=${ifile1:3:2}
	    year2=${ifile1:9:2}
	    if [[ ${year1:0:1} -eq "9" ]]; then year1="19"$year1 ; else year1="20"$year1; fi
	    if [[ ${year2:0:1} -eq "9" ]]; then year2="19"$year2 ; else year2="20"$year2; fi      
	    year=$year1
#        year=${ifile1: -8:4}
#        year1=$year
#        year2=$(($year1+1))

	else
	    year="2010"
	fi

	ofile1=TM.burnpix.${ofile_region}-area.${year}.tif
	ofile2=TM.burnpix.${ofile_region}.${year}.tif
	ofile3=$ofile2
	
    else

#    ofile1=`echo $ifile |  sed 's/'${ifile_region}'/'${ofile_region}'-area/' |  sed 's/.'${ifile_proj}'././' | sed 's/-[0-9]\{4\}//'`
#    ofile2=`echo $ifile |  sed 's/'${ifile_region}'/'${ofile_region}'/' |  sed 's/.'${ifile_proj}'././' | sed 's/-[0-9]\{4\}//'`
#    ofile3=`echo $ifile |  sed 's/'${ifile_region}'/'${ofile_region}'/' |  sed 's/.'${ifile_proj}'././'  | sed 's/-[0-9]\{4\}//' | sed 's/burndate/burnpix/'
	ofile1=`echo $ifile1 |  sed 's/'${ifile_region}'/'${ofile_region}'-area/' |  sed 's/.'${ifile_proj}'././' | sed 's/-[0-9]\{4\}//' | sed 's/-[a-z]\{3\}[0-9]\{4\}//' | sed 's/.jun/./'`
	ofile2=`echo $ofile1 |  sed 's/-area//'`
	ofile3=`echo $ofile2 |  sed 's/burndate/burnpix/'`
    fi

    echo years: $year1 $year2
    echo ifile: $ifile
    echo ofiles: $ofile1 $ofile2 $ofile3
 

   rm -f tmp?.tif
    rm -f $ofile $ofile2 $ofile3

    #compute coordinates
#    file_shp=$file_shp_dir"/"${pn_data[0]}"_pol-"${pn_data[9]}".shp"
    file_shp=$file_shp_dir"/"${pn_data[0]}"_pol.shp"
    if [ ! -f $file_shp ]; then  echo "ERROR! file $file_shp does not exist!!" ;  exit ; fi
    file_shp_base=`basename $file_shp .shp`
    extent=`ogrinfo -so $file_shp $file_shp_base | grep Extent \
	| sed 's/Extent: //g' | sed 's/(//g' | sed 's/)//g' \
	| sed 's/ - /, /g'`
    extent=`echo $extent | awk -F ',' '{print $1 " " $2 " " $3 " " $4}'`
   
    
    if [ $dst_tm -ne 1 ] ; then

    #transform the files
    echo ${dst_data[1]} "EPSG:4326"
    if [ "${dst_data[1]}" != "EPSG:4326" ] ; then
       	dst_coords1=( `echo ${pn_data[5]} ${pn_data[6]} | gdaltransform -s_srs EPSG:4326 -t_srs "${dst_data[1]}"` )
	dst_coords2=( `echo ${pn_data[7]} ${pn_data[4]} | gdaltransform -s_srs EPSG:4326 -t_srs "${dst_data[1]}"` )
    else
	echo "no coord transformation needed"
	dst_coords1=( ${pn_data[5]} ${pn_data[6]} )
	dst_coords2=( ${pn_data[7]} ${pn_data[4]} )
    fi
#    echo ${pn_data[5]} ${pn_data[6]} ${dst_coords1[0]} ${dst_coords1[1]}
#    echo ${pn_data[7]} ${pn_data[4]} ${dst_coords2[0]} ${dst_coords2[1]}
    echo ${dst_coords1[0]} ${dst_coords1[1]}
    echo ${dst_coords2[0]} ${dst_coords2[1]}
    gdal_translate $options_gtiff -projwin ${dst_coords1[0]} ${dst_coords1[1]} ${dst_coords2[0]} ${dst_coords2[1]} $ifile tmp0.tif
#    gdalwarp $options_gtiff -overwrite -srcnodata $nodata -dstnodata $nodata -s_srs "${dst_data[1]}" -t_srs "${pn_data[8]}" -te $extent -tr 30 30 tmp0.tif tmp1.tif
    gdalwarp $options_gtiff -overwrite -s_srs "${dst_data[1]}" -t_srs "${pn_data[8]}" -te $extent $option_tr tmp0.tif tmp1.tif
    gdalwarp $options_gtiff -overwrite -dstnodata 0 -cutline $file_shp tmp1.tif tmpb.tif
    val_repl.py $options_gtiff -in 0 -in2 367 -out 1 -c lg -ot 'Int16' tmp1.tif tmp2.tif
    gdalwarp $options_gtiff -overwrite -dstnodata -99 -cutline $file_shp -ot 'Int16' tmp2.tif tmp3.tif
#   echo gdalwarp -co $options_gtiff -overwrite -te $extent-cutline $file_shp tmp1.tif tmp2.tif

    else

	#crop to extent
	gdalwarp $options_gtiff -overwrite -t_srs "${pn_data[8]}" -te $extent $ifile tmp1.tif
	#change vals to (0,1)
	if [ $pnname_pne -eq 1 ] ; then
	    if [ "$year" -eq "2010" ] ; then
		val_repl.py $options_gtiff -c eq -in 3 -out 1 -ot 'Int16' tmp1.tif tmp2.tif
	    else
#		val_repl.py $options_gtiff -c ne -in 2 -out 1 -ot 'Int16' tmp1.tif tmp5.tif	
#		val_repl.py $options_gtiff -c eq -in 2 -out 0 -ot 'Int16' tmp5.tif tmp2.tif
		val_repl.py $options_gtiff -c gt -in 2 -out 1 -ot 'Int16' tmp1.tif tmp5.tif	
		val_repl.py $options_gtiff -c eq -in 2 -out 0 -ot 'Int16' tmp5.tif tmp2.tif
		rm -f tmp5.tif
	    fi
	else
	    burnval=${pn_data[10]}
	    noburnval=${pn_data[11]}
	    val_repl.py $options_gtiff -c eq -in $noburnval -out 0 -ot 'Int16' tmp1.tif tmp5.tif	
	    val_repl.py $options_gtiff -c eq -in $burnval -out 1 -ot 'Int16' tmp5.tif tmp2.tif
	    rm -f tmp5.tif
#	val_repl.py $options_gtiff -c gt -in 0 -out 1 -a_nodata -99 -ot 'Int16' tmp2.tif tmp3.tif
	fi

        #cut to shape
	gdalwarp $options_gtiff -overwrite -dstnodata -99 -cutline $file_shp -ot 'Int16' tmp2.tif tmp3.tif

    fi


    #rename the files
    mv tmpb.tif $ofile2
    mv tmp3.tif $ofile3
    rm -f tmp?.tif *.aux.xml


done

} #end function


function do_clip ()
{

    #PNSci optional? dont have tiffs yet
#    for pn in PNCG PNB PNCV PNE PNSCa PNSCi ; do
    for pn in PNE ; do
	echo ++++++++++++++++++++++++++++++ $pn
	echo ++++++++++++++++++++++++++++++ $pn
##	do-clip-pn MCD45 $pn /data/research/work/modis/mcd45/jun-may/MCD45.burndate.cerrado.*.sin.tif
##	do-clip-pn MCD64 $pn /data/research/work/modis/mcd64/jun-may/MCD64.burndate.cerrado.*.sin.tif
##	do-clip-pn L3JRC $pn /data/research/work/l3jrc/L3JRC.burndate.sam.*.wgs84.tif
    done

#    exit

#    do-clip-pn TM PNCG ../../Dados_UC/Tiff/Guimaraes/Queimada2010.tif 
#    do-clip-pn TM PNB ../../Dados_UC/Tiff/Brasilia/Queimada-2010-PNB-ant.tif
#    do-clip-pn TM PNCV ../../Dados_UC/Tiff/Veadeiros/Queimada-2010.tif 
    do-clip-pn TM PNE ../../Dados_UC/Tiff/Emas/Jun*.tif 
    do-clip-pn TM PNSCa ../../Dados_UC/Tiff/Canastra/jun*.tif 
#    do-clip-pn TM PNE Tiff/Emas/Jun10-Mai11.tif 
#    do-clip-pn TM PNSCa Tiff/Canastra/jun10_mai11.tif 

    exit


}

if [ $# -eq 0 ]
then
    do_clip
else 
    do-clip-pn $*
fi
