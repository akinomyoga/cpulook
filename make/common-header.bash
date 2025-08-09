#!/usr/bin/env bash

function cpulook/initialize-cpudir {
  unset -f "$FUNCNAME"

  local script=$0
  if [[ -h $script ]]; then
    local path=$(realpath "$0" || readlink -f "$0" || /bin/readlink -f "$script") 2>/dev/null
    [[ $path ]] && script=$path
  fi

  local script_dir=${script%/*}
  [[ $script_dir == "$script" ]] && script_dir=.
  if [[ -d ${script_dir:=/} ]]; then
    cpudir=$script_dir
  elif local dir=${XDG_DATA_HOME:-$HOME/.local/share}/cpulook; [[ -d $dir ]]; then
    cpudir=$dir
  elif local dir=${MWGDIR:-$HOME/.mwg}/share/cpulook; [[ -d $dir ]]; then
    cpudir=$dir
  else
    cpudir=$script_dir
  fi

  if [[ ! -f $cpudir/cpudefs.sh ]]; then
    printf '%s\n' "$0: failed to detect the cpulook directory." >&2
    exit 2
  elif [[ ! -r $cpudir/cpudefs.sh ]]; then
    printf '%s\n' "$0: permission denied for the cpulook directory." >&2
    exit 2
  fi
}
cpulook/initialize-cpudir
