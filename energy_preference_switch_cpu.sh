#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2017-2026 Maulik Mistry <mistry01@gmail.com>
#
# Allows for switching governors in intel_pstate drivers in KDE.
#
# References: https://wiki.archlinux.org/index.php/CPU_frequency_scaling#Scaling_governors
# Requires: KDE, libnotify-bin, cpupower
#
# Please share support: https://www.paypal.com/paypalme/m1st0
#                       https://venmo.com/code?user_id=3319592654995456106&created=1753283702


PREFERENCE_LIST=`cat /sys/devices/system/cpu/*/cpufreq/energy_performance_available_preferences`
CPU=0
DBUSREF=''
PREFERENCE=''

function waitToRead() {
  sleep 0.5
}

# Open progress dialog.
function setDialog() {
  #{DBUSREF}="$(kdialog --progressbar "Tuning governor." 4)"
  DBUSREF=$(kdialog --title 'CPU Governor Script' --warningcontinuecancel "$1")
  # Initialize starting value to avoid missing first segment.
  #qdbus ${DBUSREF} Set "" "value" 0;
  waitToRead
  waitToRead
}

function ssetCpuEnergyPref() {
  #qdbus ${DBUSREF} setLabelText "CPU $1 on $2."
  #PROGRESS=$((`qdbus ${DBUSREF} Get "" "value"` + 1))
  #qdbus ${DBUSREF} Set "" "value" ${PROGRESS};
  #sudo cpupower -c $1 frequency-set -g $2
  sudo sh -c "echo $1 > /sys/devices/system/cpu/$2/cpufreq/energy_performance_preference"
  waitToRead
}

#setDialog
for CPUENERGY in ${PREFERENCE_LIST}
do
  case ${CPUENERGY} in
    default)
      PREFERENCE='default' 
      ;;
    performance)
      PREFERENCE='performance'
      ;;
    balance_performance)
      PREFERENCE='balance_performance'
      ;;
    balance_power)
      PREFERENCE='balance_power'
      ;;
    power)
      PREFERENCE='power'
      ;;
  esac
  setCpuEnergyPref ${PREFERENCE} ${CPU}
  CPU=$((${CPU} + 1))
done
setDialog "CPU set to ${PREFERENCE}"
#qdbus ${DBUSREF} setLabelText "CPU settings finished."
waitToRead
waitToRead
#qdbus ${DBUSREF} close
logger `cat /sys/devices/system/cpu/*/cpufreq/energy_performance_preference`
