#!/bin/bash
out=".out"
warn=".warn"
runtime_error=".runtime_error"
prev_state=".prev_state"
curr_state=".curr_state"
comp_info=".compile_info"
#gvers="-std=c++20"
my_lib="/home/$(whoami)/Documents/cpp/my_lib/" #excluded from the project for now
arg1=$1
arg2=$2
line="**********"
gs="\e[0;32m"
gb="\e[5;32m"
os="\e[0;31m"
ob="\e[5;31m"
ws="\e[0;35m"
wb="\e[5;35m"
abrt="\e[7;35m"

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
    $(rm $warn)
  case $1 in
    cpp )  
      g++ $gvers -Wall -fdiagnostics-color -c ${diff_list[@]} &> $warn #$out 
      rslt=$?  ;;
    h ) 
      g++ $gvers -Wall -fdiagnostics-color -c *.cpp &>> $warn #$out 
      rslt=$?;;
    o ) 
      g++ $gvers -Wall -fdiagnostics-color *.o &>> $warn #$out
      rslt=$?
      if [ $rslt -eq 0 ];then
        if [ -z $arg1 ];then ./a.out $arg2 > $out 2> $runtime_error
        else ./a.out $arg2  < $arg1 &> $out
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
      if [ -f "$comp_info" ];then rm $comp_info
      fi
    echo "${diff_list[@]}" >> $comp_info
  fi

  #echo $(echo "${prev_files[@]}" "${curr_files[@]}" | tr ' ' '\n'|sort | uniq -u | awk -F\| '{print$2}')
  if [ ${#diff_list[@]} -gt 0 ];then
    for i in ${diff_list[@]};do
        if [ ! -f $i ];then diff_list=(${diff_list[@]/$i}) 
        fi
    done
    if [ ${#diff_list[@]} -gt 0 ];then file_work $1
    fi
  fi
}

if [[ "${prev_arr[@]}" != "${curr_arr[@]}" ]] || [[ ! -f $prev_state ]];then
  prev_files=()
  curr_files=()
  diff h
  if [ $rslt -eq -2 ];then diff cpp
    if [ $rslt -eq 0 ];then diff o
    fi
  elif [ $rslt -eq 0 ];then diff o
  fi
fi

ls --full-time *.cpp *.h *.o 2> /dev/null | awk '{print$7"|"$9}' > $prev_state
#REMOVE curr and prev if empty --------------START
if [ $(echo $(ls -lah "$prev_state" 2> /dev/null | awk '{print$5}')) == 0 ];then
    rm "$prev_state"
fi
rm "$curr_state"
#REMOVE curr and prev if empty --------------END

lu="\U02554"
ru="\U02512"
rb="\U0251b"
lb="\U02517"
if [ -f "$out" ];then
    if [ "$(cat "$warn" | grep error)" ];then 
            prog_msg="******PREVIOUS START PROGRAMM******"
            warn_msg="ERROR"
            rslt=$gb
    else
            prog_msg="$line*START PROGRAMM$line"
            warn_msg="WARNING"
            rslt=$gs 
    fi
    echo -e "$rslt$lu$prog_msg$ru\e[0m"
    cat $out
    if [ "$(cat "$runtime_error")" != "" ];then
        rslt=$abrt
        echo -e "$rslt$lu$line*PROGRAMM ABORT***$line$ru"
        echo $(cat $runtime_error)
        echo -e "$rslt$lb$line$line*****$line***$rb\e[0m"
    else
        echo -e "$rslt$lb$line**END PROGRAMM$line*$rb\e[0m"
    fi
fi
if [ -f "$comp_info" ];then
    if [ $(echo $(ls -l "$comp_info" | awk '{print$5}')) != 0 ];then
        echo -e "\e[0;33m\U02554***COMPILE INFO START**-std=c++17**\U02512"
        cat $comp_info
        echo -e "\U02517******$lineCOMPILE INFO END$line$line\U0251b"
        rm .compile_info
    fi
fi
if [ -f "$warn" ];then
    if [ $(echo $(ls -l "$warn" | awk '{print$5}')) != 0 ];then
        if [ "$(cat "$warn" | grep error)" ];then 
            rslt=$ob
        elif [ "$(cat "$warn" | grep warning)" ];then rslt=$ws 
        else  rslt="\e[0;36m"
        fi
        echo -e "\n$rslt\U02554$line****$warn_msg$line******\U02512\e[0m"
        cat $warn
        echo -e "$rslt\U02517$line$line$line*****\U0251b\e[0m"
    fi
fi

