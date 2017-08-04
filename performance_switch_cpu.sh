#! /bin/bash


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
