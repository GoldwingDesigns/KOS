#!/bin/bash
excludetext="//#EXTERNAL_IDS lazyGlobal, BOOTVOLUME, DATAVOLUME, BOOTLIBFILES, LIBFILES, LEXFILES, BOOTLEXFILES, MNV, MNV_TMP, VES, VES1, UTL, UI, SYS, man_check_stage, find_burntime, find_eta_to_true_anomaly, plane_change_info, find_landing_tgt_LAN,get_path_to_apprpoint,find_landing_tgt_LAN_lowalt, orbit_circumference, circle_distance, LAZcalc, LAZcalc_init, pitchangle, hillclimb,etatoaltitude2, LOGMSGS, MIS, STARTTIME, orbit_period, cpa"
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
    (echo $excludetext | cat - $file) | python ./minifier.py  > ${newdir}/${fname}
    # (echo $excludetext | cat - $file) | python ./minifier.py -n -s -i -c> ${newdir}/${fname}
    fi
  done
done