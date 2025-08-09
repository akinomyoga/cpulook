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
