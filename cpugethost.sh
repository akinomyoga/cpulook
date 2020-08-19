#!/usr/bin/env bash

function cpudir.initialize {
  local _scr=$(readlink -f "$0" || /bin/readlink -f "$0" || echo "$0")
  local _dir=${_scr%/*}
  [[ $_dir = "$_scr" ]] && _dir=.
  [[ ! $_dir ]] && _dir=/
  cpudir=$_dir
}
cpudir.initialize

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
