#!/bin/bash
for d in ./source/*/;
do 
for file in $d*; 
  do
    echo "$file"
    if [[ -f "$file" ]]; then
      fname=${file##*/}
      dirtmp=${file%/*}
      newdir=${dirtmp##*/}
      if [ ! -d  $newdir ]; then
        mkdir -p  $newdir;
      fi
    python ./minifier.py $file > ${newdir}/${fname}
    fi
  done
done