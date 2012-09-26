#temp vars (for testing script)

#do_compile=0
#do_run=0
compile_compilers=( "gfortran" )
#compile_numflags=1
#compile_flags_gfortran=( "-g -O2" )
#compile_compilers=( "ifort" )
#compile_numflags=1
#compile_flags_ifort=("-O2")
compile_numflags=1
#compile_flags_gfortran=( "-g -O2" )
#compile_flags_ifort=("-g -O2")
compile_flags_names=( "O0")
compile_flags_gfortran=( "-g -O0")
compile_flags_ifort=( "-g -O0")

#domains=("small" "amz")
domains=("small")
#domains=( "to")
#domains=("amz" "global")
nruns=("10")
#nruns=("2" "5")
#isimvegs=("0" "1")
isimvegs=("0")

basedir_ref=inland-ref3
basedir_new="inland-ref4"

do_run_ref=1
do_openmp=0
numthreads_new=( "4" "1" )
do_plot2d=0
do_plot=1