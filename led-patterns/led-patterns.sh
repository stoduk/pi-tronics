#!/usr/bin/env bash
#
# led-patterns.sh

# standard locals
alias cd='builtin cd'
P="$0"
USAGE="`basename ${P}` [-h(elp)] [-d(ebug)] [-o(ff)]"
DBG=:
OPTIONSTRING=hdo

# specific locals
TURNOFF=0
STOPFILE=${HOME}/.stop-led-patterns
TIMINGFILE=${HOME}/.led-patterns-timings
G_RED=0
G_YELLOW=2
G_GREEN=3
G_SWITCH=6

# write our end time
pdate() { date '+%b %d %Y %T'; }
write-end-time() {
  (echo "ending at   `pdate`"; echo) >>$TIMINGFILE
}
trap write-end-time EXIT

# message & exit if exit num present
usage() { echo -e Usage: $USAGE; [ ! -z "$1" ] && exit $1; }

# process options
while getopts $OPTIONSTRING OPTION
do
  case $OPTION in
    h)	usage 0 ;;
    d)	DBG=echo ;;
    o)  TURNOFF=1 ;;
    *)	usage 1 ;;
  esac
done 
shift `expr $OPTIND - 1`

# stop requested?
[ ${TURNOFF} == 1 ] && { >${STOPFILE}; exit 0; }

# simulate gpio if not available
if [ x`which gpio` == x ]
then
  gpio() { echo $*; }
fi

# initialise gpio pins
init() {
  echo "starting at `pdate`" >>$TIMINGFILE
  echo initialising pins...
  for PIN in $G_RED $G_YELLOW $G_GREEN
  do
    echo -n "setting pin $PIN to output mode; "
    gpio mode $PIN out
  done

  echo -n "setting pin G_SWITCH to input mode"
  gpio mode $G_SWITCH in
  echo
}
init

# get switch status
get-status() {
  echo `gpio read $G_SWITCH`
}

# led switching functions
on-off() {
  if [ x$2 == xoff ]
  then
    gpio write $1 0
  else
    gpio write $1 1
  fi
}
red()     { on-off $G_RED    $1; }
yellow()  { on-off $G_YELLOW $1; }
green()   { on-off $G_GREEN  $1; }
all-on()  { red; yellow; green;  }
all-off() { red off; yellow off; green off;  }

# slow flashing
slow-flash() {
  all-on
  sleep 1
  all-off
  sleep 1
}

# each in sequence
sequence() {
  all-off
  green
  sleep 1

  green off
  yellow
  sleep 1

  yellow off
  red
  sleep 1
}

# main loop
while :
do
  [ -f ${STOPFILE} ] && { all-off; rm ${STOPFILE}; exit 0; }
  if [ "`get-status`" == 1 ]
  then 
    slow-flash
  else
    sequence
  fi
done
