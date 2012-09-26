#!/bin/bash

base_url="ftp://ftp.glcf.umd.edu/glcf/Mosaic_Landsat"
#N-17 10 15

#zones1="S-20 S-19 S-18"
#zones2="35 40 45 50"
zones1="N-20 N-19 N-18"
zones2="10"
ignore=""
#ignore="-R .sid"

for zone1 in $zones1 ; do

    for zone2 in $zones2 ; do
# ftp://ftp.glcf.umd.edu/glcf/Mosaic_Landsat/S-22/S-22-25.ETM-EarthSat-MrSID/
        rfile=$base_url/${zone1}/${zone1}-${zone2}".ETM-EarthSat-MrSID/"
        wget -nc -c -nd -r -l 0 $ignore $rfile
    done
done

