#!/bin/bash
out=".out"
warn=".warn"
prev_state=".prev_state"

curr_arr=($(ls --full-time *.cpp *.h *.o 2> /dev/null | awk '{print$7"|"$9}'))
if [ "${#curr_arr[@]}" -eq "0" ];then
    echo "Files missing"
    exit
fi
if [ -f $prev_state ];then
    prev_arr=$(cat $prev_state)
fi
rslt=-2
file_work(){ # $1
  case $1 in
    cpp )  
      g++ -fdiagnostics-color -c ${diff_list[@]} &> $warn #$out 
      rslt=$?  ;;
    h ) 
      g++ -fdiagnostics-color -c *.cpp &> $warn #$out 
      rslt=$?;;
    o ) 
      g++ -fdiagnostics-color *.o &> $warn #$out
      rslt=$?
      if [ $rslt -eq 0 ];then
        ./a.out > $out
      fi ;;
    * ) echo "something wrong"
  esac 
  curr_arr=$(ls --full-time *.cpp *.h *.o 2> /dev/null | awk '{print$7"|"$9}')
}
diff(){ #$1 extension
  prev_files=($(echo "${prev_arr[@]}" | grep $1$))
  curr_files=($(echo "${curr_arr[@]}" | grep $1$))
  diff_list=($(echo ${prev_files[@]} ${curr_files[@]} | tr ' ' '\n' | sort | uniq -u | awk -F\| '{print$2}' | uniq ))
  if [ ${#diff_list[@]} -gt 0 ];then
    for i in ${diff_list[@]};do
        if [ ! -f $i ];then
          diff_list=(${diff_list[@]/$i}) 
        fi
    done
    if [ ${#diff_list[@]} -gt 0 ];then
      file_work $1
    fi
  fi
}

if [[ "${prev_arr[@]}" != "${curr_arr[@]}" ]] || [[ ! -f $prev_state ]];then
  prev_files=()
  curr_files=()
  diff h
  if [ $rslt -eq -2 ];then
    diff cpp
    if [ $rslt -eq 0 ];then
       diff o
    fi
  elif [ $rslt -eq 0 ];then
      diff o
  fi
fi

ls --full-time *.cpp *.h *.o 2> /dev/null | awk '{print$7"|"$9}' > $prev_state

if [ -f "$out" ];then
    echo "-/^\/^START^\/^\/^\/^\/^\/^\/^\/-"
    cat $out
    echo "-/^\/^END\/^\/^\/^\/^\/^\/^\/^\/-"
    if [ -f "$warn" ];then
        if [ $(echo $(ls -l "$warn" | awk '{print$5}')) != 0 ];then
            echo -e "\n********************************"
            cat $warn
            echo "-/^\/^\/^\/^\/^\/^\/^\/^\/^\/^\/-"
        fi
    fi
fi

