#!/usr/bin/env bash

function cpudir.initialize {
  local _scr=$(readlink -f "$0" || /bin/readlink -f "$0" || printf '%s\n' "$0") 2>/dev/null
  local _dir=${_scr%/*}
  [[ $_dir == "$_scr" ]] && _dir=.
  if [[ -d ${_dir:=/} ]]; then
    cpudir=$_dir
  elif _dir=${XDG_DATA_HOME:-$HOME/.local/share}/cpulook; [[ -d $_dir ]]; then
    cpudir=$_dir
  elif _dir=${MWGDIR:-$HOME/.mwg}/share/cpulook; [[ -d $_dir ]]; then
    cpudir=$_dir
  fi
}
cpudir.initialize
