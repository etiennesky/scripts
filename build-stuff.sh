#!/bin/bash

#set -x 


# needs
# libproj-dev flex bison
################### declare
#export src_prefix=/data/src
export src_prefix=/home/src
#declare -a src_all=( '$src_hdf5' $src_hdf4 $src_netcdf $src_cdo $src_gdal)
declare -A src_dirs
declare -A src_conf
declare -A src_clean
declare -A results
#$export src_dirs

src_dirs["szip"]=szip-2.1
src_dirs["hdf5"]=hdf5-1.8.9
src_dirs["hdf4"]=hdf-4.2.8
src_dirs["udunits"]=udunits-2.1.23
src_dirs["netcdf"]=netcdf-4.2.1.1
src_dirs["netcdf-fortran"]=netcdf-fortran-4.2
src_dirs["cdo"]=cdo-1.6.1
src_dirs["nco"]=nco-4.3.1
#src_dirs["gdal"]=gdal-1.8.1
src_dirs["gdal"]=gdal/gdal-svn
src_dirs["qgis"]=qgis-trunk/Quantum-GIS/build


#flavor="softdev"
flavor="soft"

if [[ "$flavor" == "soft" ]]; then

#################### SOFT
export SOFT_PREFIX="/home/soft"
setup_soft
do_it=1
do_clean=0
src_dirs["gdal"]=/data/src/gdal/svn/branches/1.10/gdal
src_dirs["qgis"]=/data/src/qgis/qgis-master/build-release
#qgis_build_type="-DCMAKE_BUILD_TYPE=RelWithDebInfo"
qgis_build_type="-DCMAKE_BUILD_TYPE=Release"
qgis_apidoc=" "
#src_names=(  hdf4 hdf5 netcdf udunits nco cdo )
src_names=( qgis )

elif [[ "$flavor" == "softdev" ]]; then

#################### SOFTDEV
export SOFT_PREFIX="/home/softdev"
setup_softdev
do_it=1
do_clean=0
src_dirs["gdal"]=/home/src/gdal/git/gdal/gdal
src_dirs["qgis"]=qgis-trunk/Quantum-GIS/build-softdev
qgis_build_type="-DCMAKE_BUILD_TYPE=Debug"
qgis_apidoc="-DWITH_APIDOC=yes"
#cmake -D CMAKE_INSTALL_PREFIX=$SOFT_PREFIX  -D PYTHON_LIBRARY=/usr/lib/libpython2.7.so ..
#src_names=(  hdf4 hdf5 netcdf udunits nco cdo )
src_names=( qgis )

fi

#################### conf
#WITH_SZLIB='--with-szlib=$SOFT_PREFIX'
WITH_SZLIB=''

src_conf["szip"]="./configure --prefix=$SOFT_PREFIX"

#src_conf["hdf5"]="./configure --prefix=$SOFT_PREFIX $WITH_SZLIB --disable-fortran --enable-cxx "
src_conf["hdf5"]="./configure --prefix=$SOFT_PREFIX $WITH_SZLIB --enable-fortran --enable-cxx "
#src_clean["hdf5"]="rm -rf $src_prefix/${src_dirs["hdf5"]}/*"
#src_conf["hdf5"]="cmake -DCMAKE_INSTALL_PREFIX=$SOFT_PREFIX -DBUILD_SHARED_LIBS=yes .."


#src_conf["hdf4"]="./configure --prefix=$SOFT_PREFIX $WITH_SZLIB --disable-netcdf --disable-fortran --enable-shared"
src_conf["hdf4"]="./configure --prefix=$SOFT_PREFIX $WITH_SZLIB --enable-netcdf=no --disable-fortran --enable-shared"
#src_clean["hdf4"]="rm -rf $src_prefix/${src_dirs["hdf4"]}/*"
#src_conf["hdf4"]="cmake -DCMAKE_INSTALL_PREFIX=$SOFT_PREFIX -DBUILD_SHARED_LIBS=yes .."

src_conf["udunits"]="./configure --prefix=$SOFT_PREFIX"

src_conf["netcdf"]="./configure --prefix=$SOFT_PREFIX --with-hdf5=$SOFT_PREFIX --enable-netcdf4 --enable-hdf4 --with-hdf4=$SOFT_PREFIX $WITH_SZLIB --with-zlib=/usr --enable-shared "
src_conf["netcdf-fortran"]="./configure --prefix=$SOFT_PREFIX --with-hdf5=$SOFT_PREFIX --enable-netcdf4 --enable-hdf4 --with-hdf4=$SOFT_PREFIX $WITH_SZLIB --with-zlib=/usr --enable-shared "
#w/hdf5: ./configure --prefix=/home/softdev  --with-hdf5=/home/softdev --enable-netcdf4 --enable-hdf4 --with-hdf4=/home/softdev --with-szlib=/home/softdev --with-zlib=/usr --enable-shared
#wo/hdf5: ./configure --prefix=/home/softdev --disable-netcdf-4  --enable-shared
#netcdf-3: ./configure --prefix=$SOFT_PREFIX --enable-shared

src_conf["nco"]="./configure --prefix=$SOFT_PREFIX --enable-netcdf4 --with-hdf5=$SOFT_PREFIX --with-netcdf=$SOFT_PREFIX --with-udunits2=$SOFT_PREFIX"

src_conf["cdo"]="./configure --prefix=$SOFT_PREFIX --with-zlib=/usr $WITH_SZLIB --with-hdf5=$SOFT_PREFIX --with-netcdf=$SOFT_PREFIX --with-udunits2=$SOFT_PREFIX --with-proj" 
#TODO fix proj.4.8
#src_conf["cdo"]="./configure --prefix=$SOFT_PREFIX --with-zlib=/usr $WITH_SZLIB --with-hdf5=$SOFT_PREFIX --with-netcdf=$SOFT_PREFIX --with-proj=$SOFT_PREFIX" 
#src_conf["gdal"]="./configure --prefix=$SOFT_PREFIX --with-python --with-poppler=yes --with-spatialite=yes  --with-geos=$SOFT_PREFIX/bin/geos-config --with-libtiff=internal --with-geotiff=internal --enable-shared"
#src_conf["gdal"]="./configure --prefix=$SOFT_PREFIX --with-python --with-poppler=yes --with-spatialite=yes  --with-geos=$SOFT_PREFIX/bin/geos-config --with-libtiff=internal --with-geotiff=internal --enable-shared --with-hdf5=$SOFT_PREFIX --with-netcdf=$SOFT_PREFIX --with-hdf4=$SOFT_PREFIX"

src_conf["gdal"]="./configure --prefix=$SOFT_PREFIX --with-geos --with-libtiff=internal --with-geotiff=internal --enable-shared --with-hdf5=$SOFT_PREFIX --with-netcdf=$SOFT_PREFIX --with-hdf4=$SOFT_PREFIX --with-spatialite=yes --with-mrsid=$SOFT_PREFIX/MrSID_Raster_DSDK" # --with-openjpeg=$SOFT_PREFIX"
#TODO add python install
#src_conf["gdal"]="./configure --prefix=$SOFT_PREFIX --with-geos=$SOFT_PREFIX/bin/geos-config --with-libtiff=internal --with-geotiff=internal --enable-shared --with-hdf5=$SOFT_PREFIX --with-netcdf=$SOFT_PREFIX --with-hdf4=$SOFT_PREFIX --with-spatialite=yes --with-mrsid=$SOFT_PREFIX/MrSID_Raster_DSDK --with-openjpeg=$SOFT_PREFIX"
#nc3
#src_conf["gdal"]="./configure --prefix=$SOFT_PREFIX --with-geos=$SOFT_PREFIX/bin/geos-config --with-libtiff=internal --with-geotiff=internal --enable-shared --with-hdf5=$SOFT_PREFIX --with-netcdf=$SOFT_PREFIX --with-hdf4=$SOFT_PREFIX"
#softdev ./configure --prefix=$SOFT_PREFIX --with-geos=/usr/bin/geos-config --with-libtiff=internal --with-geotiff=internal --enable-shared --with-hdf5=$SOFT_PREFIX --with-netcdf=$SOFT_PREFIX --with-hdf4=$SOFT_PREFIX

src_clean["qgis"]="rm -rf $src_prefix/${src_dirs["qgis"]}/*"
#src_conf["qgis"]="cmake -D CMAKE_INSTALL_PREFIX=$SOFT_PREFIX -D PYTHON_EXECUTABLE=/home/soft/bin/python -D GRASS_PREFIX=/home/soft/grass-6.4.1/  .."
#src_conf["qgis"]="cmake -D CMAKE_INSTALL_PREFIX=$SOFT_PREFIX -D GRASS_PREFIX=/home/soft/grass-6.4.1/  .."
src_conf["qgis"]="cmake -DCMAKE_INSTALL_PREFIX=$SOFT_PREFIX  -DPYTHON_LIBRARY=/usr/lib/python2.7/config-x86_64-linux-gnu/libpython2.7.so -DWITH_ASTYLE=yes -DQWT_INCLUDE_DIR=/usr/include/qwt-qt4 $qgis_apidoc $qgis_build_type .."

#openjpeg
#cmake -DCMAKE_INSTALL_PREFIX=$SOFT_PREFIX -DBUILD_SHARED_LIBS=YES ..

#grass-6.2.4
#./configure --prefix=$SOFT_PREFIX --with-tcltk-includes=/usr/include/tcl8.5 --with-geos  --with-proj-share=/usr/share/proj --with-python=/usr/bin/python2.7-config --with-wxwidgets=/usr/bin/wx-config --with-readline --enable-64bit
#export LD_LIBRARY_PATH="/home/softdev/lib:/home/softdev/grass-6.4.2/lib/"

#do_setup_soft


cd $src_prefix
echo $SOFT_PREFIX - $src_prefix
echo ${src_names[*]}
echo ${src_dirs[*]}
echo "PATH: $PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"


for src_name in ${src_names[*]}; do
    src_dir=${src_dirs[$src_name]}
    src_conf=${src_conf[$src_name]}
    src_clean=${src_clean[$src_name]}
    echo $src_name $src_dir $src_conf $src_clean
    echo " "
    echo " "
    echo "======================================================"
    echo $src_name / $src_dir
    echo $src_conf
    cd $src_dir
    pwd
    if [[ "$do_it" == 1 ]]; then
	echo "DO IT"
	if [[ "$do_clean" == 1 ]]; then
	    echo "DO CLEAN"
	    if [[ "$src_clean" == "" ]]; then
		make clean
	    else
		echo "SRC CLEAN: $src_clean"
#		ls
#		pwd
		$src_clean
	    fi
	fi
#	pwd
#	ls
#	cd $src_dir
	echo $src_conf
#ls
	$src_conf && notify-send -t 5000 "BUILDING" "${src_dirs[$src_name]}" && sleep 5 && nice make -j8 && echo "++ DONE make -j8" && make && echo "++ DONE make" && make install && echo "++ DONE make install" 
#	echo make -j8 && make install
	results[$src_name]=$?
	tmp_result="${src_dirs[$src_name]}"
	echo "result: ${results[$src_name]}"
	if [[ "${results[$src_name]}" != 0 ]]; then
	    tmp_result="$tmp_result    FAILED!!!!!"
	else
	    tmp_result="$tmp_result    OK"
	fi
	echo " "
	echo " "
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo $tmp_result
	echo notify-send "BUILD REPORT" "$tmp_result"
	notify-send -t 5000 "BUILD REPORT" "$tmp_result"
	sleep 5
    fi
    cd $src_prefix
done

#cd /home/src
#ls
#cd $src_hdf5
#echo $config_hdf5

echo " "
echo " "
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "BUILD REPORT"
for src_name in ${src_names[*]}; do
#    echo $src_name "-" ${src_dirs[$src_name]} "=>" ${results[$src_name]}
    echo -n ${src_dirs[$src_name]}
    if [[ "${results[$src_name]}" != 0 ]]; then
	echo " FAILED!!!!!"
	echo "configure was: ${src_conf[$src_name]}"
    echo "directory was:"`pwd`
	export
    else
	echo " OK"
    fi
done

#for python-3.2
#cd swig/python
#alias python='/usr/bin/python3.2'
#export PYTHONPATH="/home/softdev/lib/python3.2/site-packages/"
#python2.7 setup.py install --prefix=/home/softdev
#this works:
# python3.2 /home/softdev/bin/virtualenv.py /home/softdev/
# python3.2 setup.py build
# python3.2 setup.py install

#this works for /home/soft
#mkdir -p /home/soft/lib/python2.7/site-packages
#export PYTHONPATH=/home/soft/lib/python2.7/site-packages/
#python setup.py install --prefix=/home/soft



###static
#szip: ./configure --prefix=$SOFT_PREFIX --enable-shared=no
#hdf5: ./configure --prefix=$SOFT_PREFIX --disable-fortran --enable-cxx  --disable-shared
#netcdf: ./configure --prefix=$SOFT_PREFIX --with-hdf5=$SOFT_PREFIX --enable-netcdf4 ---with-zlib=/usr --disable-shared ./configure --prefix=$SOFT_PREFIX --with-geos=$SOFT_PREFIX/bin/geos-configgdal: --with-libtiff=internal --with-geotiff=internal --enable-shared --with-hdf5=$SOFT_PREFIX --with-netcdf=$SOFT_PREFIX --with-hdf4=$SOFT_PREFIX --disable-shared


# prerequisites
# sudo apt-get install build-essential libz-dev bison flex libjpeg6.2-dev libjpeg8-dev gfortran
# all from QGIS install page
