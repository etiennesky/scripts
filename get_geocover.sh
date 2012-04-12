#!/bin/bash

base_url="ftp://ftp.glcf.umd.edu/glcf/Mosaic_Landsat"

#zones1="S-24 S-23 S-22 S-21 S-20 S-19"
#zones1="S-19"
#zones2="00 05 10 15 20"
zones1="S-18 S-17"
#zones1="S-19"
zones2="00 05 10 15 20 25 30"
#zones1="S-25"
#zones2="05"
#zones1="N-22 N-21 N-20 N-19 N-18"
#zones2="00 05"
#ignore="-A .sid"
#ignore="-R .sid"
ignore=""

for zone1 in $zones1 ; do

    for zone2 in $zones2 ; do
# ftp://ftp.glcf.umd.edu/glcf/Mosaic_Landsat/S-22/S-22-25.ETM-EarthSat-MrSID/
        rfile=$base_url/${zone1}/${zone1}-${zone2}".ETM-EarthSat-MrSID/"
        wget -nc -c -nd -r -l 0 $ignore $rfile
    done
done

