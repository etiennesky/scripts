#!/bin/bash

#set -x 

if [ $# -lt 1 ]
then
  echo "Usage: `basename $0` tiff_files"
  exit 1
fi

tmpfile="_tmp.tif"
					
#note: use "$var" to account for file names with spaces
#http://g-scripts.sourceforge.net/faq.php
#http://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-bash-script

for arg
do
    ifile=$arg
    echo "--- "$ifile
   if [ ! -f "$ifile" ]; then echo "<"$ifile"> does not exist, stopping now"; continue; fi
    itype=`identify -format %m "$ifile"`
    if [[ $itype != "TIFF" && $itype != "PNG" ]]; then echo "<"$ifile"> is not a TIFF or PNG file, stopping now"; continue; fi
    if [ "$itype" == "TIFF" ]; then options="-compress LZW"; elif [ "$itype" == "PNG" ]; then options="-quality 90"; fi
    echo "processing <"$ifile"> "$itype" "$options
    nice convert $options "$ifile" "$tmpfile" 
    if [ ! -f "$tmpfile" ]; then echo "error compressing file <"$ifile">, stopping now"; continue; fi

    if [ `stat  -c %s "$tmpfile"` -lt `stat  -c %s "$ifile"` ]
    then
	echo "compressed file <"$ifile">"
	rm -f "$ifile"
	mv -f "$tmpfile" "$ifile"
    else
	echo "did not compress file <"$ifile"> - does not make it smaller..."
	rm -f "$tmpfile"
    fi
done 