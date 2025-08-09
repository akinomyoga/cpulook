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
##----CPULOOK_COMMON_HEADER_END----

CPULST=$cpudir/cpulist.cfg

declare key=$1

declare r=$(awk '$0~/^[[:space:]]*#|^[[:space:]]*$/{next} $1=="'"$key"'"{print $1}' "$CPULST")
declare c=$(echo "$r" | wc -l)
if [[ $r && $c -eq 1 ]]; then
  echo $r
  exit
elif ((c>1)); then
  echo "cpugethost.sh! ambiguous hostname $key" >&2
  exit 1
fi

declare r=$(awk '$0~/^[[:space:]]*#|^[[:space:]]*$/{next} $1~/'"$key"'/{print $1}' "$CPULST")
declare c=$(echo "$r" | wc -l)
if [[ $r && $c -eq 1 ]]; then
  echo cpugethost.sh: host=$r >&2
  echo "$r"
  exit
elif ((c>1)); then
  echo "cpugethost.sh! ambiguous hostname $key" >&2
  exit 1
fi

declare pattern=$(echo "$key" | sed 's/\b\|\B/.*/g')
declare r=$(awk '$0~/^[[:space:]]*#|^[[:space:]]*$/{next} $1~/'"$pattern"'/{print $1}' "$CPULST")
declare c=$(echo "$r" | wc -l)
if [[ $r && $c -eq 1 ]]; then
  echo "cpugethost.sh: host=$r" >&2
  echo "$r"
  exit
fi

echo "cpugethost.sh! unknown hostname $key" >&2
exit 1
