#!/bin/bash

#set -x

###########################
# usage: test-openmp.sh [all | run | compare]
#
# run from a directory which contains the source directories to compare
# there must exist a directory compare/defs which contains grid definition files 
# (inland-grid.infile, inland_compar.h) for each domain, each file prefixed with
# the domain name (e.g. inland-grid.infile.amz, inland_compar.h.amz)

command="all"
if [[ $# -gt 0 ]]; then
    command=$1
fi

echo command: $command

# check if we are running in CRAY environment
if [[ "$CRAY_CPU_TARGET" == "" ]]; then env_cray=0 ; else env_cray=1; fi

if [[ "$env_cray" == "1" ]]; then echo "running in CRAY environment"; fi


#dir vars
datadir=`pwd`/inland-data
basedir_prefix=`pwd`
basedir_ref=inland-ref
basedir_new="inland-ref2 inland"
#FIXME if not absolute path
scriptname=$0
plot2d=`dirname $scriptname`/plot-2D.py
plot1d=`dirname $scriptname`/plot-1D.py

unset INLAND_RANDOMVAL

#openmp
numthreads_new=( "4" "2" "1" "6")


#compilers
if [[ "$env_cray" == "1" ]]; then

source /opt/modules/default/etc/modules.sh 
compile_env=( "PrgEnv-gnu" )
compile_envnum=( "8" )
compile_compilers=( "gfortran" )
compile_numflags=2
compile_flags_names=( "O2" "O0")
compile_flags_gfortran=( "-g -O2" "-g -O0" )
#configure_flags_all="--disable-openmp"
configure_flags_all=""

else

compile_compilers=( "gfortran" "ifort" )
compile_numflags=2
compile_flags_gfortran=( "-g -O2"  "-g -O0")
compile_flags_ifort=( "-g -O2" "-g -O0")
#configure_flags_all="--disable-openmp"
configure_flags_all=""

fi
export OMP_NUM_THREADS=0

#conf
do_compile=1
do_run_ref=1
do_run_new=1
do_run=1
do_plot=1
do_plot2d=1
do_openmp=0
nice_str="nice -n 10 ionice -c 3"
domains=("small" "amz" "tocantins" "global")
nruns=("2" "5")
isimvegs=("0" "1" "2")

#temp vars (for testing script)


function do_run()
{
    basedir=$1
    echo "do_run, basedir = "$basedir
    cd ${basedir_prefix}/$basedir

    #loop domain
    for (( i_domains = 0 ; i_domains < ${#domains[*]} ; i_domains++ )) ; do      
        domain=${domains[$i_domains]}
        echo ++++++++++ domain: $domain

        # copy domain conf files
        make_dir=${basedir_prefix}/$basedir
        cd $make_dir
        ifile=${basedir_prefix}/compare/conf/inland_compar.h.$domain
        ofile=include/inland_compar.h
        if [ ! -f $ifile ] ; then
            echo ERROR conf file $ifile domain $domain is absent!
            exit
        fi
        cp -f $ifile $ofile

        ifile=${basedir_prefix}/compare/conf/inland-grid.infile.${domain}
        ofile=./data/offline/grid/conf/inland-grid.infile
        if [ ! -f $ifile ] ; then  echo "ERROR conf file $ifile domain $domain is absent" ; exit ; fi
        cp -f $ifile $ofile
        echo ""
        echo +++: $ofile:
        echo ""
        cat $ofile
        echo ""

    #loop compilers
    for (( i_compilers = 0 ; i_compilers < ${#compile_compilers[*]} ; i_compilers++ )) ; do      
        compiler=${compile_compilers[$i_compilers]}
        compiler_dir=$compiler

        # prepare cray build env.
        if [[ "$env_cray" == "1" ]]; then
            echo ${compile_envnum[$i_compiler]} | source /usr/bin/development_config > /dev/null 2> /dev/null 
            module load netcdf
            module list
        fi
        
    # loop compiler flags
    for (( i_flags = 0 ; i_flags < $compile_numflags ; i_flags++ )) ; do      
        compile_flag=compile_flags_${compiler}[i_flags]; 
        echo == compiler: $compiler  flags: ${!compile_flag}       
        
        # compile
        if [[ "$do_compile" == "1" ]]; then
            if [[ "$env_cray" == "1" ]]; then compiler="ftn"; fi
            cd $make_dir
            ./configure FC=$compiler FCFLAGS="${!compile_flag}" $configure_flags_all > /dev/null
            if [ "$?" -ne 0 ]; then echo "ERROR during configure"; exit; fi 
            make clean > /dev/null && nice make -j4 > /dev/null
            if [ "$?" -ne 0 ]; then echo "ERROR during make"; exit; fi 
            #make dev-symlinks
            echo "+++done compiling"
        fi

        #loop nrun
        for (( i_nruns = 0 ; i_nruns < ${#nruns[*]} ; i_nruns++ )) ; do      
            nrun=${nruns[$i_nruns]}
            echo ++++++++++ nrun: $nrun

        # loop isimveg flag
        for (( i_isimvegs = 0 ; i_isimvegs < ${#isimvegs[*]} ; i_isimvegs++ )) ; do      
            isimveg=${isimvegs[$i_isimvegs]}
            echo +++: isimveg = $isimveg

        # loop numthreads
        for (( i_numthreads = 0 ; i_numthreads < ${#numthreads[*]} ; i_numthreads++ )) ; do      
            numthread=${numthreads[$i_numthreads]}
            export OMP_NUM_THREADS=$numthread
            echo +++: numthreads = $numthread
            numthread_str=""
            if [ "$numthread" -ne 0 ] ; then numthread_str=_omp_$numthread ; fi

            #work_dir=${basedir_prefix}/compare/$basedir/$compiler/$domain/${nrun}yr/isimveg$isimveg/flags_${compile_flags_names[$i_flags]}
            work_dir=${basedir_prefix}/compare/$basedir/$domain/${nrun}yr/isimveg$isimveg/$compiler/flags_${compile_flags_names[$i_flags]}${numthread_str}

            # make install
            echo "installing files to $work_dir"
            cd $make_dir
            ./configure FC=$compiler FCFLAGS="${!compile_flag}" $configure_flags_all --prefix=${work_dir} > /dev/null
            make install > /dev/null
            if [ "$?" -ne 0 ]; then echo "ERROR during make install"; exit; fi 
            echo "+++done compiling"

            # prepare input files
            cd $work_dir
            rm data
            if [ ! -d share/inland/ ] ; then ln -s share/doc/inland/ data ; else ln -s share/inland/ data ; fi
            ln -s data/offline/grid/conf
            ln -s data/offline/grid/params
            ln -s $datadir/input 
            infile=data/offline/grid/conf/inland-grid.infile
            sed -i -e"s/[0-9]         ! nrun/$nrun         ! nrun/" $infile
            sed -i -e"s/[0-9]         ! isimveg/$isimveg         ! isimveg/" $infile
            grep nrun $infile
            grep isimveg $infile

            if [[ "$do_run" == "1" ]]; then
                # execute
                echo +++ running $nice_str ./inland-grid
                #$nice_str ./bin/inland-grid > log.txt 2>&1
                if [ "$nrun" -gt 5 -a  "$env_cray" -eq 1 ]; then 
                    echo "qsub!!!";
                else                 
                    $nice_str ./bin/inland-grid > log.txt 2>&1
                fi
                if [ "$?" -ne 0 ]; then echo "ERROR during execution"; cat log.txt ; exit; fi 
                echo "+++done executing"
                #cat log.txt

                # move results
                #odir=${basedir_prefix}/compare/$basedir/$domain/${nrun}yr/$isimveg/$compiler/flags_$i_flags
                #echo +++move results to $odir
                #rm -rf $odir 
                #mkdir -p $odir
                #mv  *.nc log.txt $odir
            fi

        done #numthreads
        unset OMP_NUM_THREADS
        done #isimveg
        done #nruns
    done #compiler flags
    done #compilers
    done #domains

}

function do_diff()
{
    filename=$4
    filename_ts=`basename $filename .nc`_ts.nc
    filename_tsnorm=`basename $filename .nc`_tsnorm.nc
    file1=$1/$filename
    file1_ts=$1/$filename_ts
    file2=$2/$filename
    file2_ts=$2/$filename_ts
    ofile=$3/$4
    ofile_ts=$3/$filename_ts
    ofile_tsnorm=$3/$filename_tsnorm
    if [ ! -f $file1 ] ; then echo "file $file1 missing" ; return 1 ; fi
    if [ ! -f $file2 ] ; then echo "file $file2 missing" ; return 1 ; fi

    echo $file1 $file2 $ofile $file1_ts

    # basic output
    tmpoutput=`cdo diffn $file1 $file2 2>/dev/null`  
    echo "$tmpoutput" | grep -v "0.0000" | grep -v "Date  Time    Name"
    echo "$tmpoutput" | grep "records differ"

    # generate diff file
    mkdir -p $3
    cdo -r -O sub $file2 $file1 $ofile

    # generate ts files
    cdo -r -O fldmean $file1 $file1_ts
    cdo -r -O fldmean $file2 $file2_ts
    cdo -r -O fldmean $ofile $ofile_ts
    cdo -r -O mulc,100 -div -sub $file2_ts $file1_ts $file1_ts $ofile_tsnorm
    echo cdo -r -O mulc,100 -div -sub $ofile_ts $file1_ts $file1_ts $ofile_tsnorm

    # plot files
    if [ "$do_plot" = 1 ] ; then
        echo "plotting"
        mkdir -p $1/plot2d $2/plot2d $3/plot2d
        mkdir -p $1/plotts $2/plotts $3/plotts
        mkdir -p $3/plottsnorm
        if [ "$do_plot2d" = 1 ] ; then
            $plot2d $file1 plot2d      
            $plot2d $file2 plot2d
            $plot2d $ofile plot2d
        fi
        $plot1d $file1_ts plotts
        $plot1d $file2_ts plotts
        $plot1d $ofile_ts plotts
        $plot1d $ofile_tsnorm plottsnorm 1
    fi
}

function do_compare()
{
    basedir=$1
    echo "do_compare, basedir = "$basedir
    #cd ${basedir_prefix}/$basedir

    #loop domain
    for (( i_domains = 0 ; i_domains < ${#domains[*]} ; i_domains++ )) ; do      
        domain=${domains[$i_domains]}
        echo ++++++++++ domain: $domain

    #loop compilers
    for (( i_compilers = 0 ; i_compilers < ${#compile_compilers[*]} ; i_compilers++ )) ; do      
        compiler=${compile_compilers[$i_compilers]}
        
    # loop compiler flags
    for (( i_flags = 0 ; i_flags < $compile_numflags ; i_flags++ )) ; do      
        compile_flag=compile_flags_${compiler}[i_flags]; 
        echo == compiler: $compiler  flags: ${!compile_flag}       
        
        #loop nrun
        for (( i_nruns = 0 ; i_nruns < ${#nruns[*]} ; i_nruns++ )) ; do      
            nrun=${nruns[$i_nruns]}
            echo ++++++++++ nrun: $nrun

        # loop isimveg flag
        for (( i_isimvegs = 0 ; i_isimvegs < ${#isimvegs[*]} ; i_isimvegs++ )) ; do      
            isimveg=${isimvegs[$i_isimvegs]}
            echo +++: isimveg = $isimveg

        # loop numthreads
        for (( i_numthreads = 0 ; i_numthreads < ${#numthreads[*]} ; i_numthreads++ )) ; do      
            numthread=${numthreads[$i_numthreads]}
            export OMP_NUM_THREADS=$numthread
            numthread_str=""
            if [ $numthread -ne 0 ] ; then numthread_str=_omp_$numthread ; fi

            #compare netcdf files
            dir_ref=${basedir_prefix}/compare/${basedir_ref}/$domain/${nrun}yr/isimveg$isimveg/$compiler/flags_${compile_flags_names[$i_flags]}
            dir_new=${basedir_prefix}/compare/${basedir}/$domain/${nrun}yr/isimveg$isimveg/$compiler/flags_${compile_flags_names[$i_flags]}${numthread_str}
            dir_diff=${basedir_prefix}/diff/${basedir}_${basedir_ref}/$domain/${nrun}yr/isimveg$isimveg/$compiler/flags_${compile_flags_names[$i_flags]}${numthread_str}
            echo "dir_ref: "$dir_ref
            echo "dir_new: "$dir_new
            echo "dir_diff: "$dir_diff
            tmpfile1=ibis-yearly.nc
            cdo -O -r -f nc mergetime ${dir_ref}/ibis-yearly-????.nc ${dir_ref}/$tmpfile1
            cdo -O -r -f nc mergetime ${dir_new}/ibis-yearly-????.nc ${dir_new}/$tmpfile1
            do_diff $dir_ref $dir_new $dir_diff $tmpfile1

        done #numthreads
        done #isimveg
        done #nruns
    done #compiler flags
    done #compilers
    done #domains

}


###########################
if [ "$command" = "run_ref" -o "$command" = "all" ]; then
if [ "$do_run_ref" = "1" ]; then
# do the reference run
echo "================================================================="
echo "reference run"
echo "================================================================="
numthreads=("0")
do_run $basedir_ref
fi
fi

# do the new run

if [ "$command" = "run_new" -o "$command" = "all" ]; then
if [ "$do_run_new" = "1" ]; then
echo "================================================================="
echo "new runs"
echo "================================================================="


if [ "$do_openmp" = 1 ]; then numthreads=( ${numthreads_new[*]} );
else numthreads=("0"); fi

for basedir_n in $basedir_new; do
    echo "================================================================="
    echo "new run: "$basedir_n
    echo "================================================================="
    do_run $basedir_n
done
fi
fi

if [ "$command" = "diff" -o "$command" = "showdiff" -o "$command" = "all" ]; then
echo "================================================================="
echo "file differences"
echo "================================================================="
#basedir=$basedir_openmp
#do_compile $numthreads_openmp
#do_run $numthreads_openmp

if [ "$command" = "showdiff" ]; then do_plot=0; fi

if [ "$do_openmp" = 1 ]; then numthreads=( ${numthreads_new[*]} );
else numthreads=("0"); fi

for basedir_n in $basedir_new; do
    echo "================================================================="
    echo "new run: "$basedir_n
    echo "================================================================="
    do_compare $basedir_n
done
fi

exit

