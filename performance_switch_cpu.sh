#! /bin/bash

# Allows for switching governors in intel_pstate drivers in KDE.
#
# Author: Maulik Mistry
# Date: Aug 04, 2017
# References: https://wiki.archlinux.org/index.php/CPU_frequency_scaling#Scaling_governors
# Requires: KDE, libnotify-bin, cpupower
#
# License: BSD License 2.0
# Copyright (c) 2017, Maulik Mistry
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the <organization> nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

GOVERNOR_LIST=`cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`
CPU=0
DBUSREF=''

function waitToRead() {
  sleep 0.5
}

# Open progress dialog.
function setDialog() {
  DBUSREF="$(kdialog --progressbar "Tuning governor." 4)"
  # Initialize starting value to avoid missing first segment.
  qdbus $DBUSREF Set "" "value" 0;
  waitToRead
  waitToRead
}

function setGovernor() {
  qdbus $DBUSREF setLabelText "CPU $1 on $2."
  PROGRESS=$((`qdbus $DBUSREF Get "" "value"` + 1))
  qdbus $DBUSREF Set "" "value" $PROGRESS;
  sudo cpupower -c $1 frequency-set -g $2
  waitToRead
}

setDialog
for CPUGOV in ${GOVERNOR_LIST}
do
  case ${CPUGOV} in
    performance)
      setGovernor ${CPU} 'powersave'
      ;;
    powersave)
      setGovernor ${CPU} 'performance'
      ;;
  esac
  CPU=$((${CPU} + 1))
done
qdbus $DBUSREF setLabelText "CPU settings finished."
waitToRead
waitToRead
qdbus $DBUSREF close
