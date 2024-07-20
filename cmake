#!/bin/bash
out=".out"
warn=".warn"
prev_state=".prev_state"
curr_state=".curr_state"
comp_info=".compile_info"
my_lib="/home/$(whoami)/Documents/cpp/my_lib/" #excluded from the project for now
arg1=$1
arg2=$2

#curr_arr=($(ls --full-time *.cpp *.h *.o 2> /dev/null | awk '{print$7"|"$9}'))
ls --full-time *.cpp *.h *.o 2> /dev/null | awk '{print$7"|"$9}' > $curr_state
curr_arr=$(cat $curr_state)
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
        if [ -z $arg1 ];then
          ./a.out $arg2 > $out 
        else
          ./a.out $arg2  < $arg1 > $out 
        fi
      fi ;;
    * ) echo "CASE: \"$1\" something wrong"
  esac 
  #curr_arr=($(ls --full-time *.cpp *.h *.o 2> /dev/null | awk '{print$7"|"$9}'))
  ls --full-time *.cpp *.h *.o 2> /dev/null | awk '{print$7"|"$9}' > $curr_state
  curr_arr=$(cat $curr_state)

}
diff(){ #$1 extension
  prev_files=($(echo "${prev_arr[@]}" | grep $1$)) # | sed 's/ /\n/g'))
  curr_files=($(echo "${curr_arr[@]}" | grep $1$))
  diff_list=($(echo ${prev_files[@]} ${curr_files[@]} | tr ' ' '\n' | sort | uniq -u | awk -F\| '{print$2}' | uniq ))
  if [ "${#diff_list[@]}" != 0 ];then
    echo "${diff_list[@]}" >> $comp_info
  fi

  #echo $(echo "${prev_files[@]}" "${curr_files[@]}" | tr ' ' '\n'|sort | uniq -u | awk -F\| '{print$2}')
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
#REMOVE curr and prev if empty START
if [ $(echo $(ls -lah "$prev_state" 2> /dev/null | awk '{print$5}')) == 0 ];then
    rm "$prev_state"
fi
rm "$curr_state"
#REMOVE curr and prev if empty END

if [ -f "$out" ];then
    echo "-/^\/^START^\/^\/^\/^\/^\/^\/^\/-"
    cat $out
    echo "-/^\/^END\/^\/^\/^\/^\/^\/^\/^\/-"
fi
if [ -f "$comp_info" ];then
    if [ $(echo $(ls -l "$comp_info" | awk '{print$5}')) != 0 ];then
        echo "^^compile info^^^^^^^^^^^^^^^^^"
        cat $comp_info
        echo "^^compile info end^^^^^^^^^^^^^"
        rm .compile_info
    fi
fi
if [ -f "$warn" ];then
    if [ $(echo $(ls -l "$warn" | awk '{print$5}')) != 0 ];then
        echo -e "\n********************************"
        cat $warn
        echo "-/^\/^\/^\/^\/^\/^\/^\/^\/^\/^\/-"
    fi
fi

