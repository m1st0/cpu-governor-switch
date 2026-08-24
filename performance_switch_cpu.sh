#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2017-2026 Maulik Mistry
#
# Allows for switching governors in intel_pstate drivers in KDE.
#
# References: https://wiki.archlinux.org/index.php/CPU_frequency_scaling#Scaling_governors
# Requires: KDE, libnotify-bin, cpupower
#
# Please share support: https://www.paypal.com/paypalme/m1st0
#                       https://venmo.com/code?user_id=3319592654995456106&created=1753283702


# Using BASH_SOURCE for better path reliability in Bash
SCRIPT_PATH="$(readlink -f -- "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname -- "$SCRIPT_PATH")"
source "${SCRIPT_DIR}/vendor/tput_shell_colorize/tput_shell_colorize.sh"

GOVERNOR_LIST=`cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`
CPU=0
DBUSREF=''
GOVERNOR=''

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
}

function setGovernor() {
  #qdbus ${DBUSREF} setLabelText "CPU $1 on $2."
  #PROGRESS=$((`qdbus ${DBUSREF} Get "" "value"` + 1))
  #qdbus ${DBUSREF} Set "" "value" ${PROGRESS};
  sudo cpupower -c $1 frequency-set -g $2
  messenger_std $2
  linefeed
  #waitToRead
}

#function verifyMinFreq() {
#  sudo sh -c "echo 400000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq"
#  sudo sh -c "echo 400000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq"
#  sudo sh -c "echo 400000 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq"
#  sudo sh -c "echo 400000 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq"
#}

#setDialog
for CPUGOV in ${GOVERNOR_LIST}
do
  case ${CPUGOV} in
    performance)
      #verifyMinFreq # Unnecessary unless you have cpufreq packages.
      GOVERNOR='powersave'
      ;;
    powersave)
      GOVERNOR='performance'
      ;;
  esac
  setGovernor ${CPU} ${GOVERNOR}
  CPU=$((${CPU} + 1))
done
#setDialog "CPU set to ${GOVERNOR}"
#qdbus ${DBUSREF} setLabelText "CPU settings finished."
#waitToRead
#waitToRead
#qdbus ${DBUSREF} close
#logger `cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`
messenger_end Done.
