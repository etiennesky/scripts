#!/bin/bash
#******************************************************************************
#  $Id$
# 
#  Name:     gdalwarp_sds.sh
#  Project:  
#  Purpose:  
#  Author:   Etienne Tourigny, etourigny.dev@gmail.com
# 
#******************************************************************************
#  Copyright (c) 2013 Etienne Tourigny
# 
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
# 
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
# 
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
#  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#  DEALINGS IN THE SOFTWARE.
#******************************************************************************

# =============================================================================

# this script is meant to be run in the same manner as gdalwarp, but acts on 
# all subdatasets and joins the results in a unique file. For all formats 
# except netcdf, files are added to a single .zip file.
# This script requires the following be installed: 
# cat, grep, gawk, tail, gdalinfo, gdal_translate, gdalwarp, ncks and zip
#
# The following environment variables control internal behaviour:
# GDALWARP_SDS_NUM_THREADS={#/procs/halfprocs} 
#     number of threads to use for parallel processing of subdatasets
#     #=fixed number / procs=number of procs in system / halfprocc=half procs in system
# GDALWARP_SDS_CLEAN=1/0     remove temporary files (default 1,yes)
# GDALWARP_SDS_ORDER=1/0     order final files alphabetically (default 1,yes)
# =============================================================================

tmp_prefix="tmp_"
warp_co=""
tr_co=""
warp_args=""
tr_args=""

#warp_format = 'GTiff'
#warp_ext = 'tif'
#warp_co_str = "-co COMPRESS=DEFLATE"
warp_format='vrt'
warp_ext='vrt'

dst_format='gtiff'
dst_ext='tif'


# =============================================================================

# parse arguments

if [[ $# -lt 2 ]]; then echo "usage: gdalwarp_sds.sh <gdalwarp args> infile outfile"; exit ; fi

argc=$#
argv=( $* )
src_file=${argv[argc-2]}
dst_file=${argv[argc-1]}

i=0
while [ $i -lt $(($argc-2)) ]; do
    #echo $i ${argv[i]}
    # remove -of argument so we know which output format to use in gdal_translate
    if [[ ${argv[i]} == "-of" ]] ; then
        let i=i+1 
        dst_format=`echo ${argv[i]} | tr '[A-Z]' '[a-z]'`
        dst_ext=`gdalinfo --format ${dst_format} | grep "Extension:" | gawk '{print $2};'`
        if [[ ${dst_ext} == ${warp_ext} ]]; then warp_ext=${warp_ext}2; fi 
    # remove -co arguments, so we pass them on to gdal_translate
    elif [[ ${argv[i]} == "-co" ]] ; then
        let i=i+1 
        tr_co=${tr_co}" -co "`echo ${argv[i]} | tr '[a-z]' '[A-Z]'`
    else
        warp_args=${warp_args}" "${argv[i]}
    fi
    let i=i+1 
done


# get subdatasets using SUBDATASET_NAME metadata
subdatasets=`gdalinfo $src_file | grep SUBDATASET | grep _NAME | gawk 'BEGIN { FS="=" }{print $2}'`

# get num_threads set by GDALWARP_SDS_NUM_THREADS={#/procs/halfprocs}
num_threads=$GDALWARP_SDS_NUM_THREADS
if [[ ${num_threads} == "" ]] ; then 
    num_threads=1
elif [[ ${num_threads} == "procs" ]] ; then 
    num_threads=`cat /proc/cpuinfo | grep processor | wc -l`
elif [[ ${num_threads} == "halfprocs" ]] ; then 
    let "num_threads=`cat /proc/cpuinfo | grep processor | wc -l` / 2"
fi
if [[ ${num_threads} != *[[:digit:]]* ]]; then num_threads="1" ; fi

# get other options set through GDALWARP_SDS_* env. vars
do_warp=1
do_clean=1
if [[ ${GDALWARP_SDS_CLEAN} != "" ]]; then do_clean=${GDALWARP_SDS_CLEAN}; fi
do_order=1
if [[ ${GDALWARP_SDS_ORDER} != "" ]]; then do_order=${GDALWARP_SDS_ORDER}; fi

# =============================================================================

echo "===================="
echo src: $src_file dst: $dst_file
echo warp_args: $warp_args
echo warp_co: $warp_co
echo tr_args: $tr_args
echo tr_co: $tr_co
echo dst_format: ${dst_format} dst_ext=${dst_ext}
echo warp_format: ${warp_format} warp_ext=${warp_ext}
echo subdatasets: $subdatasets
echo num_threads: $num_threads
echo "===================="
echo ""


# =============================================================================
# process each variable

count=0
for sds in $subdatasets ; do
    OLD_IFS=$IFS
    IFS=":"
    sds2=( $sds )
    varname=${sds2[2]}
    IFS=${OLD_IFS}
    ofile1=`pwd`/${tmp_prefix}${varname}.${warp_ext}
    ofile2=`pwd`/${tmp_prefix}${varname}.${dst_ext}
    echo $sds $ofile1 $ofile2

    tmp_ofiles=${tmp_ofiles}" "$ofile2

    if [[ $do_warp == "0" ]] ; then continue ; fi

    rm -f $ofile1 $ofile2

    # warp to tmp file
    echo "$" gdalwarp -overwrite -of ${warp_format} ${warp_co} ${warp_args} $sds $ofile1
    gdalwarp -overwrite -of ${warp_format} ${warp_co} ${warp_args} $sds $ofile1

    # translate to final file
    echo "$" gdal_translate -of ${dst_format} ${tr_co} ${tr_args} $ofile1 $ofile2
    gdal_translate -of ${dst_format} ${tr_co} ${tr_args} $ofile1 $ofile2 &
    
    # make sure we do not run more than $num_threads
    let count+=1 
    [[ $((count%num_threads)) -eq 0 ]] && echo "waiting..." && wait && echo "done waiting"

done

wait


# =============================================================================
# join result files - if netcdf use ncks, else add all files to a unique .zip file

# re-order them in increasing filesize for optimization (although this seems unnecessary with --create_ram --no_tmp_fl)
if [[ ${do_order} == "1" ]] ; then tmp_ofiles=`ls -rS ${tmp_ofiles}` ; fi

if [[ ${dst_format} == "netcdf" ]] ; then
    
    ncks_version=`ncks --version 2>&1 | tail -1 | gawk '{print $3};'`  
    if [[ "${ncks_version}" > "4.2.0" ]] ; then ncks_args="--create_ram --no_tmp_fl"; else ncks_args="" ; fi
    # with RAM optim: decreasing size = 0m22.048s / increasing size = 0m21.846s
    # without RAM optim: decreasing size = 0m34.101s / increasing size = 0m22.342s
  
    rm -f $dst_file

    # append each var to dst file using ncks -A
    for ofile in ${tmp_ofiles} ; do
        echo "$" ncks ${ncks_args} -A $ofile ${dst_file}
        nice ncks ${ncks_args} -A $ofile ${dst_file}
    done
    
    echo ""
    echo "===================="
    echo result in unique file ${dst_file}
    echo "===================="


else

    #add results to a zip file
    dst_file_zip=${dst_file}".zip"
    rm -f ${dst_file_zip}
    echo "$" zip ${dst_file_zip} ${tmp_ofiles}
    zip ${dst_file_zip} ${tmp_ofiles}
    echo ""
    echo "===================="
    echo output format $dst_format does not support appending subdatasets
    #echo result in seperate files ${tmp_prefix}*.${dst_ext}
    echo result in unique zipfile ${dst_file_zip}
    echo "===================="

fi

#remove tmp files
if [[ $do_clean == "1" ]] ; then rm -f ${tmp_prefix}*.${warp_ext} ${tmp_prefix}*.${dst_ext} ; fi

