#!/usr/bin/env bash

function cpulook/initialize-cpudir {
  unset -f "$FUNCNAME"

  local script=$0
  if [[ -h $script ]]; then
    local path=$(realpath "$0" || readlink -f "$0" || /bin/readlink -f "$script") 2>/dev/null
    [[ $path ]] && script=$path
  fi

  [[ $script =~ ^(/?)(.*/)[^/]*$ ]]
  local script_dir=${BASH_REMATCH[1]:-$PWD/}${BASH_REMATCH[2]}
  script_dir=${script_dir%/}
  if [[ -d ${script_dir:-/} ]]; then
    cpudir=$script_dir
  elif local dir=${XDG_DATA_HOME:-$HOME/.local/share}/cpulook; [[ -d $dir ]]; then
    cpudir=$dir
  else
    cpudir=$script_dir
  fi

  # Go to the parent directory until we find $cpudir/lib/cpudef.bash
  while
    local common=$cpudir/lib/cpudef.bash
    if [[ -f $common ]]; then
      if [[ ! -r $common ]]; then
        printf '%s\n' "$script: permission denied for the cpulook directory." >&2
        return 1
      fi
      source "$common"
      return "$?"
    fi
    [[ $cpudir == */* ]]
  do
    cpudir=${cpudir%/*}
  done

  cpudir=
  printf '%s\n' "$script: failed to detect the cpulook directory." >&2
  return 1
}
cpulook/initialize-cpudir || exit "$?"
##----CPULOOK_COMMON_HEADER_END----

# tasks[]
takks=()
function tasks_addcmd {
  local cmd="$*"
  tasks[${#tasks[*]}]="$cmd"
}
function tasks_addfile {
  local fcmd=$1
  tasks_addcmd "$(< "$fcmd")"
}
function tasks_adddir {
  local dcmd=$1 fcmd
  for fcmd in "$dcmd"/*.cmd; do
    if [[ -s $fcmd ]]; then
      tasks_addfile "$fcmd"
    fi
  done
}

# argumuments
function readargs {
  unset -f "$FUNCNAME"
  flags= nice= wd= rc= sub= args=()
  while [[ $1 == -* ]]; do
    case $1 in
    (-n)    nice=$2    ; shift 2 ;;
    (-n*)   nice=${1:2}; shift   ;;
    (-C)    wd=$2      ; shift 2 ;;
    (-C*)   wd=${1:2}  ; shift   ;;
    (--rc)  flags=$flags:rc; shift ;;
    (-c)    tasks_addcmd  "$2"    ; shift 2 ;;
    (-c*)   tasks_addcmd  "${1:2}"; shift   ;;
    (-f)    tasks_addfile "$2"    ; shift 2 ;;
    (-f*)   tasks_addfile "${1:2}"; shift   ;;
    (-d)    tasks_adddir  "$2"    ; shift 2 ;;
    (-d*)   tasks_adddir  "${1:2}"; shift   ;;
    (--sub) # for internal use
      sub=1
      flags=$flags:sub
      shift ;;
    (*)
      cpulook/seeklog "ERROR! unknown option '$1', execution is canceled."
      flags=$flags:error ;;
    esac
  done
  (($#)) && tasks_addcmd "$*"
  [[ :$flags: != *:error:* ]]
}
readargs "$@" || return 2

# execution
if ((nice)); then
  renice "$nice" "${BASHPID:-$$}" &>/dev/null
fi

[[ :$flags: == *:rc:* ]] && source "$HOME/.bashrc"
[[ $wd ]] && cd "$wd"

if [[ :$flags: == *:sub:* ]] && ((${#tasks[@]}==1)); then
  cpulook/seeklog "exec host=$HOSTNAME command=(${tasks[*]})'"
  eval "${tasks[0]}"
else
  (
    for ((i=0;i<${#tasks[@]};i++)); do
      "$0" --sub -c "${tasks[i]}" &
    done
    wait
  ) &>/dev/null </dev/null &
fi
