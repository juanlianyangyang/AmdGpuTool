#!/bin/bash

# VARS
gpu="all"

# OPTION ERROR MSJ
err() {
   echo "error: invalid arguments"
   echo "usage: $0 [-h] for help..."
}

# FAN SPEED FUNCTIONS
set_fans_speeds() {
   if [[ $gpu == "all" ]] ; then
      set_all_fans_speeds $fanspeed
   else
      if [[ ! -z $gpu ]] && [[ ! -z $fanspeed ]] ; then
         set_req_fan_speed $gpu $fanspeed
      fi
   fi
}

set_all_fans_speeds() {
   local GPUcount="0";
   for GPU in  /sys/class/drm/card?/ ; do
      for GPUhwmon in "$GPU"device/hwmon/hwmon?/ ; do
         cd $GPUhwmon
         workdir="`pwd`"
         fanmax=$(head -1 "$workdir"/pwm1_max)
         if [ $fanmax -gt 0 ] ; then
            f_speed=$(( fanmax * $1 ))
            f_speed=$(( f_speed / 100 ))
            sudo chown $USER "$workdir"/pwm1_enable
            sudo chown $USER "$workdir"/pwm1
            sudo echo -n "1" >> "$workdir"/pwm1_enable
            sudo echo -n "$f_speed" >> $workdir/pwm1
            speedresults=$(head -1 "$workdir"/pwm1)
            if [ $(( speedresults - f_speed )) -gt 6 ] ; then
               echo "Error setting speed for GPU[$GPUcount]!"
            else
               echo "GPU[$GPUcount] speed set to $1%"
            fi
         else
            echo "Error: Unable to determine maximum fan speed for GPU[$GPUcount]!"
         fi
      done
      GPUcount="$(($GPUcount + 1))"
   done
}

set_req_fan_speed() {
   local GPUcount=-1;
   for i in  /sys/class/drm/card?/ ; do
      GPUcount=$(($GPUcount + 1))
   done
   if [[ $1 -gt $GPUcount ]] ; then
      echo "error: invalid GPU ID"
      echo "usage: $0 [-i] for list all GPUs..." ; exit 1
   fi
   GPUhwmon="/sys/class/drm/card$1/device/hwmon/hwmon?/" && cd $GPUhwmon
   workdir="`pwd`"
   fanmax=$(head -1 "$workdir"/pwm1_max)
   if [ $fanmax -gt 0 ] ; then
      f_speed=$(( fanmax * $2 ))
      f_speed=$(( f_speed / 100 ))
      sudo chown $USER "$workdir"/pwm1_enable
      sudo chown $USER "$workdir"/pwm1
      sudo echo -n "1" >> "$workdir"/pwm1_enable
      sudo echo -n "$f_speed" >> $workdir/pwm1
      speedresults=$(head -1 "$workdir"/pwm1)
      if [ $(( speedresults - f_speed )) -gt 6 ] ; then
         echo "Error setting speed for GPU[$1]!"
      else
         echo "GPU[$1] speed set to $2%"
      fi
   else
      echo "Error: Unable to determine maximum fan speed for GPU[$1]!"
   fi
}

# GPU'S INFO
amdgpuinfo() {
   tw=0
   for GPU in /sys/kernel/debug/dri/?/; do
      cd $GPU && GPUdir="`pwd`"
      amdgpu_info=$(cat "$GPUdir"/amdgpu_pm_info | grep GFX -A 9)
      mclk=$(echo "$amdgpu_info" | grep MCLK | awk '{print $1}')
      sclk=$(echo "$amdgpu_info" | grep SCLK | awk '{print $1}')
      load=$(echo "$amdgpu_info" | grep Load | awk '{print $3}')
      realwatts=$(cat "$GPUdir"/amdgpu_pm_info | grep average | awk '{print $1}')
      watts=$(echo "$realwatts" | awk -F "." '{print $1}')
      tw=$(echo "$tw + $realwatts" | bc)
      printf "SCLK[%s] MCLK[%s] LOAD[%s] WATTS[%s]\n" "$sclk" "$mclk" "$load" "$watts"
   done
   tw=$(echo "$tw" | awk -F "." '{print $1}')
   printf "$tw"
}

#amdgputw() {
#   tw=0
#   for GPU in /sys/kernel/debug/dri/?/; do
#      cd $GPU && GPUdir="`pwd`"
#      watts=$(cat "$GPUdir"/amdgpu_pm_info | grep average | awk '{print $1}')
#      tw=$(echo "$tw + $watts" | bc)
#   done
#   tw=$(echo "$tw" | cut -c1-3)
#   printf "$tw"
#}

gpuinfo() {
   local GPUcount="0";
   for GPU in  /sys/class/drm/card?/ ; do
      for GPUhwmon in "$GPU"device/hwmon/hwmon?/ ; do
         cd $GPUhwmon
         workdir="`pwd`"
         temp=$(cat $workdir/temp1_input)
         irq=$(cat $workdir/device/irq)
         rpm=$(cat $workdir/fan1_input)
         printf "GPU[%s] IRQ[%s] TEMP[%s°C] RPM[%s]\n" "$GPUcount" "$irq" "${temp:0:2}" "$rpm"
      done
      GPUcount="$(($GPUcount + 1))"
   done
}

gpubus() {
   lspci | grep ' VGA ' | cut -d " " -f 1 | while read glist; do
      printf "BUS[%s]\n" "${glist:0:2}00"
   done
}

gpuvendor() {
   lspci | grep ' VGA ' | cut -d " " -f 1 | while read glist; do
      vendor=$(lspci -v -s "$glist" | grep Subsystem | awk '{print $2 " " $3 " " $4 " " $5}')
      printf "[%s]\n" "$vendor"
   done
}

gpuprint() {
   bus=$(gpubus)
   info=$(gpuinfo)
   vendor=$(gpuvendor)
   amdinfo=$(amdgpuinfo)
#   tw=$(amdgputw)
   str=$(paste <(echo "$info") <(echo "$bus") <(echo "$amdinfo") <(echo "$vendor"))
   tw=$(echo "$str" | grep -v GPU | awk '{print $1}')
   str=$(echo "$str" | grep GPU)
   printf "%0.s-" {1..127}
   printf "\n"
   printf "%-49s %s %48s\n" "|" "AMDGPU-TOOLS V.1.0 - MONITOR" "|"
   printf "%0.s-" {1..127}
   printf "\n"
#   printf "$str" | awk '{print $1 " - " $2 " - " $5 " - " $4 " - " $3 " - " $9 " - " $8 " - " $6 " - " $7 " - " $10 " " $11 " " $12 " " $13}'
   printf "$str" | awk '{print $1 "  " $2 "  " $5 "  " $4 "  " $3 "  " $9 "  " $8 "  " $6 "  " $7 "  " $10 " " $11 " " $12 " " $13}'
   printf "%0.s-" {1..127}
   printf "\n"
   printf "%-50s WATTS[%s] %65s\n" "|" "$tw" "|"
   printf "%0.s-" {1..127}
   printf "\n"
#    printf "Press [Ctrl + C] to exit...\n"
}

# MAIN
usage() {
cat << EOF
-------------------------------------------------------------------------------------------------------
|                                       AMDGPU-TOOLS V.1.0 - HELP                                     |
-------------------------------------------------------------------------------------------------------
usage: $0 [option] args

OPTIONS:
	-g|--gpu	set for select the GPU by specific ID [should be combined with the option "-f"]
	-f|--fan-speed	set to specify the speed of the GPU(s) fan(s)
	-i|--info	set for monitoring the GPU(s)
	-h|--help	set for help

INFO:
      1. if you need to combine options "-g" and "-f" you must do it in this respective order.
      2. any other options combination cannot be made.
-------------------------------------------------------------------------------------------------------
EOF
}

# TEMP=`getopt -o :g:f:ih --long gpu:,fan-speed:,help,info -- "$@"`
TEMP=`getopt :g:f:ih $*` # For make it works in MAC OS X
if [[ $? -ne 0 ]]; then
   err
   exit 2
fi
eval set -- "$TEMP"

gSwitch=0 ; fSwitch=0 ; iSwitch=0
while true; do
    case "$1" in
      -g|--gpu)       gpu=$2      && gSwitch=1 ; shift 2 ;;
      -f|--fan-speed) fanspeed=$2 && fSwitch=1 ; break   ;;
      -i|--info)      iSwitch=1                ; break   ;;
      -h|--help)      usage                    ; exit 0  ;;
       *)             err                      ; exit 1  ;;
    esac
done

num='^[0-9]+$' ; argsCount=$(($# - 1))
if ([[ ! -z ${gpu}  ]] && [[ ${gpu} =~ $num  ]]) && ([[ ! -z ${fanspeed} ]] && [[ ${fanspeed} =~ $num ]]) ; then
   set_fans_speeds # FOR CHANGE SPECIFIC GPU FANSPEED
elif [[ ! -z ${fanspeed} ]] && [[ ${fanspeed} =~ $num ]] && [[ $argsCount -eq 2 ]] ; then
   if [[ $gSwitch -eq 1 ]] ; then
      err ; exit 1
   fi
   set_fans_speeds # FOR CHANGE ALL GPU FANSPEED
elif [[ $iSwitch -eq 1 ]] && [[ $argsCount -eq 1 ]] && [[ $gSwitch -eq 0 ]] && [[ $fSwitch -eq 0 ]] ; then
#    time gpuprint # FOR GET GPUs INFO
   gpuprint # FOR GET GPUs INFO
else
   err
   exit 2
fi

exit 0
