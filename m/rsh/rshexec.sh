#!/bin/bash

CPUDIR="${MWGDIR:-$HOME/.mwg}/cpulook"

# log_submit
seeklog="$CPUDIR/cpuseekd.log"
datetime="$(date +'[%x %T]')"
log_submit() {
  echo "$datetime rshexec.sh: $*" >> "$seeklog"
}

# tasks[]
declare -a tasks
tasks_addcmd() {
  local cmd="$*"
  tasks[${#tasks[*]}]="$cmd"
}
tasks_addfile() {
  local fcmd="$1"
  tasks_addcmd "$(cat "$fcmd")"
}
tasks_adddir(){
  local dcmd="$1"
  for fcmd in "$dcmd"/*.cmd; do
    if test -s "$fcmd"; then
      tasks_addfile "$fcmd"
    fi
  done
}

# argumuments
declare nice=
declare wd=
declare rc=
declare sub=
while test "x${1:0:1}" == 'x-'; do
  case "x$1" in
  x-n)    nice="$2"    ; shift 2 ;;
  x-n*)   nice="${1:2}"; shift   ;;
  x-C)    wd="$2"      ; shift 2 ;;
  x-C*)   wd="${1:2}"  ; shift   ;;
  x--rc)  rc=1; shift ;;
  x-c)    tasks_addcmd  "$2"    ; shift 2 ;;
  x-c*)   tasks_addcmd  "${1:2}"; shift   ;;
  x-f)    tasks_addfile "$2"    ; shift 2 ;;
  x-f*)   tasks_addfile "${1:2}"; shift   ;;
  x-d)    tasks_adddir  "$2"    ; shift 2 ;;
  x-d*)   tasks_adddir  "${1:2}"; shift   ;;
  x--sub) # for internal use
    sub=1
    shift ;;
  *)
    log_submit "ERROR! unknown option '$1', execution is canceled."
    exit 1
    ;;
  esac
done

if test $# -gt 0; then
  tasks_addcmd "$*"
fi

# execution
if test -n "$nice" -a $nice -ne 0; then
  renice "$nice" $BASHPID &>/dev/null
fi

test -n "$rc" && source "$HOME/.bashrc"
test -n "$wd" && cd "$wd"

if test -n "$sub" -a "${#tasks[@]}" -eq 1; then
  log_submit "exec host=$HOSTNAME command=(${tasks[$i]})'"
  eval "${tasks[0]}"
else
  (
    for((i=0;i<${#tasks[*]};i++)); do
      "$0" --sub -c "${tasks[$i]}" &
    done
    wait
  ) &>/dev/null </dev/null &
fi
