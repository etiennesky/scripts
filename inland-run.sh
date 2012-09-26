#merge-output:
#	cd output ; pwd ; for type in daily monthly yearly; do echo ${type} ; rm ibis-${type}.nc ; cdo mergetime ibis-${type}-????.nc ibis-${type}.nc; done

#set -x

make -j6 || exit

rm -f output/*.nc
#time ./inland-grid
/usr/bin/time -f "\nuser     %U  \nsystem   %S \nelapsed  %E\nCPU      %P\nmem max  %M\n" ./inland-grid 2>&1
 
cd output

mkdir -p merge
rm -f merge/ibis-*.nc 

for type in daily monthly yearly ; do 
    for nlpt in "" "-t01" "-t02" "-t03" "-t04" ; do 
        #rm -f merge/ibis-${type}*.nc 
#        rm -f merge/ibis-*.nc 
        # should check for file existence
        ifiles=`ls ibis-${type}-????${nlpt}.nc 2>/dev/null`
        if [[ "$ifiles" != "" ]]; then
            cdo  mergetime $ifiles merge/ibis-${type}${nlpt}.nc
        fi
    done 
done
